import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lays/models/zona.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Zona>> _zoneList;
  late Future<String> _zoneListString;
  late bool _hasConnection;
  final String apiString = "http://192.168.100.19:3000/api/albergue";
  Future<void> _checkConnectivity() async {
    try {
      final response = await http.get(Uri.parse(apiString));
      setState(() {
        _hasConnection = response.statusCode == 200;
      });

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

  Widget csvContainer() {
    return FutureBuilder<String>(
      future: _zoneListString,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final csvLines = snapshot.data!.split('\n');
          return ListView.builder(
            itemCount: csvLines.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(csvLines[index]),
              );
            },
          );
        } else if (snapshot.hasError) {
          return const Text('Error al leer el archivo.');
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget nameList() {
    return FutureBuilder(
      future: _zoneList,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView(
            children: _listZone(snapshot.data),
          );
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return const Text("Error");
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _zoneListString = readFileFromInternalStorage();
    _checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Material App Bar'),
          ),
          body: csvContainer()),
    );
  }

  List<Widget> _listZone(List<Zona>? data) {
    List<Widget> zones = [];
    for (var zona in data!) {
      zones.add(Text(zona.nombre));
    }
    return zones;
  }
}
