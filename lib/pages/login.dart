import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'pages.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  final TextEditingController _userIdController = TextEditingController();
  String _phoneNumber = '';

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  bool _isInvalidInput() {
    return _userIdController.text.isEmpty || _phoneNumber.length < 12;
  }

  Future<void> _verifyPhoneNumber() async {
    try {
      final userId = _userIdController.text;
      final phoneNumber = _phoneNumber;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final snapshot = await _databaseReference
          .child('Staffs/$userId/Profile/ContactNo')
          .get();

      if (snapshot.value != null && snapshot.value.toString() == phoneNumber) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userId', userId);

        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          timeout: const Duration(seconds: 60),
          verificationCompleted: _onVerificationCompleted,
          verificationFailed: _onVerificationFailed,
          codeSent: _onCodeSent,
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ID or Phone Number not found.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {}
  }

  void _onVerificationCompleted(PhoneAuthCredential credential) async {
    await _auth.signInWithCredential(credential);
    Navigator.of(context).pop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavBar()),
    );
  }

  void _onVerificationFailed(FirebaseAuthException e) {
    if (e.code == 'invalid-phone-number') {
      // Handle the verification failure as needed
    } else {
      // Handle other verification failure cases
    }
  }

  void _onCodeSent(String verificationId, int? resendToken) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationPage(verificationId: verificationId),
      ),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Login Page'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Enter Your User ID:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              TextFormField(
                controller: _userIdController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Enter your User ID',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'MY', // Set your initial country code if needed
                onChanged: (phone) {
                  print("the phone ${phone.completeNumber}");
                  _phoneNumber = phone.completeNumber;
                  // Update the button's opacity when phone number changes
                  setState(() {});
                },
              ),
              SizedBox(height: 16.0),
              // Send OTP button with conditionally set onPressed and opacity
              ElevatedButton(
                onPressed: _isInvalidInput() ? null : _verifyPhoneNumber,
                style: ButtonStyle(
                  // Adjust opacity based on conditions
                  overlayColor: MaterialStateProperty.resolveWith(
                        (states) {
                      if (_isInvalidInput()) {
                        return Colors.transparent;
                      } else {
                        return Colors.blue.withOpacity(0.7);
                      }
                    },
                  ),
                ),
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  child: Text(
                    'Send OTP',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
