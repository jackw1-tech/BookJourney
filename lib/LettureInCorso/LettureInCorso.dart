import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../Funzioni.dart';

class Lettureincorso extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);

  Lettureincorso({required this.authToken, required this.dati });

  @override
  _LettureInCorsoState createState() => _LettureInCorsoState();
}

class _LettureInCorsoState extends State<Lettureincorso> {

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
                children: [Text("ciao")]
              ),
            ),
          ],
        ),
      ),
    );
  }


}
