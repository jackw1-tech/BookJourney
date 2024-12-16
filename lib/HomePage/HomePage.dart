import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  List<dynamic> _books = [];

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


  
  Future<void> fetchBooks(String query) async {
    final String apiKey = dotenv.env['API_KEY'] ?? '';
    const String endpoint = 'https://www.googleapis.com/books/v1/volumes';
    final String url = '$endpoint?q=$query&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _books = data["items"];
          _genres = [];
        });
      } else {
        print('Errore: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore durante la chiamata API: $e');
    }
  }

  Future<void> metti_like(String id, Map libro) async {
          String libro_url = dotenv.env['LIBRO'] ?? '';
          try {
            final body = jsonEncode(libro);

            final response = await http.post(
              Uri.parse(libro_url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },
              body: body,
            );

            if (response.statusCode == 200 || response.statusCode == 201) {

                    try {

                    final response = await http.get(
                    Uri.parse(libro_url),
                    headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Token ${widget.authToken}',
                    },
                    );

                    if (response.statusCode == 200 || response.statusCode == 200) {

                              for (libro in jsonDecode(response.body))
                                {
                                  if (libro['google_books_id'] == id)
                                    {
                                    String api = dotenv.env['UTENTE'] ?? '';
                                    int id_utente = 2;
                                    String preferiti = '$api$id_utente/preferiti/';
                                    print(preferiti);
                                    String id_libro = libro['id'];
                                    try {
                                    final body = jsonEncode({'libro': id_libro});

                                    final response = await http.post(
                                    Uri.parse(preferiti),
                                    headers: {
                                    'Content-Type': 'application/json',
                                      'Authorization': 'Token ${widget.authToken}',
                                    },
                                    body: body,
                                    );

                                    if (response.statusCode == 200 || response.statusCode == 201) {
                                    print('Successo: ${response.body}');
                                    } else {
                                    print('Errore: ${response.statusCode}, ${response.body}');
                                    }
                                    } catch (e) {
                                    print('Errore durante la richiesta: $e');
                                    }
                                    }

                                }



                    } else {
                    print('Errore: ${response.statusCode}, ${response.body}');
                    }
                    } catch (e) {
                    print('Errore durante la richiesta: $e');
                    }


            } else {
              print('Errore: ${response.statusCode}, ${response.body}');
            }
          } catch (e) {
            print('Errore durante la richiesta: $e');
          }













  }
  

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
          _books = [];
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

  void _showBookSearch(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Inserisci il nome'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: 'Scrivi qui...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                fetchBooks(_controller.text);
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
              onPressed: () => _showBookSearch(context),
              child: Text('Cerca libri'),
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
            ) : Container(),
            _books.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: _books.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10), // Arrotondamento dei bordi
                      child: SizedBox(
                        width: 42, // Larghezza del rettangolo
                        height: 120, // Altezza del rettangolo
                        child: (_books[index]['volumeInfo']['imageLinks']?['thumbnail'] != null)
                            ? Image.network(
                          _books[index]['volumeInfo']['imageLinks']['thumbnail'],
                          fit:  BoxFit.fill, // Per adattare l'immagine al contenitore
                        )
                            : Image.asset(
                          'assets/images/img.png', // Immagine di fallback
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(_books[index]['volumeInfo']['title'] ?? 'N/A'),
                    subtitle: Text('Author: ${_books[index]['volumeInfo']['authors'][0]}' ),
                    trailing:  GestureDetector(
                      onTap: () {
                        Map<String, dynamic> libro = {
                          "titolo": _books[index]['volumeInfo']['title'] ?? 'N/A',
                          "autore": (_books[index]['volumeInfo']['authors'] != null && _books[index]['volumeInfo']['authors'] is List)
                              ? _books[index]['volumeInfo']['authors'].join(', ')
                              : 'N/A',
                          "numero_pagine": _books[index]['volumeInfo']['pageCount'] ?? 0,
                          "copertina": null,
                          "descrizione": _books[index]['volumeInfo']['description'] ?? 'N/A',
                          "data_pubblicazione": null,
                          "google_books_id": _books[index]['id'] ?? 'N/A',
                          "copertina_url": _books[index]['volumeInfo']['imageLinks'] != null ? _books[index]['volumeInfo']['imageLinks']['thumbnail'] ?? '' : '',
                          "link_esterna": _books[index]['volumeInfo']['canonicalVolumeLink'] ?? '',
                          "isbn": (_books[index]['volumeInfo']['industryIdentifiers'] != null && _books[index]['volumeInfo']['industryIdentifiers'] is List && _books[index]['volumeInfo']['industryIdentifiers'].isNotEmpty)
                              ? _books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'] ?? 'N/A'
                              : 'N/A',
                          "categoria":  null,
                        };
                        metti_like(_books[index]['id'],libro);
                      },
                      child: const Icon(Icons.favorite),
                    ),
                  );
                },
              ),
            ) : Container(),
          ],
        ),
      ),
    );
  }
}
