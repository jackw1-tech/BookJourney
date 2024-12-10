import 'package:flutter/material.dart';
import 'package:book_journey/Login/login.dart';
import 'package:book_journey/HomePage/HomePage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';



Future<void> main() async {
  await dotenv.load();

  print("Loaded .env variables: ${dotenv.env}");  // Aggiungi questa linea per il debug
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookJourney',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String _authToken = "";

  @override
  Widget build(BuildContext context) {

    if (_authToken.isEmpty) {
      return LoginPage(onLoginSuccess: (String token) {
        setState(() {
          _authToken = token;
        });
      });
    } else {
      return HomePage(authToken: _authToken);
    }
  }
}


