import 'package:intl/intl.dart';

class Utils {
 Map<String, dynamic> componi_Json_prima_lettura(Map libro, bool completato, double pagine_al_minuto_lette) {


  print(libro["id"]);
  Map<String, dynamic> letturaData = {
   "data_inizio_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "data_fine_lettura": DateFormat('yyyy-MM-dd').format(DateTime.now()),
   "numero_pagine_lette": completato? libro["numero_pagine"] : 0,
   "tempo_di_lettura_secondi": completato ? ( (libro["numero_pagine"] / pagine_al_minuto_lette) * 60 ).toInt() : 0,
   "completato": completato? true : false,
   "iniziato": completato? false: true,
   "interrotto": false,
   "percentuale": completato? 100 : 0,
   "libro": libro["id"],
  };

  return letturaData;
 }
}