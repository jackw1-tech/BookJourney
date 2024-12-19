import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

class Cerca_Libri extends StatefulWidget {
  final String authToken;
  List<String> likedBooks = [];
  Cerca_Libri({required this.authToken, required this.likedBooks});

  @override
  _CercaLibriState createState() => _CercaLibriState();
}

class _CercaLibriState extends State<Cerca_Libri> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  List<dynamic> _genres = []; // Memorizza la lista dei generi
  List<dynamic> _books = [];
  bool isSearch = false;
  bool isLoadingLike = false;
  List<String> likedBooks = [];



  Future<void> elimina_preferito(String bookISBN) async {
    try {
      final response = await http.get(
        Uri.parse(Config.libroUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final lista_libri = json.decode(response.body) as List<dynamic>;
        print(lista_libri);
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
              print(libro_singolo);
              final response3 = await http.get(Uri.parse(Config.preferitiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },);
              if (response3.statusCode == 200 || response3.statusCode == 201) {
                final lista_preferiti = json.decode(response3.body);
                print(lista_preferiti);
                for (var pref in lista_preferiti) {
                  if (pref['libro'] == libro_singolo['id']) {
                    print("ciao");
                    String id_pref = pref['id'];
                    String fullUrlEliminaPref = '${Config
                        .preferitiUrl}$id_pref/';
                    print(fullUrlEliminaPref);
                    final response4 = await http.delete(
                      Uri.parse(fullUrlEliminaPref),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Token ${widget.authToken}',
                      },
                    );

                    if (response4.statusCode == 200 || response4.statusCode == 204) {
                      print('Eliminazione avvenuta con successo');
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
      print('Errore durante la chiamata API: $e');
      return; // Ritorna una lista vuota in caso di eccezione
    }
  }

  void toggleLike(String bookISBN, Map bookData) async {
    setState(() {
      isLoadingLike = true;
    });
    if (likedBooks.contains(bookISBN)) {
      await elimina_preferito(bookISBN);
      setState(() {
        likedBooks.remove(bookISBN);
      });
    } else {
      await metti_like(bookData["google_books_id"], bookData);
      setState(() {
        likedBooks.add(bookISBN);
      });
    }
    setState(() {
      isLoadingLike = false;
    });
  }



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

  Future<List<dynamic>> fetchPreferiti() async {
    try {
      final response = await http.get(Uri.parse(Config.preferitiUrl));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List<dynamic>;
        return data; // Converte List<dynamic> in List<String>
      } else {
        print('Errore: ${response.statusCode}');
        return []; // Ritorna una lista vuota in caso di errore
      }
    } catch (e) {
      print('Errore durante la chiamata API: $e');
      return []; // Ritorna una lista vuota in caso di eccezione
    }
  }


  Future<void> fetchBooks(String query) async {
    int id_utente = 2;
    setState(() {
      isSearch = true;
    });
    if (likedBooks.isEmpty) {
       var lista_preferiti = await fetchPreferiti();
       for (var preferito in lista_preferiti) {
         if(preferito['utente'] == id_utente)
           {
             try {
               String id_libro_nei_preferiti = preferito['libro'];
               String fullUrl = '${Config.libroUrl}$id_libro_nei_preferiti';
               print(fullUrl);
               final response = await http.get(
                 Uri.parse(fullUrl),
                 headers: {
                 'Content-Type': 'application/json',
                 'Authorization': 'Token ${widget.authToken}',
                 },);
               if (response.statusCode == 200 || response.statusCode == 201 ) {
                 final data = json.decode(response.body);
                 setState(() {
                   likedBooks.add(data['isbn']);
                 });

               } else {
                 print('Errore: ${response.statusCode}');
               }
             } catch (e) {
               print('Errore durante la chiamata API: $e');
             }

           }

       }
       print(likedBooks);


    }
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
            _genres = [];
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

  Future<void> metti_like(String id, Map libro) async {
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
          print(libro_db['isbn']);
          print(libro['isbn']);
          if (libro_db['isbn'].toString() == libro['isbn'].toString()) {

            print(Uri.parse(Config.preferitiUrl));
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
                    return;
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
                return;
              } else {
                print('Errore: ${response.statusCode}, ${response.body}');
              }
            } catch (e) {
              print('Errore durante la richiesta: $e');
            }


          }
        }

        //creare il libro e inserirlo nei preferiti

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
          const Text(
            'Results:',
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
                      child: Icon(
                        Icons.favorite,
                        color: _books[index]['volumeInfo'] != null &&
                            _books[index]['volumeInfo']['industryIdentifiers'] != null &&
                            _books[index]['volumeInfo']['industryIdentifiers'].isNotEmpty &&
                            _books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'] != null &&
                            likedBooks.contains(_books[index]['volumeInfo']['industryIdentifiers'][0]['identifier'])
                            ? Colors.red
                            : Colors.grey,
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