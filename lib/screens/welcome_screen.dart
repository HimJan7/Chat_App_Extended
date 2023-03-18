import 'package:flash_chat/screens/login_screen.dart';
import 'package:flash_chat/screens/registration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/components/rounded_button.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeScreen extends StatefulWidget {
  static const id = 'Welcome_Screen';
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    controller!.forward();

    controller?.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo',
                  child: Container(
                    child: Image.asset('images/logo.png'),
                    height: 60.0,
                  ),
                ),
                Text(
                  'Flash Chat',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 40.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(
                  width: 20.0,
                ),
              ],
            ),
            SizedBox(
              height: 48.0,
            ),
            roundButton(
              name: 'Log In',
              onPress: () {
                Navigator.pushNamed(context, LoginScreen.id);
              },
              buttonColor: Colors.lightBlueAccent,
            ),
            roundButton(
              name: 'Register',
              onPress: () {
                Navigator.pushNamed(context, RegistrationScreen.id);
              },
              buttonColor: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}
