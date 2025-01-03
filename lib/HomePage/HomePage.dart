import 'package:book_journey/LettureInCorso/LettureInCorso.dart';
import 'package:flutter/material.dart';
import 'package:book_journey/CercaLibri/cerca.dart';
import 'package:book_journey/Profilo/Profilo.dart';

class HomePage extends StatefulWidget {
  final String authToken;
  ValueNotifier<List<List<dynamic>>> dati = ValueNotifier<List<List<dynamic>>>([]);
  HomePage({super.key, required this.authToken, required this.dati});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: widget.dati, builder: (context, value, child)
    {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          body: TabBarView(
            children: [
             Lettureincorso(authToken: widget.authToken, dati: widget.dati),
              Cerca_Libri(authToken: widget.authToken, dati: widget.dati),
              Profilo(authToken: widget.authToken, dati: widget.dati)
            ],
          ),
          bottomNavigationBar: const BottomAppBar(
            height: 60,
            padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
            color: Colors.white,
            child: TabBar(
              indicatorColor: Color(0xFF06402B),
              labelColor: Color(0xFF06402B),
              unselectedLabelColor: Colors.black,
              indicatorWeight: 5,
              tabs: [
                Tab(icon: Icon(Icons.book_outlined)),
                Tab(icon: Icon(Icons.search)),
                Tab(icon: Icon(Icons.person)),
              ],
            ),
          ),
        ),
      )
    ;
    });
  }
}
