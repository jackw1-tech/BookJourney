import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Semplice con Autenticazione Djoser',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  String _authToken = ""; // Memorizza il token di autenticazione
  List<dynamic> _genres = []; // Memorizza la lista dei generi

  // Funzione per autenticarsi con Djoser
  Future<void> authenticate(String username, String password) async {
    final url = Uri.parse('http://macbook-air-di-giacomo-3.local:8000/auth/token/login/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _authToken = data['auth_token'];
        });
        print('Autenticazione riuscita. Token: $_authToken');
      } else {
        setState(() {
          _response = 'Errore di autenticazione: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Errore: $e';
      });
    }
  }

  // Funzione per inviare il testo con il token di autenticazione
  Future<void> sendText(String text) async {
    final url = Uri.parse('http://macbook-air-di-giacomo-3.local:8000/api/categoria-libro/');
    try {
      final body = jsonEncode({'nome': text});
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_authToken',
          'Content-Type': 'application/json',  // Indica che il corpo è in formato JSON
        },
        body: body,
      );

      if (response.statusCode == 201) {
        setState(() {
          _response = jsonDecode(response.body)['message'] ?? 'Successo!';
        });
      } else {
        setState(() {
          _response = 'Errore: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Errore: $e';
      });
    }
  }

  // Funzione per ottenere i generi
  Future<void> fetchGenres() async {
    final url = Uri.parse('http://macbook-air-di-giacomo-3.local:8000/api/categoria-libro/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _genres = data;  // Modifica in base alla risposta dell'API
        });
      } else {
        setState(() {
          _response = 'Errore: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Errore: $e';
      });
    }
  }

  void _showTextEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Inserisci una stringa'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Scrivi qui...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sendText(_controller.text);
              },
              child: Text('Invia'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App con Autenticazione Djoser'),
        actions: [
          IconButton(
            icon: Icon(Icons.login),
            onPressed: () async {
              final usernameController = TextEditingController();
              final passwordController = TextEditingController();

              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Effettua il login'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: InputDecoration(hintText: 'Username'),
                        ),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(hintText: 'Password'),
                          obscureText: true,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () {
                          authenticate(usernameController.text, passwordController.text);
                          Navigator.of(context).pop();
                        },
                        child: Text('Login'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showTextEditor(context),
              child: Text('Apri editor di testo'),
            ),
            ElevatedButton(
              onPressed: fetchGenres,
              child: Text('Visualizza Generi'),
            ),
            SizedBox(height: 20),
            Text(
              _response,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),
            _genres.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_genres[index]['nome'] ?? 'N/A'),
                    subtitle: Text('ID: ${_genres[index]['id']}'),
                  );
                },
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
