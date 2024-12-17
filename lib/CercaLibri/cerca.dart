import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

class Cerca_Libri extends StatefulWidget {
  final String authToken;

  Cerca_Libri({required this.authToken});

  @override
  _CercaLibriState createState() => _CercaLibriState();
}

class _CercaLibriState extends State<Cerca_Libri> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  List<dynamic> _genres = []; // Memorizza la lista dei generi
  List<dynamic> _books = [];

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
            for (libro in jsonDecode(response.body)) {
              if (libro['google_books_id'] == id) {
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

                  if (response.statusCode == 200 ||
                      response.statusCode == 201) {
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
    // Lista di 50 libri
    final List<String> libri = List.generate(50, (index) => 'Libro ${index + 1}');

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text(
            'BookJourney',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF06402B),
          centerTitle: true,
          floating: true,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Libri disponibili:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
              return ListTile(
                title: Text(libri[index]), // Mostra il nome del libro
                subtitle: Text('Descrizione del libro $index'),
              );
            },
            childCount: libri.length, // Il numero di libri
          ),
        ),
      ],
    );
  }
}