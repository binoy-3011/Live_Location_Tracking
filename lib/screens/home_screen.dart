// ignore_for_file: non_constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:live_location_tracking/screens/create_group_screen.dart';
import '../custom_widgets/Round_buttons.dart';
import '../firebase/crud.dart';
import 'memberListScreen.dart';

FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseFirestore _firestore = FirebaseFirestore.instance;
Geoflutterfire geo = Geoflutterfire();
late String UID;

class homeScreen extends StatefulWidget {
  @override
  _homeScreenState createState() => _homeScreenState();
}

class _homeScreenState extends State<homeScreen> {
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
      backgroundColor: Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Center(child: Text("Groups")),
        actions: [
          IconButton(
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.logout,
                color: Colors.black,
              ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => createGroupAndMemberAdding()));
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 10),
        child: Column(
          children: [
            groupStream(
              email: email,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            joinRequestStream(
              email: email,
            ),
          ],
        ),
      ),
    );
  }
}

//**************************************************** groupStream********************************************

class groupStream extends StatelessWidget {
  groupStream({required this.email});

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
        List<dynamic> groupList = [];
        List<Widget> Groups = [];
        for (var group in userData) {
          UID = group.get('UID');
          groupList = group.get('GroupList');
          for (var i in groupList) {
            GroupWidget GB = GroupWidget(
              groupName: i['GroupName'],
              admin: i['Admin'],
              GID: i['GID'],
            );
            Groups.add(GB);
          }
        }
        return Expanded(
          child: ListView(
            children: Groups,
          ),
        );
      },
    );
  }
}

//**************************************************groupWidget*****************************************

class GroupWidget extends StatefulWidget {
  GroupWidget(
      {required this.groupName, required this.admin, required this.GID});

  String admin, groupName, GID;

  @override
  _GroupWidgetState createState() => _GroupWidgetState();
}

class _GroupWidgetState extends State<GroupWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 5.0,
        ),
        decoration: BoxDecoration(
          color: Colors.lightBlue[50],
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 1.0,
              offset: Offset(1.0, 1.0), // shadow direction: bottom right
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                widget.groupName,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                width: 210,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => memberList(
                              groupName: widget.groupName, gid: widget.GID)));
                },
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 35,
                ),
              ),
            ]),
            Padding(
              padding: EdgeInsets.only(
                top: 12.0,
              ),
              child: Text(
                "Admin: ${widget.admin}",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    height: 1.5,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 30,
                  ),
                ),
                SizedBox(
                  width: 25,
                ),
                GestureDetector(
                  onTap: () {
                    //deleteGroupByAdmin(widget.groupName,widget.GID);
                  },
                  child: Icon(
                    Icons.restore_from_trash_outlined,
                    size: 30,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

//**********************************************Join Request Stream ***********************************************

class joinRequestStream extends StatelessWidget {
  joinRequestStream({required this.email});
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
          late List<dynamic> requestsList;
          late List<Widget> requestWidgets = [
            Container(
              height: 56.0,
              child: Center(
                child: Text(
                  'Join Requests',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
              ),
              decoration: BoxDecoration(color: Colors.redAccent),
            ),
          ];

          for (var group in userData) {
            UID = group.get('UID');
            requestsList = group.get('Requests');
            for (var i in requestsList) {
              joinRequestsWidget RC = joinRequestsWidget(
                groupName: i['GroupName'],
                admin: i['Admin'],
                GID: i['GID'],
                UID: UID,
                email: email,
                // list: requestWidgets
              );
              requestWidgets.add(RC);
            }
          }
          return Expanded(
            child: ListView(
              children: requestWidgets,
            ),
          );
        });
  }
}

//***************************************************Join Request widget*********************************************

class joinRequestsWidget extends StatefulWidget {
  joinRequestsWidget(
      {required this.admin,
      required this.groupName,
      required this.GID,
      required this.email,
      required this.UID});

  late String admin, groupName, GID, email, UID;

  @override
  _joinRequestsWidgetState createState() => _joinRequestsWidgetState();
}

class _joinRequestsWidgetState extends State<joinRequestsWidget> {
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
                  "Group Name: ${widget.groupName}",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  "Admin : ${widget.admin}",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                Row(
                  children: [
                    RoundedButton(
                      title: "YES",
                      color: Colors.black,
                      onPressed: () {
                        deleteFromRequest(widget.GID, widget.UID, widget.email);
                        addGroupToGroupList(widget.UID, widget.admin,
                            widget.groupName, widget.GID);
                        updateUserInMembersList(widget.GID, widget.UID);
                      },
                      height: 0,
                      width: 70,
                    ),
                    SizedBox(
                      width: 70,
                    ),
                    RoundedButton(
                      title: "NO",
                      color: Colors.black,
                      onPressed: () {
                        deleteFromRequest(widget.GID, widget.UID, widget.email);
                      },
                      height: 0,
                      width: 70,
                    )
                  ],
                )
              ],
            )));
  }
}
