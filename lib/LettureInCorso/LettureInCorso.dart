import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../Funzioni.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class SemiCircleProgress extends StatelessWidget {
  final double progress;

  const SemiCircleProgress({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 50), // Dimensione del semicerchio
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

    // Disegna il semicerchio di sfondo
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Inizio dell'arco (180 gradi)
      pi, // Lunghezza dell'arco (semicerchio = pi radianti)
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Inizio dell'arco
      pi * progress.clamp(0.0, 1.0), // Lunghezza dell'arco limitata a pi (semicerchio)
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

  Lettureincorso({required this.authToken, required this.dati });

  @override
  _LettureInCorsoState createState() => _LettureInCorsoState();
}

class _LettureInCorsoState extends State<Lettureincorso> {
  void showLetturaDialog(Map libro) {
    print(widget.dati.value[4].length);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              SimpleDialogOption(
                onPressed: () async {
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
                  Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    var letture_not_complete = [];
    for (var lettura in  (widget.dati.value[3])) {
      if (lettura['completato'] == false && lettura['interrotto'] == false) {
        letture_not_complete.add(lettura);
      }
    }

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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8, // Imposta un'altezza specifica
                    child: ListView.builder(
                      itemCount: (letture_not_complete.length),
                      itemBuilder: (context, index) {
                        var libroTrovato = widget.dati.value[4].firstWhere(
                              (elemento) => elemento['id'] == letture_not_complete[index]['libro'],
                          orElse: () => null,
                        );
                        var pagine_rimaste = libroTrovato['numero_pagine'] - letture_not_complete[index]['numero_pagine_lette'];
                        var tempo_lettura_secondi = letture_not_complete[index]['tempo_di_lettura_secondi'];
                        var numero_ore_lettura = tempo_lettura_secondi ~/ 3600;
                        var numero_minuti_lettura = (tempo_lettura_secondi ~/ 60) - (numero_ore_lettura * 60);
                        return GestureDetector(
                          child: Card(
                            elevation: 5,
                            shape: const RoundedRectangleBorder(
                              side: BorderSide(
                                color: Colors.black, // Colore del bordo
                                width: 0.5, // Spessore del bordo
                              ),
                            ),
                            child: Row(
                              children: [
                                libroTrovato['copertina_url'].isNotEmpty
                                    ? Image.network(libroTrovato['copertina_url'])
                                    : const Center(child: Icon(Icons.image, size: 30)),
                                const SizedBox(width: 20),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: SemiCircleProgress(
                                            progress: (double.parse(letture_not_complete[index]['percentuale']) / 100)),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text("$pagine_rimaste page left", style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    Text("Booking time:"),
                                    Row(
                                      children: [
                                        Text("$numero_ore_lettura hours", style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(width: 5),
                                        Text("$numero_minuti_lettura minutes", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    SizedBox(width: 200, height: 20)
                                  ],
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            showLetturaDialog(libroTrovato);
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
      ),
    );
  }
}
