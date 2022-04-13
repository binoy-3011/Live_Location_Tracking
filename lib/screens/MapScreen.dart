import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:location/location.dart' as loc;

FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;
Geoflutterfire _geo = Geoflutterfire();

class Map extends StatefulWidget {
  Map({required this.gid});
  late String gid;

  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  late User? loggedInUser;
  late String email;
  StreamSubscription<loc.LocationData>? _locationSubscription;

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

  final loc.Location location = loc.Location();
  bool _added = false;

  late GoogleMapController _controller;
  bool mapToggle = true;
  Set<Marker> _marker = {};
  bool clientsToggle = false;
  bool flag = true;
  var clients = [];

  void initState() {
    super.initState();
    getUserData();
    email = loggedInUser!.email!;
    populateClients();
  }

  populateClients() async {
    await for (var snapshot in _firestore
        .collection("Groups")
        .doc(widget.gid)
        .collection("MembersList")
        .snapshots()) {
      setState(() {
        clientsToggle = true;
      });
      for (var i in snapshot.docs) {
        clients.add(i);
        initMarker(i);
      }
    }
  }

  initMarker(doc) {
    LatLng showLocation = LatLng(doc["Location"]['geopoint'].latitude,
        doc["Location"]['geopoint'].longitude);
    setState(() {
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

  Widget clientCard(client) {
    return Padding(
      padding: EdgeInsets.only(left: 2.0, top: 10.0),
      child: InkWell(
        onTap: () {
          zoomInMarker(client);
        },
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(5.0),
          child: Container(
            height: 100,
            width: 125,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
            child: Center(
              child: Text(client["Name"]),
            ),
          ),
        ),
      ),
    );
  }

  zoomInMarker(client) {
    _controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(client["Location"]["geopoint"].latitude,
          client["Location"]["geopoint"].longitude),
      zoom: 14,
      bearing: 90,
      tilt: 45,
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _locationSubscription?.cancel();
              setState(() {
                _locationSubscription = null;
              });
              Navigator.of(context).pop();
            },
          ),
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
              if (_added) {
                myMap(snapshot);
              }
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height - 80.0,
                        width: double.infinity,
                        child: mapToggle
                            ? GoogleMap(
                                mapType: MapType.normal,
                                onMapCreated:
                                    (GoogleMapController controller) async {
                                  setState(() {
                                    _controller = controller;
                                    _added = true;
                                  });
                                },
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(20.5937, 78.9629),
                                  zoom: 10,
                                ),
                                markers: _marker,
                              )
                            : Center(
                                child: Text(
                                  "Loading....Please Wait",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).size.height - 250,
                        left: 10.0,
                        child: Container(
                          height: 125,
                          width: MediaQuery.of(context).size.width,
                          child: clientsToggle
                              ? ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.all(8.0),
                                  children: clients.map((e) {
                                    return clientCard(e);
                                  }).toList(),
                                )
                              : Container(
                                  height: 1.0,
                                  width: 1.0,
                                ),
                        ),
                      ),
                    ],
                  )
                ],
              );
            }));
  }

  // void onMapCreated(GoogleMapController controller) {
  //   setState(() {
  //     myController = controller;
  //   });
  // }

  Future<void> myMap(AsyncSnapshot<QuerySnapshot> snapshot) async {
    var lat, lng, name;
    var user =
        await snapshot.data!.docs.where((element) => element['Email'] == email);

    for (var i in user) {
      lat = i['Location']['geopoint'].latitude;
      lng = i['Location']['geopoint'].longitude;
      name = i['Name'];
    }

    await _controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 14.47)));

    _marker.removeWhere((element) => element.mapsId == email);
    _marker.add(Marker(
      markerId: MarkerId(email),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: name,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      visible: true,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
