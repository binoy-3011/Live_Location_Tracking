import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;

class MapSample extends StatefulWidget {
  MapSample({required this.gid, required this.helpEmail, required this.name});
  late String gid, helpEmail, name;

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Set<Marker> _marker = {};
  List<LatLng> coordinates = [];
  var mylat, mylong;
  var helplat, helplong;
  Completer<GoogleMapController> _controller = Completer();

  late User? loggedInUser;
  late String email;

  void getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  void initState() {
    super.initState();
    getUserData();
    email = loggedInUser!.email!;
    populateClients();
    print(coordinates);
  }

  populateClients() async {
    await for (var snapshot in _firestore
        .collection("Groups")
        .doc(widget.gid)
        .collection("MembersList")
        .snapshots()) {
      for (var i in snapshot.docs) {
        if (i["Email"] == email) {
          mylat = i["Location"]['geopoint'].latitude ?? 0.0;
          mylong = i["Location"]['geopoint'].longitude ?? 0.0;
        }
        if (i['Email'] == widget.helpEmail) {
          helplat = i["Location"]['geopoint'].latitude ?? 0.0;
          helplong = i["Location"]['geopoint'].longitude ?? 0.0;
        }
        initMarker(i);
      }
    }
  }

  initMarker(doc) {
    LatLng showLocation = LatLng(doc["Location"]['geopoint'].latitude ?? 0.0,
        doc["Location"]['geopoint'].longitude ?? 0.0);
    setState(() {
      coordinates.add(showLocation);
      _marker.add(Marker(
        markerId: MarkerId(doc['Email']),
        position: showLocation,
        infoWindow: InfoWindow(
          title: doc["Name"],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        visible: true,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          title: Text("Map"),
        ),
        body: StreamBuilder(
            stream: _firestore
                .collection("Groups")
                .doc(widget.gid)
                .collection("MembersList")
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Column(children: [
                Stack(children: [
                  Container(
                    height: MediaQuery.of(context).size.height - 90.0,
                    width: double.infinity,
                    child: GoogleMap(
                      zoomGesturesEnabled: true,
                      zoomControlsEnabled: true,
                      mapType: MapType.normal,
                      polygons: {
                        Polygon(
                            polygonId: PolygonId("kPolygon"),
                            points: coordinates,
                            strokeWidth: 5,
                            fillColor: Colors.transparent)
                      },
                      markers: _marker,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(mylat, mylong),
                        zoom: 13,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  ),
                ]),
              ]);
            }),
        floatingActionButton: Align(
          child: FloatingActionButton.extended(
            onPressed: _goToHelpUser,
            backgroundColor: Colors.redAccent,
            label: Text('${widget.name}'),
            icon: Icon(
              Icons.directions,
            ),
          ),
          alignment: Alignment(0.1, 1),
        ));
  }

  Future<void> _goToHelpUser() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(helplat, helplong), zoom: 13)));
  }
}
