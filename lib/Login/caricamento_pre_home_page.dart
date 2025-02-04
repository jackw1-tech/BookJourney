
import 'package:book_journey/Funzioni.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../HomePage/HomePage.dart';

class Caricamentoprehomepage extends StatefulWidget {
  final String authToken;
  final int id_utente;
  final bool prima_volta;

  const Caricamentoprehomepage({super.key, required this.authToken, required this.id_utente, required this.prima_volta});

  @override
  CaricamentoState createState() => CaricamentoState();
}

class CaricamentoState extends State<Caricamentoprehomepage> {
  List<dynamic> preferiti = [];
  List<dynamic> Books_detail = [];
  List<dynamic> likedBooks_detail = [];
  List<dynamic> profilo_lettore = [];
  List<dynamic> letture_utente = [];
  List<dynamic> sessioni_lettura_utente = [];
  bool isLoadingDatiCompleti = true;


  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([
    [],
    [],
    [],
    [],
    [],
    [],
  ]);

  Future<void> fetchISBNPreferiti() async {
    try {
      if(widget.prima_volta)
        {
          final response_3 = await http.post(
            Uri.parse(Config.profilo_utente),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },
            body: jsonEncode({'avatar': null, 'user': widget.id_utente}),
          );

          if (response_3.statusCode == 200 || response_3.statusCode == 201) {

            String id = widget.id_utente.toString();
            String url_base_profilo = "${Config.utente}$id/profilo-lettore/";
            final response_3 = await http.post(
              Uri.parse(url_base_profilo),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token ${widget.authToken}',
              },
              body: jsonEncode({
                "numero_ore_lettura": 0,
                "numero_giorni_lettura": 0,
                "numero_mesi_lettura": 0,
                "pagine_al_minuto_lette": 0.5,
                "numero_libri_letti": 0,
                "numero_libri_in_corso": 0,
                "numero_libri_interrotti": 0,
                "numero_pagine_lette": 0,
                "numero_sessioni_lettura": 0
              }),
            );
            print(response_3.body);
            if (response_3.statusCode != 200 && response_3.statusCode != 201) {

              return;
            }

          }

        }

      final response = await http.get(Uri.parse(Config.preferitiUrl));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List<dynamic>;
        preferiti = data;
        try {
              final response = await http.get(
                Uri.parse(Config.libroUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                final data = json.decode(response.body);
                Books_detail= data;
              }
            } catch (e) {}



        String url_base_profilo = Config.profilo_lettoreURL;
        String profilo_lettore_url = '$url_base_profilo${widget.id_utente}/';

        final response_3 = await http.get(Uri.parse(profilo_lettore_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_3.statusCode == 200 || response_3.statusCode == 201) {
          profilo_lettore.add(json.decode(response_3.body));
        }

        final response_4 = await http.get(Uri.parse("${Config.lettura_utente}${widget.id_utente}/"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_4.statusCode == 200 || response_4.statusCode == 201) {
          letture_utente = (json.decode(response_4.body));
        }

        final response_5 = await http.get(Uri.parse("${Config.dettagli_sessione_lettura}${widget.id_utente}/"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_5.statusCode == 200 || response_5.statusCode == 201) {
          sessioni_lettura_utente = (json.decode(response_5.body));
        }
        setState(() {
          isLoadingDatiCompleti = false;
        });

        dati.value[0] = preferiti;



        for (var preferito in dati.value[0]) {
          if(preferito['utente'] == widget.id_utente.toString())
            {
              var libroTrovato = Books_detail.firstWhere(
                    (libro) => libro['id'] == preferito['libro'],
                orElse: () => null,
              );


              if (libroTrovato != null) {
                likedBooks_detail.add(libroTrovato);

              }
            }

        }


        dati.value[1] = likedBooks_detail;
        dati.value[2] = profilo_lettore;
        dati.value[3] = letture_utente;
        dati.value[4] = Books_detail;
        dati.value[5] = sessioni_lettura_utente;






        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              authToken: widget.authToken,
              dati: dati,
              id_utente: widget.id_utente,
            ),
          ),
        );
      } else {
        print('Errore: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore durante la richiesta: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchISBNPreferiti();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child:  Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Loading",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF06402B),
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 30),
              if (isLoadingDatiCompleti)
                const LinearProgressIndicator(
                  minHeight: 10,
                  borderRadius: BorderRadius.all(Radius.circular(200)),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06402B)),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}
