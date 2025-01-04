
import 'package:book_journey/Funzioni.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../HomePage/HomePage.dart';

class Caricamentoprehomepage extends StatefulWidget {
  final String authToken;

  const Caricamentoprehomepage({super.key, required this.authToken});

  @override
  CaricamentoState createState() => CaricamentoState();
}

class CaricamentoState extends State<Caricamentoprehomepage> {
  List<dynamic> preferiti = [];
  List<dynamic> Books_detail = [];
  List<dynamic> likedBooks_detail = [];
  List<dynamic> profilo_lettore = [];
  List<dynamic> letture_utente = [];
  bool isLoadingDatiCompleti = true;


  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([
    [],
    [],
    [],
    [],
    [],
  ]);

  Future<void> fetchISBNPreferiti() async {
    String idUtente = '2';
    try {
      String url_base = Config.preferitiUrl;
      String url_finale = 'utente/2';
      String preferiti_url = '$url_base$url_finale';
      print(preferiti_url);

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
        String profilo_lettore_url = url_base_profilo + idUtente + '/';

        final response_3 = await http.get(Uri.parse(profilo_lettore_url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_3.statusCode == 200 || response_3.statusCode == 201) {
          profilo_lettore.add(json.decode(response_3.body));
        }

        final response_4 = await http.get(Uri.parse(Config.lettura_utente),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token ${widget.authToken}',
            });

        if (response_4.statusCode == 200 || response_4.statusCode == 201) {
          letture_utente = (json.decode(response_4.body));
        }

        setState(() {
          isLoadingDatiCompleti = false;
        });

        dati.value[0] = preferiti;



        for (var preferito in dati.value[0]) {


          print(preferito);

          var libroTrovato = Books_detail.firstWhere(
                (libro) => libro['id'] == preferito['libro'],
            orElse: () => null, // Restituisce null se non viene trovato nessun libro
          );

          // Verifica se il libro è stato trovato
          if (libroTrovato != null) {
            likedBooks_detail.add(libroTrovato);
            print(libroTrovato);
          } else {

          }
        }


        dati.value[1] = likedBooks_detail;
        dati.value[2] = profilo_lettore;
        dati.value[3] = letture_utente;
        dati.value[4] = Books_detail;


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              authToken: widget.authToken,
              dati: dati,
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
    return Scaffold(
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
    );
  }
}
