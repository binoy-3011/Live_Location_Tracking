import 'package:flutter/material.dart';
import 'package:live_location_tracking/custom_widgets/constants.dart';
import 'package:live_location_tracking/custom_widgets/Round_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import '../firebase/crud.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late String name, email, password;
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFF6F6F6),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 60, left: 20, right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Hero(
                      tag: "logo",
                      child: Container(
                        child: Image.asset("assets/logo3.png"),
                        height: 200,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                    ),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        name = value;
                      },
                      decoration: kTextFieldDecoration.copyWith(
                          hintText: "Enter your Name..."),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        email = value;
                      },
                      decoration: kTextFieldDecoration.copyWith(
                          hintText: "Enter your Email..."),
                    ),
                    SizedBox(
                      height: 5.0,
                    ),
                    TextField(
                      style: TextStyle(color: Colors.black),
                      obscureText: true,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        password = value;
                      },
                      decoration: kTextFieldDecoration.copyWith(
                          hintText: "Enter your Password..."),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    RoundedButton(
                      title: "Register",
                      color: Colors.redAccent,
                      onPressed: () async {
                        setState(() {
                          showSpinner = true;
                        });
                        try {
                          final newUser =
                              await _auth.createUserWithEmailAndPassword(
                                  email: email, password: password);

                          if (newUser != null) {
                            addUserData(name, email);
                            Navigator.pushNamed(context, "home_screen");
                          }
                          setState(() {
                            showSpinner = false;
                          });
                        } catch (e) {
                          messageAlert("User already exists", context);
                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                      height: 42.0,
                      width: 160.0,
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
