import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../Funzioni.dart';

class Profilo extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);

  Profilo({super.key, required this.authToken, required this.dati });

  @override
  _ProfiloState createState() => _ProfiloState();
}

class _ProfiloState extends State<Profilo> {

  var utils = Utils();


  Future<void> eliminaPreferito(String bookISBN, Map bookData) async {
    try {
      final response = await http.get(
        Uri.parse(Config.libroUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final listaLibri = json.decode(response.body) as List<dynamic>;
        for (var libro in listaLibri) {
          if (libro['isbn'] == bookISBN) {
            String idLibro = libro['id'];
            String fullUrlDettagliLibro = '${Config.libroUrl}$idLibro';
            final response2 = await http.get(
              Uri.parse(fullUrlDettagliLibro),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },);
            if (response2.statusCode == 200 || response2.statusCode == 201) {
              final libroSingolo = json.decode(response2.body);
              final response3 = await http.get(Uri.parse(Config.preferitiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },);
              if (response3.statusCode == 200 || response3.statusCode == 201) {
                final listaPreferiti = json.decode(response3.body);

                for (var pref in listaPreferiti) {
                  if (pref['libro'] == libroSingolo['id']) {
                    String idPref = pref['id'];
                    String fullUrlEliminaPref = '${Config.preferitiUrl}$idPref/';

                    final response4 = await http.delete(
                      Uri.parse(fullUrlEliminaPref),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Token ${widget.authToken}',
                      },
                    );

                    if (response4.statusCode == 200 ||
                        response4.statusCode == 204) {
                      setState(() {
                        widget.dati.value[1].removeWhere((book) {
                          bool shouldRemove = book['isbn'] == bookData['isbn'];
                          return shouldRemove;
                        });
                        widget.dati.value[0].removeWhere((preferito) {
                          bool shouldRemove = preferito['id'] == idPref;
                          return shouldRemove;
                        });
                      });
                      return;
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





  Future<void> markAsDoneBook(Map libro, bool iniziato) async {
    List<dynamic> datiAttuali = widget.dati.value[2];

    datiAttuali[0]['numero_libri_letti'] += 1;
    datiAttuali[0]['numero_pagine_lette'] += (libro['numero_pagine']);
    datiAttuali[0]['numero_ore_lettura'] =
        (datiAttuali[0]['numero_pagine_lette'] /
            datiAttuali[0]['pagine_al_minuto_lette']) ~/ 60;
    datiAttuali[0]['numero_giorni_lettura'] =
        datiAttuali[0]['numero_ore_lettura']  ~/ 24;
    datiAttuali[0]['numero_mesi_lettura'] =
        datiAttuali[0]['numero_giorni_lettura'] ~/ 30;


    setState(() {
      widget.dati.value[2][0] = datiAttuali[0];
    });


    String profiloLettoreUrl = '${Config.profilo_lettoreURL}2/';

    final response = await http.put(Uri.parse(
        profiloLettoreUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${widget.authToken}',
      },
      body: jsonEncode(widget.dati.value[2][0]),

    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      startReading(libro, true);
    }
  }

  Future<void> startReading(Map libro, bool completato) async {

    final Map<String, dynamic> data = utils.componi_Json_prima_lettura(libro, completato);
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
         if (response.statusCode == 200 || response.statusCode == 201){
           print(jsonDecode(response.body));
           setState(() {
             widget.dati.value[3].add(jsonDecode(response.body));
           });

    }


    } catch (e) {
      print("Errore durante la richiesta: $e");
    }
  }


  void howPreferitiDialog(Map libro) {
    showDialog(context: context, builder: (BuildContext context) {
      return SimpleDialog(
        children: [

        SimpleDialogOption(
            onPressed: () async {
              await eliminaPreferito(libro['isbn'], libro);
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
              await startReading(libro, false);
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
            onPressed: () async {
              await markAsDoneBook(libro, false);
              Navigator.pop(context);
            },
            child: const Row(
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


  void showLibreriaDialog(Map libro) {
    showDialog(context: context, builder: (BuildContext context) {
      return SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () async {
              await eliminaPreferito(libro['isbn'], libro);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Remove', textAlign: TextAlign.center),
                  SizedBox(width: 5),
                  Icon(Icons.remove_circle, color: Color(0xFF06402B),)
                ]
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () async {
              await startReading(libro, false);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Stop reading', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.stop_circle_rounded, color: Color(0xFF06402B),)
                ]
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () async {
              await markAsDoneBook(libro, true);
              Navigator.pop(context);
            },
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Complete', textAlign: TextAlign.center,),
                  SizedBox(width: 5),
                  Icon(Icons.incomplete_circle, color: Color(0xFF06402B),)
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
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        color: Colors.black, // Colore del bordo
                        width: 1.0, // Spessore del bordo
                      ),
                      borderRadius: BorderRadius.circular(10), // Raggio degli angoli
                    ),
                    child: SizedBox(
                      width: 500,
                      height: 200,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_sharp),
                              SizedBox(width: 10),
                              Text(
                                'Reading time',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.dati.value[2][0]['numero_mesi_lettura'].toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Months',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 50),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(widget.dati.value[2][0]['numero_giorni_lettura'] - (widget.dati.value[2][0]['numero_mesi_lettura'] * 30)).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Days',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 50),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(widget.dati.value[2][0]['numero_ore_lettura'] - (widget.dati.value[2][0]['numero_giorni_lettura'] * 24)).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'Hours',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          Column(
                            children: [
                              Text(
                                '${widget.dati.value[2][0]['numero_libri_letti'].toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Books Readed',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                  SizedBox(
                    height: 380,
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
                              side: const BorderSide(
                                color: Colors.black, // Colore del bordo
                                width: 0.5, // Spessore del bordo
                              ),
                              borderRadius: BorderRadius.circular(10), // Raggio degli angoli
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 150,
                                child: Column(
                                  children: [
                                    imageUrl.isNotEmpty
                                        ? Image.network(imageUrl)
                                        : const Center(child: Icon(Icons.image, size: 30)),
                                    const SizedBox(height: 10),
                                    Text('$titolo'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            howPreferitiDialog(book);
                          },
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
                  SizedBox(
                    height: 380,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.dati.value[3].length,
                      itemBuilder: (context, index) {
                        var libroTrovato = widget.dati.value[1].firstWhere(
                              (elemento) => elemento['id'] == widget.dati.value[3][index]['libro'],
                          orElse: () => null,
                        );

                        var imageUrl = libroTrovato['copertina_url'];
                        var titolo = libroTrovato['titolo'];
                        var stato = widget.dati.value[3][index]["completato"] == true
                            ? "completato"
                            : widget.dati.value[3][index]["interrotto"] == true
                            ? "interrotto"
                            : "iniziato";

                        return GestureDetector(
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                color: Colors.black, // Colore del bordo
                                width: 0.5, // Spessore del bordo
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 150,
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        imageUrl.isNotEmpty
                                            ? Image.network(imageUrl)
                                            : const Center(child: Icon(Icons.image, size: 30)),
                                        const SizedBox(height: 10),
                                        Text('$titolo'),
                                      ],
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Stack(
                                        children: [
                                          LinearProgressIndicator(
                                            value: double.parse(widget.dati.value[3][index]["percentuale"]) / 100,
                                            minHeight: 20,
                                            backgroundColor: Colors.grey[300],
                                            color: stato == "completato"
                                                ? const Color(0xFF06402B)
                                                : stato == "interrotto"
                                                ? Colors.red
                                                : Colors.amber,
                                          ),
                                          Positioned.fill(
                                            child: Center(
                                              child: Text(
                                                '${double.parse(widget.dati.value[3][index]["percentuale"])}%',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            howPreferitiDialog(libroTrovato);
                          },
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
