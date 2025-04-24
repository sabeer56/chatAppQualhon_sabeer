import 'package:flutter/material.dart';
import 'package:myflproject/Important/ChatApp.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor:
            Colors.black, // Set background color for scaffold
      ),
      debugShowCheckedModeBanner: false,
      title: 'ChatApp',
      home: ChatApp(),
    );
  }
}
