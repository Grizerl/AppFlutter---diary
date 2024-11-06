import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_diary/pages/home.dart';
import 'package:flutter_diary/widgets/sign_in_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyAdQTb1o3iyZ_ZpHvwhrvD2P-97xk-t0tE",
        authDomain: "flutterdiary-b41ad.firebaseapp.com",
        projectId: "flutterdiary-b41ad",
        storageBucket: "flutterdiary-b41ad.firebasestorage.app",
        messagingSenderId: "619956224411",
        appId: "1:619956224411:web:4b53894f47d8b2b571613e"
    ),
  );
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Firebase App',
      home: Home(),
    );
  }
}
