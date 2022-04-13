import 'package:flutter/material.dart';


class RoundedButton extends StatelessWidget {
  RoundedButton({required this.title,required this.color,  required this.onPressed,required this.height,required this.width});

  final  Color color;
  final String title;
  final Function() onPressed;
  final double height;
  final double width;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        elevation: 5.0,
        color: color,
        borderRadius: BorderRadius.circular(30.0),
        child: MaterialButton(
          onPressed: onPressed,
          minWidth: width,
          height: height,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
