import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

class LoginPage extends StatefulWidget {
  final Function(String) onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> authenticate(String username, String password) async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(Config.loginUrl);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        widget.onLoginSuccess(data['auth_token']);
      } else {
        // Gestione degli errori
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BookJourney',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF06402B),
        centerTitle: true,
      ),
      body: Stack(
        children: [

          Positioned(
            child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF06402B),
              ),
              height: 400,
              width: double.infinity,
            ),
            Expanded(child:
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEBEBEB),
              ),
              height: 400,
              width: double.infinity,
            ),
            ),

        ],
      )
          ),
          Positioned(
            top: 180,
            left: 25,
            right: 25,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(30.0),
                ),
              ),
              height: 550,
              width: double.infinity,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Column(
              children: [
                const SizedBox(height: 60.0),
                Image.asset(
                  'assets/images/book.png',
                  width: 70.0,
                  height: 70.0,
                  fit: BoxFit.cover,
                ),

    const SizedBox(height: 70.0),
    Expanded(child:
    SingleChildScrollView(
    padding: const EdgeInsets.only(top: 60.0),
    child: Column(
    children: [
    const Text("Welcome back",  style: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF06402B),
      fontFamily: 'Roboto', // Specifica il font
    ),
    ),
    const SizedBox(height: 80.0),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    contentPadding: const EdgeInsets.only(left: 20.0),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/images/user.ico',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF06402B), width: 3.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(0xFF06402B),
                        width: 5.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    contentPadding: const EdgeInsets.only(left: 20.0),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        'assets/images/key.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF06402B), width: 3.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(0xFF06402B),
                        width: 5.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06402B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                  ),
                  onPressed: () {
                    authenticate(
                      _usernameController.text,
                      _passwordController.text,
                    );
                  },
                  child: isLoading
                      ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.0,
                    ),
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
          ),
    )
        ],

      ),
    )
    ]
    )
    )
    ;
  }
}
