import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_firebase/constants/color_constants.dart';
import 'pages.dart';
import 'package:image/image.dart' as img;

class FacePageR extends StatefulWidget {
  @override
  _FacePageRState createState() => _FacePageRState();
}

class _FacePageRState extends State<FacePageR> {
  final picker = ImagePicker();
  final _firebaseStorage = FirebaseStorage.instance;
  final _databaseReference = FirebaseDatabase.instance.ref();

  Future<void> _uploadImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;
      _showLoadingDialog();
      final String timestamp =
      DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final Reference storageReference =
      _firebaseStorage.ref().child('$timestamp');
      final File pickedImageFile = File(pickedFile.path);
      final img.Image image =
      img.decodeImage(pickedImageFile.readAsBytesSync())!;
      final img.Image resizedImage = img.copyResize(image, width: 400);
      final File resizedFile = File(pickedFile.path);
      await resizedFile.writeAsBytes(img.encodeJpg(resizedImage));
      await storageReference.putFile(resizedFile);
      final String downloadURL = await storageReference.getDownloadURL();

      await _updateDatabase(downloadURL);
      Navigator.of(context).pop();
      _showUploadSuccessSnackBar();
      _redirectToHomePage();
    } catch (e) {
      print(e);
      _showErrorSnackBar('Image upload failed');
    }
  }

  Future<void> _updateDatabase(String downloadURL) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    await _databaseReference
        .child('Staffs/$userId/Profile/Remark1')
        .set(downloadURL);
  }

  void _showUploadSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Image uploaded to Firebase Storage and URL inserted into Remark1'),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _redirectToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavBar()),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(color:ColorConstants.orangeColor),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent navigating back when the back button is pressed
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Update Face'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                label: 'Upload from Gallery',
                icon: Icons.photo_library,
                onPressed: () => _uploadImage(ImageSource.gallery),
              ),
              SizedBox(height: 20.0),
              _buildButton(
                label: 'Take a Photo',
                icon: Icons.camera_alt,
                onPressed: () => _uploadImage(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required void Function() onPressed,
  }) {
    return Container(
      width: 200.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(16.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
