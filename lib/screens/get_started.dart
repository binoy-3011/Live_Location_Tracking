import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:live_location_tracking/custom_widgets/Round_buttons.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class getStarted extends StatefulWidget {
  @override
  _getStartedState createState() => _getStartedState();
}

class _getStartedState extends State<getStarted>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: Padding(
        padding: EdgeInsets.only(top: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Hero(
                    tag: "logo",
                    child: Container(
                      child: Image.asset("assets/logo3.png"),
                      height: 50,
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                TypewriterAnimatedTextKit(
                  text: ["Live Location Tracking"],
                  textStyle: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color: Colors.black),
                  speed: Duration(milliseconds: 100),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.only(left: 50),
              child: Text(
                "Navigate To find Your  Friends \n          Faster And Easier",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Image(
              image: AssetImage("assets/getStartedImage.png"),
              height: 280,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                children: [
                  RoundedButton(
                    title: "Log In",
                    color: Colors.redAccent,
                    onPressed: () {
                      Navigator.pushNamed(context, "login_screen");
                    },
                    height: 42.0,
                    width: 160.0,
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  RoundedButton(
                    title: "Register",
                    color: Colors.redAccent,
                    onPressed: () {
                      Navigator.pushNamed(context, "registration_screen");
                    },
                    height: 42.0,
                    width: 160.0,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
