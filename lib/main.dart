import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_firebase/constants/color_constants.dart';
import 'pages/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase here if needed.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdvanCTi',
      theme: _buildThemeData(),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildThemeData() {
    final customSwatch = MaterialColor(
      ColorConstants.themeColor.value,
      ColorConstants.swatchColor,
    );

    return ThemeData(
      primarySwatch: customSwatch,
    );
  }
}
