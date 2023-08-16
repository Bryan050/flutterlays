import 'package:flutter/material.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class SecondPage extends StatefulWidget {
  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  String qrValue = "Codigo QR";

  void ScanQr() async {
    // Parse to code string with uint8list

    String cameraScanResult = await scanner.scanPhoto();
    setState(() {
      qrValue = cameraScanResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Scan',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'QR Scan',
          ),
        ),
        body: Center(
          child: Container(
            child: Text(
              qrValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () => ScanQr(),
          child: Icon(
            Icons.camera,
          ),
        ),
      ),
    );
  }
}
