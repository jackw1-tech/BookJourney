import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

class HomePage extends StatefulWidget {
  final String authToken;

  HomePage({required this.authToken});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  List<dynamic> _genres = []; // Memorizza la lista dei generi

  // Funzione per inviare il testo con il token di autenticazione
  Future<void> sendText(String text) async {
    final url = Uri.parse(Config.libroUrl);
    try {
      final body = jsonEncode({'nome': text});
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token ${widget.authToken}',
          'Content-Type': 'application/json',
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
    final url = Uri.parse(Config.libroUrl);
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token ${widget.authToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _genres = data;
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
