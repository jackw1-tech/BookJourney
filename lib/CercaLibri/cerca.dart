import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

class Cerca_Libri extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  Cerca_Libri({required this.authToken, required this.dati});

  @override
  _CercaLibriState createState() => _CercaLibriState();
}

class _CercaLibriState extends State<Cerca_Libri> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _books = [];
  bool isSearch = false;
  bool isLoadingLike = false;
  List<String> isbn_preferiti = [];



  Future<void> elimina_preferito(String bookISBN, Map bookData) async {
    try {
      final response = await http.get(
        Uri.parse(Config.libroUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final lista_libri = json.decode(response.body) as List<dynamic>;
        for (var libro in lista_libri) {
          if (libro['isbn'] == bookISBN) {
            String id_libro = libro['id'];
            String fullUrlDettagliLibro = '${Config.libroUrl}$id_libro';
            final response2 = await http.get(
              Uri.parse(fullUrlDettagliLibro),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },);
            if (response2.statusCode == 200 || response2.statusCode == 201) {

              final libro_singolo = json.decode(response2.body);
              final response3 = await http.get(Uri.parse(Config.preferitiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },);
              if (response3.statusCode == 200 || response3.statusCode == 201) {
                final lista_preferiti = json.decode(response3.body);

                for (var pref in lista_preferiti) {
                  if (pref['libro'] == libro_singolo['id']) {

                    String id_pref = pref['id'];
                    String fullUrlEliminaPref = '${Config
                        .preferitiUrl}$id_pref/';

                    final response4 = await http.delete(
                      Uri.parse(fullUrlEliminaPref),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Token ${widget.authToken}',
                      },
                    );

                    if (response4.statusCode == 200 || response4.statusCode == 204) {

                      setState(() {
                        isbn_preferiti.remove((bookISBN));
                        widget.dati.value[1].removeWhere((book) {
                          bool shouldRemove = book['isbn'] == bookData['isbn'];
                          if (shouldRemove) {
                            print("Rimuovendo libro con id: ${book['isbn']}");
                          }
                          return shouldRemove;
                        });
                        widget.dati.value[0].removeWhere((preferito) {
                          bool shouldRemove = preferito['id'] == id_pref;
                          if (shouldRemove) {
                            print("Rimuovendo preferito con id: ${preferito['id']}");
                          }
                          return shouldRemove;
                        });
                      });
                      return;
                    } else {
                      print('Errore nella richiesta DELETE: ${response4.statusCode}');
                    }
                  }
                }

              }
            }
          }
        }
      }
    }

    catch (e) {
      return;
    }
  }

  void toggleLike(String bookISBN, Map bookData) async {
    setState(() {
      isLoadingLike = true;
    });
    if (isbn_preferiti.contains(bookISBN)) {
      await elimina_preferito(bookISBN, bookData);

    } else {
      var libro = await metti_like(bookData["google_books_id"], bookData);

      widget.dati.value[1].add(libro);
      isbn_preferiti.add(bookISBN);
    }
    setState(() {
      isLoadingLike = false;
    });
  }

  Future<void> fetchBooks(String query) async {
    
    if(isbn_preferiti.isEmpty){
      for(var libro in widget.dati.value[1]){
        isbn_preferiti.add(libro["isbn"]);
      }
    }
   

    setState(() {
      isSearch = true;
    });




    final String apiKey = dotenv.env['API_KEY'] ?? '';
    const String endpoint = 'https://www.googleapis.com/books/v1/volumes';
    final String url = '$endpoint?q=$query&key=$apiKey';

    try {

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data["items"] != null) {
          setState(() {
            _books = data["items"];
            isSearch = false;
          });
        } else {
          print('No books found or items is null');
        }

      } else {
        print('Errore: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore durante la chiamata API: $e');
    }
    finally
        {
          setState(() {
            isSearch = false;
          });
        }
  }



  Future<Map<dynamic,dynamic>?> metti_like(String id, Map libro) async {
    int id_utente = 2;
    String libro_url = dotenv.env['LIBRO'] ?? '';
    try {

      final response = await http.get(
        Uri.parse(libro_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        for (var libro_db in jsonDecode(response.body)) {
          if (libro_db['isbn'].toString() == libro['isbn'].toString()) {
            try{
              final response = await http.get(
                  Uri.parse(Config.preferitiUrl),
                  headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
              },);
              if (response.statusCode == 200 || response.statusCode == 201) {
                for (var preferito_db in jsonDecode(response.body)) {
                  if (preferito_db['libro'].toString() == libro_db['id'].toString() &&
                      preferito_db['utente'].toString() == id_utente.toString() )
                  {
                    return libro_db;
                  }
                }
              }

            } catch (e) {
              print('Errore durante la richiesta: $e');
              }


            String api = dotenv.env['UTENTE'] ?? '';
            String preferiti = '$api$id_utente/preferiti/';

            String id_libro = libro_db['id'];
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
                var responseData = jsonDecode(response.body);
                widget.dati.value[0].add(responseData);
                return libro_db;
              } else {
                print('Errore: ${response.statusCode}, ${response.body}');
              }
            } catch (e) {
              print('Errore durante la richiesta: $e');
            }


          }
        }



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
                        var responseData = jsonDecode(response.body);
                        widget.dati.value[0].add(responseData);
                        return libro;
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
    }
    catch (e) {
      print('Errore durante la richiesta: $e');
    }


  }




  @override
  Widget build(BuildContext context) {

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

    SliverToBoxAdapter( child:
    Padding(
      
    padding: EdgeInsets.only(left: 20, right: 20),
    child:Column(
        children: [
      SizedBox(height: 10.0),
      TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search books',
          prefixIcon: GestureDetector( child: Icon(Icons.search ), onTap : (){
            if (_controller.text.isEmpty)
              {
                setState(() {
                  _books = [];
                });
              }
            else {
              fetchBooks(_controller.text);
            }}),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF06402B),
              width: 3.0,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFF06402B),
              width: 5.0,
            ),
          ),
        ),
      ),
          SizedBox(height: 10.0),
          Text(
            _books.isNotEmpty? 'Results:' : '',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.0),
          isSearch ? const CircularProgressIndicator(color: Color(0xFF06402B),) : SizedBox(height: 0.0),
    ],
    )
    ),
    ),

       _books.isNotEmpty?  SliverList(
          delegate: SliverChildBuilderDelegate(

                (BuildContext context, int index) {
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 42,
                        height: 120,
                        child: (_books[index]['volumeInfo']['imageLinks']?['thumbnail'] != null)
                            ? Image.network(
                          _books[index]['volumeInfo']['imageLinks']?['thumbnail'] ?? '',
                          fit: BoxFit.fill,
                        )
                            : Image.asset(
                          'assets/images/img.png', // Immagine di fallback
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      _books[index]['volumeInfo']['title'] ?? 'N/A',
                    ),
                    subtitle: Text(
                      'Author: ${_books[index]['volumeInfo']['authors']?.first ?? 'N/A'}',
                    ),
                    trailing: GestureDetector(

                      onTap: isLoadingLike
                          ? null : () {
                        Map<String, dynamic> libro = {
                          "titolo": _books[index]['volumeInfo']['title'] ?? 'N/A',
                          "autore": (_books[index]['volumeInfo']['authors'] != null &&
                              _books[index]['volumeInfo']['authors'] is List)
                              ? _books[index]['volumeInfo']['authors']?.join(', ') ?? 'N/A'
                              : 'N/A',
                          "numero_pagine": _books[index]['volumeInfo']['pageCount'] ?? 0,
                          "copertina": null,
                          "descrizione": _books[index]['volumeInfo']['description'] ?? 'N/A',
                          "data_pubblicazione": null,
                          "google_books_id": _books[index]['id'] ?? 'N/A',
                          "copertina_url": _books[index]['volumeInfo']['imageLinks'] != null
                              ? _books[index]['volumeInfo']['imageLinks']['thumbnail'] ?? ''
                              : '',
                          "link_esterna":
                          _books[index]['volumeInfo']['canonicalVolumeLink'] ?? '',
                          "isbn": (_books[index]['volumeInfo']['industryIdentifiers'] !=
                              null &&
                              _books[index]['volumeInfo']['industryIdentifiers'] is List &&
                              _books[index]['volumeInfo']['industryIdentifiers']
                                  .isNotEmpty)
                              ? _books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'] ??
                              'N/A'
                              : 'N/A',
                          "categoria": null,
                        };
                        toggleLike(libro["isbn"], libro);

                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.favorite,
                          color: _books[index]['volumeInfo'] != null &&
                              _books[index]['volumeInfo']['industryIdentifiers'] != null &&
                              _books[index]['volumeInfo']['industryIdentifiers'].isNotEmpty &&
                              _books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'] != null &&
                              isbn_preferiti.contains(_books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'])
                              ? Colors.red
                              : Colors.grey,
                        ),
                      )

                    ),
                  );
                },
            childCount: _books.length, // Il numero di libri
          ),
        ) :  SliverToBoxAdapter( child: Container()),
      ],
    );
  }
}