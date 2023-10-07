import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase/constants/color_constants.dart';
import 'pages.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.themeColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildLogoImage(),
            SizedBox(height: 20),
            _buildLoadingIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoImage() {
    return Image.asset(
      "images/led.png", // Replace with your image path
      width: 100,
      height: 100,
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    // Delay the navigation to give the splash screen effect
    Future.delayed(Duration(seconds: 2), () {
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });

    return Container(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        color: ColorConstants.orangeColor,
      ),
    );
  }
}
