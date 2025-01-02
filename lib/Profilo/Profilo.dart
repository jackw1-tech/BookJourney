import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';

import '../Funzioni.dart';

class Profilo extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);

  Profilo({required this.authToken, required this.dati });

  @override
  _ProfiloState createState() => _ProfiloState();
}

class _ProfiloState extends State<Profilo> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  List<dynamic> _genres = [];
  List<dynamic> _books = [];
  var utils = Utils();


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



  Future<void> mark_as_done_book(Map libro) async{

    List<dynamic> dati_attuali = widget.dati.value[2];
    for (var app in dati_attuali) {
      if (app is Map<String, dynamic>) { // Verifica che l'elemento sia una mappa
        app.forEach((key, value) {
          print('Chiave: $key, Valore: $value, Tipo del valore: ${value.runtimeType}'); // Stampa chiave e valore
        });
      } else {
        print('L\'elemento non è una mappa');
      }
    }
    print(libro['numero_pagine']);
    print(libro['numero_pagine'].runtimeType);
    dati_attuali[0]['numero_libri_letti'] += 1;
    dati_attuali[0]['numero_pagine_lette'] += (libro['numero_pagine']);
    dati_attuali[0]['numero_ore_lettura'] = (dati_attuali[0]['numero_pagine_lette'] / dati_attuali[0]['pagine_al_minuto_lette'])/60;
    dati_attuali[0]['numero_giorni_lettura'] = dati_attuali[0]['numero_ore_lettura'] / 24;
    dati_attuali[0]['numero_mesi_lettura'] = dati_attuali[0]['numero_giorni_lettura'] / 30;



    setState(() {
      widget.dati.value[2][0] = dati_attuali[0];
    });


    String url_base_profilo = Config.profilo_lettoreURL;
    String profilo_lettore_url = url_base_profilo + "2" + '/';

    final response = await http.put(Uri.parse(
        profilo_lettore_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${widget.authToken}',
      },
      body: jsonEncode(widget.dati.value[2][0]),

    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("ciao");
      print(json.decode(response.body));
    }

  }

  Future<void> start_reading(Map libro) async {
    final Map<String, dynamic> data = utils.componi_Json_prima_lettura(libro);
    final Uri endpoint = Uri.parse(Config.crea_lettura_utente);
    try {
      final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Lettura inserita con successo");
        print((response.body));
        setState(() {
          var data = response.body;
          widget.dati.value[3].add(data);
        });

      } else {
        print("Errore durante l'inserimento della lettura: ${response.statusCode}");
        print(response.body);
      }
    } catch (e) {
      print("Errore durante la richiesta: $e");
    }
  }


  void show_preferiti_dialog(Map libro){
    print( widget.dati.value[3]);
    showDialog(context: context,   builder: (BuildContext context) {
      return SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await elimina_preferito(libro['isbn'], libro);
              Navigator.pop(context);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text('Unfavorite', textAlign: TextAlign.center),
              SizedBox(width: 5),
              Icon(Icons.heart_broken_outlined, color: Color(0xFF06402B),)
            ]
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () async {
              await start_reading(libro);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start reading', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.menu_book, color: Color(0xFF06402B),)
                ]
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () async  {
              await mark_as_done_book(libro);
              Navigator.pop(context);
            },
            child:const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Mark as done', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.done, color: Color(0xFF06402B),)
                ]
            ),
          ),


        ],

      );
    }
    );


  }



  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
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
        ];
      },
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Card(
                    child: Container(
                      width: 500,
                      height: 200,
                      child: Column(
                          children: [
                            Text('Ore di lettura: ${widget.dati.value[2][0]['numero_ore_lettura'].toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Giorni di lettura: ${widget.dati.value[2][0]['numero_giorni_lettura'].toStringAsFixed(1)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Libri letti: ${widget.dati.value[2][0]['numero_libri_letti'].toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ]
                      )
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Libri preferiti:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Aggiungi qui il contenuto della lista orizzontale
                  Container(
                    height: 380, // Altezza della lista orizzontale
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dati.value[1].length,
                      itemBuilder: (context, index) {
                        var book = widget.dati.value[1][index] ?? '';
                        var imageUrl = book['copertina_url'];
                        var titolo = book['titolo'];

                        return GestureDetector(
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10), // Imposta il raggio degli angoli
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  child: Column(
                                    children: [
                                      imageUrl.isNotEmpty
                                          ? Image.network(imageUrl) // Carica l'immagine dalla rete
                                          : const Center(child: Icon(Icons.image, size: 30)),
                                      const SizedBox(height: 10),
                                      Text('$titolo'),

                                    ],

                                  ),
                                  width: 150,
                                )
                            ),
                          ),
                          onTap: (){show_preferiti_dialog(book);},
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Libreria:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Aggiungi qui il contenuto della lista orizzontale
                  Container(
                    height: 200, // Altezza della lista orizzontale
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dati.value[3].length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('Libro ${ widget.dati.value[3][index]["libro"] }', style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
