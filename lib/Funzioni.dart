import 'package:intl/intl.dart';




class Utils {

 Map<String, dynamic> componi_Json_prima_lettura(Map libro) {
  print(libro["id"]);
  // Crea una nuova mappa per memorizzare i dati della lettura
  Map<String, dynamic> letturaData = {
   "data_inizio_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "data_fine_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "numero_pagine_lette": 0,
   "tempo_di_lettura_secondi": 0,
   "completato": false,
   "iniziato": true,
   "interrotto": false,
   "percentuale": 0,
   "libro": libro["id"],
  };

  return letturaData;
 }
}