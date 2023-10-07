import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_firebase/constants/color_constants.dart';
import 'pages.dart';

class VerificationPage extends StatefulWidget {
  final String verificationId;

  VerificationPage({required this.verificationId});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text('OTP Verification'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: OtpTextField(
                  numberOfFields: 6,
                  fieldWidth: screenWidth / 7,
                  focusedBorderColor: ColorConstants.orangeColor,
                  showFieldAsBox: true,
                  borderWidth: 4.0,
                  onCodeChanged: (String code) {},
                  onSubmit: (pin) {
                    _verifyOtp(pin);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyOtp(String enteredOtp) async {
    try {
      _showLoadingDialog();

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: enteredOtp,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _navigateToHomePage();
      } else {
        Navigator.of(context).pop();
        _showSnackBar('Incorrect OTP. Please try again.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('An error occurred while verifying OTP. Please try again.');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _navigateToHomePage() {
    Navigator.of(context).pop();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => BottomNavBar()),
          (route) => false, // This line removes all previous routes from the stack
    );
  }

  Future<bool> _onBackPressed() async {
    bool confirmExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Exit'),
        content: Text('Are you sure you want to quit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              exit(0);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );

    return confirmExit;
  }
}
