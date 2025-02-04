import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../Funzioni.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'SessioneLettura.dart';

class SemiCircleProgress extends StatelessWidget {
  final double progress;

  const SemiCircleProgress({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 50),
      painter: SemiCirclePainter(progress),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double progress;

  SemiCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final Paint progressPaint = Paint()
      ..color = Color(0xFF06402B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height);


    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Lettureincorso extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  int id_utente;

  int secondsElapsed = 0;
  Lettureincorso({required this.authToken, required this.dati, required this.id_utente });

  @override
  _LettureInCorsoState createState() => _LettureInCorsoState();
}

class _LettureInCorsoState extends State<Lettureincorso> {


  Future<void> interrompi_lettura(Map lettura) async {
    lettura['iniziato'] = false;
    lettura['interrotto'] = true;
    final start = Config.lettura_utente + widget.id_utente.toString() + "/" + lettura['libro'];
    final Uri endpoint = Uri.parse(start);
    final risposta = await http.put(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${widget.authToken}',
        },
        body: jsonEncode(lettura)
    );
    if(risposta.statusCode == 200 || risposta.statusCode == 201)
    {
      for(var lettura_caricata in widget.dati.value[3] )
      {
        if (lettura_caricata['id'] == lettura['id'])
        {
          setState(() {
            lettura_caricata['iniziato'] = false;
            lettura_caricata['interrotto'] = true;
          });
        }
      }


    }


  }



  void showLetturaDialog(Map libro, Map lettura) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () async {
                  await interrompi_lettura(lettura);
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
                  await showSessioneLetturaDialog(libro, lettura);
                  setState(() {
                    widget.dati;
                  });
                  },
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start reading session', textAlign: TextAlign.center,),
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


  Future<void> showSessioneLetturaDialog(Map libro, Map lettura) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TimerDialog(authToken:  widget.authToken,dati: widget.dati, libro: libro, lettura: lettura, id_utente:  widget.id_utente,);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var letture_not_complete = [];

    for (var lettura in  (widget.dati.value[3])) {
      if (lettura['completato'] == false && lettura['interrotto'] == false) {
        letture_not_complete.add(lettura);
      }
    }

    return  PopScope(
        canPop: false,
        child: ValueListenableBuilder(
        valueListenable: widget.dati,
        builder: (context, dati, child) {
          return NestedScrollView(
            headerSliverBuilder: (BuildContext context,
                bool innerBoxIsScrolled) {
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
            body: letture_not_complete.length != 0 ?SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.8,
                          child: ListView.builder(
                            itemCount: (letture_not_complete.length),
                            itemBuilder: (context, index) {
                              var libroTrovato = widget.dati.value[4]
                                  .firstWhere(
                                    (elemento) =>
                                elemento['id'] ==
                                    letture_not_complete[index]['libro'],
                                orElse: () => null,
                              );
                              var letturaTrovata = widget.dati.value[3]
                                  .firstWhere(
                                      (elemento) =>
                                  elemento['libro'] == libroTrovato['id'],
                                  orElse: () => {'id': "N/A"}
                              );
                              var pagine_rimaste = libroTrovato['numero_pagine'] -
                                  letture_not_complete[index]['numero_pagine_lette'];
                              var tempo_lettura_secondi = letture_not_complete[index]['tempo_di_lettura_secondi'];
                              var numero_ore_lettura = tempo_lettura_secondi ~/
                                  3600;
                              var numero_minuti_lettura = (tempo_lettura_secondi ~/
                                  60) - (numero_ore_lettura * 60);
                              return GestureDetector(
                                child: Card(
                                  elevation: 5,
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      libroTrovato['copertina_url'].isNotEmpty
                                          ? Image.network(
                                          libroTrovato['copertina_url'])
                                          : const Center(
                                          child: Icon(Icons.image, size: 30)),
                                      const SizedBox(width: 20),
                                      Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 20),
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: SemiCircleProgress(
                                                  progress: (double.parse(
                                                      letture_not_complete[index]['percentuale']) /
                                                      100)),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Text("$pagine_rimaste page left",
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                          SizedBox(height: 10),
                                          Text("Booking time:"),
                                          Row(
                                            children: [
                                              Text("$numero_ore_lettura hours",
                                                  style: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold)),
                                              SizedBox(width: 5),
                                              Text(
                                                  "$numero_minuti_lettura minutes",
                                                  style: TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold)),
                                            ],
                                          ),
                                          SizedBox(width: 200, height: 20)
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  showLetturaDialog(
                                      libroTrovato, letturaTrovata);
                                },
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ) : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [   Image.asset(
                    'assets/images/empty-folder.png',
                    width: 150,
                    height: 150,
                  ),
                    const Text("No reading in progress", style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),)],
                )

          ]
            ),
          );
        }
      ));
  }
}
