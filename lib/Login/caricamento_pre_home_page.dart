
import 'package:flutter/material.dart';
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
  List<String> likedBooks = [];
  bool isLoadingDatiCompleti = true;

  Future<void> fetchISBNPreferiti() async {
    String idUtente = '2';
    try {
      final response = await http.get(Uri.parse(Config.preferitiUrl));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as List<dynamic>;

        for (var preferito in data) {
          if (preferito['utente'] == idUtente) {
            try {
              String idLibroNeiPreferiti = preferito['libro'];
              String fullUrl = '${Config.libroUrl}$idLibroNeiPreferiti';
              final response = await http.get(
                Uri.parse(fullUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Token ${widget.authToken}',
                },
              );
              if (response.statusCode == 200 || response.statusCode == 201) {
                final data = json.decode(response.body);
                likedBooks.add(data['isbn']);
              }
            } catch (e) {
              return ;
            }
          }
        }

          setState(() {
            isLoadingDatiCompleti = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(authToken: widget.authToken, likedBooks: likedBooks,)),
          );




      } else {
        return ;
      }
    } catch (e) {
      return ;
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
      body:
      Center(
        child:
        Padding(padding: const EdgeInsets.symmetric(horizontal: 50),
        child:  Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Loading", style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF06402B),
          fontFamily: 'Roboto',
        ),
            ),
            const SizedBox(height: 30),
            if (isLoadingDatiCompleti) const LinearProgressIndicator(
              minHeight: 10,
              borderRadius: BorderRadius.all(Radius.circular(200)),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06402B)),
            )
          ],
        )
        )

      ),
      )

     ;
  }
}
