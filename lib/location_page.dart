import 'package:flutter/material.dart';
import 'package:lays/location_service.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as goa;
import 'package:location/location.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LocationProvider(),
          child: LocationHome(),
        )
      ],
      child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: LocationHome()),
    );
  }
}

class LocationHome extends StatefulWidget {
  const LocationHome({Key? key}) : super(key: key);

  @override
  State<LocationHome> createState() => LocationHomeState();
}

class LocationHomeState extends State<LocationHome> {
  @override
  void initState() {
    super.initState();
    Provider.of<LocationProvider>(context, listen: false).initalization();
  }

  Widget googleMapUI() {
    return Consumer<LocationProvider>(builder: (
      consumerContext,
      model,
      child,
    ) {
      if (model.locationPosition != null) {
        return Column(
          children: [
            Text(model.locationPosition.longitude.toString()),
            Text(model.locationPosition.latitude.toString())
          ],
        );
      }
      return Center(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: googleMapUI(),
    );
  }
}
