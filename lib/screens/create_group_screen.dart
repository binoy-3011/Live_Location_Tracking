import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../custom_widgets/constants.dart';
import 'package:live_location_tracking/custom_widgets/Round_buttons.dart';
import '../firebase/crud.dart';

FirebaseAuth _auth = FirebaseAuth.instance;

class createGroupAndMemberAdding extends StatefulWidget {
  @override
  _createGroupAndMemberAddingState createState() =>
      _createGroupAndMemberAddingState();
}

class _createGroupAndMemberAddingState
    extends State<createGroupAndMemberAdding> {
  late String groupName;
  late String email;
  late User loggedInUser;
  late String x;

  TextEditingController controller1 = TextEditingController();

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

  late List<Map<String, String>> memberList = [];
  bool isError = false;

  void addMember() {
    controller1.clear();
    for (var i in memberList) {
      if (i['Email'] == email) {
        isError = true;
        break;
      }
    }
    if (!isError) {
      memberList.add({
        'Email': email,
      });
    }
    print(memberList);
  }

  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Center(
          child: Text("Create A Group"),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 100, horizontal: 20),
          child: Column(
            children: [
              TextField(
                textAlign: TextAlign.center,
                onChanged: (value) {
                  groupName = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                    hintText: "Enter Group Name...."),
              ),
              SizedBox(
                height: 15,
              ),
              TextField(
                textAlign: TextAlign.center,
                onChanged: (value) {
                  email = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                    hintText: "Enter Email Id of member...."),
              ),
              SizedBox(
                height: 40,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  RoundedButton(
                    color: Colors.redAccent,
                    title: "Add  Member",
                    onPressed: () {
                      setState(() {
                        addMember();
                        if (isError) {
                          errorAlert('Request Already Sent', context);
                          isError = false;
                        } else
                          messageAlert('Request Sent', context);
                        controller1.clear();
                      });
                    },
                    height: 0,
                    width: 0,
                  ),
                  SizedBox(
                    width: 30,
                  ),
                  RoundedButton(
                    color: (Colors.redAccent),
                    title: "Create Group",
                    onPressed: () async {
                      if (loggedInUser.email == null) {
                        getUserData();
                      }
                      x = await createGroup(
                          groupName, loggedInUser.email!, memberList);
                      if (x.isNotEmpty) {
                        messageAlert(x, context);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    height: 0,
                    width: 0,
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
