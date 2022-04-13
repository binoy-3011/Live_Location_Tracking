import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:live_location_tracking/custom_widgets/constants.dart';
import 'package:live_location_tracking/screens/polyMapScreen.dart';
import '../custom_widgets/Round_buttons.dart';
import '../firebase/crud.dart';
import 'MapScreen.dart';
import 'package:location/location.dart' as loc;

FirebaseFirestore _firestore = FirebaseFirestore.instance;
FirebaseAuth _auth = FirebaseAuth.instance;
Geoflutterfire _geo = Geoflutterfire();
late String UID;
late String street, locality, district, state, code, country;

class memberList extends StatefulWidget {
  memberList({required this.groupName, required this.gid});
  late String groupName, gid;

  @override
  _memberListState createState() => _memberListState();
}

class _memberListState extends State<memberList> {
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

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

  @override
  void initState() {
    super.initState();
    getUserData();
    email = loggedInUser!.email!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text("List of Members in ${widget.groupName}"),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(
              child: Text(
                "Members",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          memberStream(GID: widget.gid),
          Padding(
            padding: const EdgeInsets.only(left: 50, bottom: 50, right: 50),
            child: Row(children: [
              FloatingActionButton(
                heroTag: "btn1",
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.handshake,
                  size: 35,
                ),
                onPressed: () {
                  _listenLocation();
                  helpAlert("Do You Want Help ?", widget.gid, email, context);
                },
              ),
              SizedBox(
                width: 170,
              ),
              FloatingActionButton(
                heroTag: "btn2",
                backgroundColor: Colors.redAccent,
                child: Icon(
                  Icons.pin_drop,
                  size: 35,
                ),
                onPressed: () {
                  _listenLocation();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Map(
                                gid: widget.gid,
                              )));
                },
              ),
            ]),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            alertMessages(email: email),
          ],
        ),
      ),
    );
  }

  Future<void> _listenLocation() async {
    _locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentLocation) async {
      var user = await _firestore
          .collection("Groups")
          .doc(widget.gid)
          .collection("MembersList")
          .where("Email", isEqualTo: email)
          .get();

      GeoFirePoint point = _geo.point(
          latitude: currentLocation.latitude!,
          longitude: currentLocation.longitude!);

      late String MID = "";
      late String UID = "";
      for (var i in user.docs) {
        MID = i['MID'];
        UID = i['UID'];
      }
      await _firestore
          .collection("Groups")
          .doc(widget.gid)
          .collection("MembersList")
          .doc(MID)
          .set({"Location": point.data}, SetOptions(merge: true));
      await _firestore
          .collection("User")
          .doc(UID)
          .set({"Location": point.data}, SetOptions(merge: true));
    });
  }
}

//***************************************************** Member Stream ******************************************

class memberStream extends StatelessWidget {
  memberStream({required this.GID});
  String GID;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Groups')
          .doc(GID)
          .collection('MembersList')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        final memberList = snapshot.data!.docs;
        List<memberWidget> member_widget = [];
        for (var i in memberList) {
          final userName = i["Name"];

          final list = memberWidget(
            userName: userName,
            GID: GID,
          );
          member_widget.add(list);
        }
        return Expanded(
            child: ListView(
          children: member_widget,
        ));
      },
    );
  }
}

// ************************************************* Member Widget ***************************************************

class memberWidget extends StatefulWidget {
  memberWidget({required this.userName, required this.GID});
  String userName, GID;

  @override
  _memberWidgetState createState() => _memberWidgetState();
}

class _memberWidgetState extends State<memberWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: Padding(
      padding: EdgeInsets.only(top: 15, left: 20, right: 20),
      child: Material(
        elevation: 5.0,
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          height: 45,
          minWidth: 10.0,
          onPressed: () {},
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(
              "${widget.userName}",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            SizedBox(
              width: 230,
            ),
          ]),
        ),
      ),
    ));
  }
}

// *******************************************************Alert Messages***********************************
class alertMessages extends StatelessWidget {
  alertMessages({required this.email});
  late String email;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('User')
            .where('UserEmail', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            );
          }
          final userData = snapshot.data!.docs;
          late List<dynamic> alertList;
          late List<Widget> alertWidgets = [
            Container(
              height: 56.0,
              child: Center(
                child: Text(
                  'Alert Messages',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ),
              decoration: BoxDecoration(color: Colors.redAccent),
            ),
          ];

          for (var it in userData) {
            UID = it.get('UID');
            alertList = it.get('AlertMessages');
            for (var i in alertList) {
              alertMessagesWidget RC = alertMessagesWidget(
                name: i['Name'],
                gid: i["GID"],
                email: i['Email'],
                UID: UID,
                Address: i['Address'],
                // list: requestWidgets
              );
              alertWidgets.add(RC);
            }
          }
          return Expanded(
            child: ListView(
              children: alertWidgets,
            ),
          );
        });
  }
}

//***************************************************Join Request widget*********************************************

class alertMessagesWidget extends StatefulWidget {
  alertMessagesWidget(
      {required this.name,
      required this.gid,
      required this.email,
      required this.UID,
      required this.Address});

  late String name, gid, email, UID, Address;

  @override
  _alertMessagesWidgetState createState() => _alertMessagesWidgetState();
}

class _alertMessagesWidgetState extends State<alertMessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 15.0,
            ),
            decoration: BoxDecoration(
              color: Colors.grey,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.name} wants your help",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Address : ${widget.Address}",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w400),
                ),
                SizedBox(
                  height: 5,
                ),
                RoundedButton(
                  title: "Take Me There",
                  color: Colors.black,
                  onPressed: () {
                    deleteFromAlertMessages(widget.UID, widget.email);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MapSample(
                                gid: widget.gid,
                                helpEmail: widget.email,
                                name: widget.name)));
                  },
                  height: 50,
                  width: 70,
                ),
              ],
            )));
  }
}
