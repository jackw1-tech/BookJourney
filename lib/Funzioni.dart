import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:book_journey/api.dart';
import '../Funzioni.dart';





class Utils {

 Map<String, dynamic> componi_Json_prima_lettura(Map libro, bool completato) {
  print(libro["id"]);
  // Crea una nuova mappa per memorizzare i dati della lettura
  Map<String, dynamic> letturaData = {
   "data_inizio_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "data_fine_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "numero_pagine_lette": completato? libro["numero_pagine"] : 0,
   "tempo_di_lettura_secondi": 0,
   "completato": completato? true : false,
   "iniziato": completato? false: true,
   "interrotto": false,
   "percentuale": completato? 100 : 0,
   "libro": libro["id"],
  };

  return letturaData;
 }
}