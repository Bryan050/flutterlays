import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import 'models/zona.dart';

class MapData {
  // ignore: unused_field
  late Future<List<Zona>> _zoneList;
  late Future<String> _zoneListString;
  late bool _hasConnection;
  final String apiString = "http://192.168.100.19:3000/api/albergue";
  MapData() {
    _zoneListString = readFileFromInternalStorage();
    _checkConnectivity();
  }

  Future<String> get zoneListString {
    return _zoneListString;
  }

  Future<void> _checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse(apiString));
      _hasConnection = response.statusCode == 200;

      if (_hasConnection) {
        // Hay conexión a Internet
        _performOnlineAction();
      } else {
        // No hay conexión a Internet
        _performOfflineAction();
      }
    } catch (e) {
      // Ocurrió un error al intentar realizar la solicitud
      _performOfflineAction();
    }
  }

  void _performOnlineAction() {
    Future<List<Zona>> _APIZones = _getZonesFromAPI();
    _generateAndSaveCSV(_APIZones);
    _zoneList = _APIZones;
    _zoneListString = readFileFromInternalStorage();
    print('Hay conexión a Internet');
  }

  void _performOfflineAction() {
    _zoneListString = readFileFromInternalStorage();
    print('No hay conexión a Internet');
  }

  Future<List<Zona>> _getZonesFromAPI() async {
    final response = await http.get(Uri.parse(apiString));
    List<Zona> zones = [];
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      final jsonData = jsonDecode(body);
      jsonData.asMap().forEach((index, item) {
        zones.add(Zona(
            id: index + 1,
            nombre: item["nombre"],
            tipo: item["tipo"],
            cx: double.parse(item["cx"].toString()),
            cy: double.parse(item["cy"].toString())));
      });
      return zones;
    } else {
      throw Exception("Error en la conexión");
    }
  }

  Future<void> _generateAndSaveCSV(Future<List<Zona>> Futuredata) async {
    List<Zona> data = await Futuredata;
    final csvData = data.map((zona) {
      return [
        zona.id,
        zona.nombre,
        zona.tipo,
        zona.cx.toString(),
        zona.cy.toString(),
      ].join(',');
    }).join('\n');
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/zoneData.csv'); // Ruta donde deseas guardar el archivo
    await file.writeAsString(csvData);
  }

  Future<String> readFileFromInternalStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/zoneData.csv');

      if (await file.exists()) {
        final content = await file.readAsString();
        return content;
      } else {
        print('El archivo no existe.');
        return '';
      }
    } catch (e) {
      print('Error al leer el archivo: $e');
      return '';
    }
  }
}
