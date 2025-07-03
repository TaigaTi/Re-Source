import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:re_source/pages/login.dart';
import 'package:re_source/pages/home.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Re-Source',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirebaseAuth.instance.currentUser == null ? const Login() : const Home(),
    );
  }
}
