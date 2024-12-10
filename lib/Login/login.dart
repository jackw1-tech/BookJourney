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
      }
    } finally {
      setState(() {
        isLoading =
        false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(
          'BookJourney',
          style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white
        ),

      ),
        backgroundColor: const Color(0xFF06402B).withOpacity(1),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false,
      body: Container(

      decoration: const BoxDecoration(
                  image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                  ),
                  ),

    child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 80.0),
            Image.asset(
              'assets/images/book.png',
              width: 70.0,
              height: 70.0,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 165.0),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                  hintText: 'Username',
                  contentPadding: const EdgeInsets.only(left: 20.0),
                prefixIcon: Padding(
                  padding: const EdgeInsets.fromLTRB(15,10,10,10),
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
                    color:Color(0xFF06402B),
                    width: 5.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20.0),

            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                contentPadding: const EdgeInsets.only(left: 20.0),
                prefixIcon: Padding(
                  padding: const EdgeInsets.fromLTRB(15,10,10,10),
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
              style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>( Color(0xFF06402B)),
                ),
              onPressed: () {
                authenticate(_usernameController.text, _passwordController.text);
              },
              child:  isLoading
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.0,
                ),
              )
                  :  const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
