import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

class LoginPage extends StatelessWidget {
  final Function(String) onLoginSuccess;

  LoginPage({required this.onLoginSuccess});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> authenticate(String username, String password) async {
    final url = Uri.parse(Config.loginUrl);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        onLoginSuccess(data['auth_token']); // Passa il token di autenticazione alla schermata principale
      } else {
        print('Errore di autenticazione: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(hintText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(hintText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authenticate(_usernameController.text, _passwordController.text);
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
