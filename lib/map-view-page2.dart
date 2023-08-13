import 'dart:async';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lays/markerdemo-contextmenubuilder.dart';
import 'package:lays/markerdemo-datastore.dart';
import 'package:location/location.dart';
//import 'package:lays/rotation-overlay.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';
import 'map-file-data.dart';

/// The [StatefulWidget] displaying the interactive map page. This is a demo
/// implementation for using mapsforge's [MapviewWidget].
///
class MapViewPage2 extends StatefulWidget {
  final MapFileData mapFileData;

  final MapDataStore? mapFile;

  const MapViewPage2(
      {Key? key, required this.mapFileData, required this.mapFile})
      : super(key: key);

  @override
  MapViewPageState createState() => MapViewPageState(
        mapFileData: mapFileData,
        mapFile: mapFile,
      );
}

/////////////////////////////////////////////////////////////////////////////

class MapViewPageState extends State<MapViewPage2> {
  final MapFileData mapFileData;

  final MapDataStore? mapFile;

  MapViewPageState(
      {Key? key, required this.mapFileData, required this.mapFile});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LocationProvider(),
          child: MapViewPageHome(mapFileData: mapFileData, mapFile: mapFile),
        )
      ],
      child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MapViewPageHome(mapFileData: mapFileData, mapFile: mapFile)),
    );
  }
}

class MapViewPageHome extends StatefulWidget {
  final MapFileData mapFileData;

  final MapDataStore? mapFile;

  const MapViewPageHome(
      {Key? key, required this.mapFileData, required this.mapFile})
      : super(key: key);

  @override
  MapViewPageState2 createState() => MapViewPageState2();
}

/// The [State] of the [MapViewPage] Widget.
class MapViewPageState2 extends State<MapViewPageHome> {
  final DisplayModel displayModel = DisplayModel(deviceScaleFactor: 1);

  late SymbolCache symbolCache;

  late MarkerdemoDatastore markerdemoDatastore;
  late LatLong currentLocation;
  LatLong? nearestPoint;
  late CircleMarker userMarker;
  late double distanceToNearesPoint;

  @override
  void initState() {
    super.initState();
    Provider.of<LocationProvider>(context, listen: false).initalization();
    userMarker = CircleMarker(
      center: LatLong(widget.mapFileData.initialPositionLat,
          widget.mapFileData.initialPositionLong),
      radius: 15,
      strokeWidth: 2,
      fillColor: 0xff0000ff,
      strokeColor: 0xff000000,
      displayModel: displayModel,
    );
    distanceToNearesPoint = -1;

    /// For the offline-maps we need a cache for all the tiny symbols in the map
    symbolCache = widget.mapFileData.relativePathPrefix != null
        ? FileSymbolCache(
            imageLoader: ImageRelativeLoader(
                relativePathPrefix: widget.mapFileData.relativePathPrefix!))
        : FileSymbolCache();
    markerdemoDatastore = MarkerdemoDatastore(
        symbolCache: symbolCache, displayModel: displayModel);
  }

  @override
  void dispose() {
    super.dispose();
    //markerdemoDatastore.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHead(context) as PreferredSizeWidget,
      body: _buildMapViewBody(context),
    );
  }

  /// Constructs the [AppBar] of the [MapViewPage] page.
  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: Text(widget.mapFileData.displayedName),
    );
  }

  /// Constructs the body ([FlutterMapView]) of the [MapViewPage].
  Widget _buildMapViewBody(BuildContext context) {
    return Consumer<LocationProvider>(builder: (
      consumerContext,
      model,
      child,
    ) {
      if (model.locationPosition != null) {
        //print("USER CURRENT LOCATION " + model.locationPosition.toString());
        currentLocation = model.locationPosition;
        userMarker.latLong = currentLocation;
        if (distanceToNearesPoint != -1) {
          var currentDistance = getDistance(nearestPoint!, currentLocation);
          print(distanceToNearesPoint);
          print(currentDistance);

          if (distanceToNearesPoint > currentDistance) {
            userMarker.setMarkerCaption(MarkerCaption(
                text: "Te estas acercando a tu destino",
                displayModel: displayModel));
          } else {
            userMarker.setMarkerCaption(MarkerCaption(
                text: "Te estas alejando a tu destino",
                displayModel: displayModel));
          }
        }
        return MapviewWidget(
            displayModel: displayModel,
            createMapModel: () async {
              /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
              return widget.mapFileData.mapType == MAPTYPE.OFFLINE
                  ? await _createOfflineMapModel()
                  : await _createOnlineMapModel();
            },
            createViewModel: () async {
              //print("CREATE VIEW MODEL");
              return _createViewModel();
            });
      }
      return Center(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    });
  }

  ViewModel _createViewModel() {
    // in this demo we use the markers only for offline databases.
    ViewModel viewModel = ViewModel(
      displayModel: displayModel,
      contextMenuBuilder: //DebugContextMenuBuilder(datastore: widget.mapFile!),
          widget.mapFileData.mapType == MAPTYPE.OFFLINE
              ? MarkerdemoContextMenuBuilder()
              : const DefaultContextMenuBuilder(),
    );
    if (widget.mapFileData.indoorZoomOverlay)
      viewModel.addOverlay(IndoorlevelZoomOverlay(viewModel,
          indoorLevels: widget.mapFileData.indoorLevels));
    else
      viewModel.addOverlay(ZoomOverlay(viewModel));
    viewModel.addOverlay(DistanceOverlay(viewModel));
    //viewModel.addOverlay(DemoOverlay(viewModel: viewModel));
    // set default position
    if (currentLocation != null) {
      viewModel.setMapViewPosition(
          currentLocation.latitude, currentLocation.longitude);
      viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
    }
    viewModel.observeMoveAroundStart.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerStart(event);
    });
    viewModel.observeMoveAroundCancel.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerCancel(event);
    });
    viewModel.observeMoveAroundUpdate.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore
          .moveMarkerUpdate(LatLong(event.latitude, event.longitude));
    });
    viewModel.observeMoveAroundEnd.listen((event) {
      // Demo: If the user tries to move around a marker
      markerdemoDatastore.moveMarkerEnd(event);
    });
    // used to demo the rotation-feature
    //viewModel.addOverlay(RotationOverlay(viewModel));
    return viewModel;
  }

  Future<MapModel> _createOfflineMapModel() async {
    /// Prepare the Themebuilder. This instructs the renderer how to draw the images
    RenderTheme renderTheme =
        await RenderThemeBuilder.create(displayModel, widget.mapFileData.theme);

    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    final JobRenderer jobRenderer = MapDataStoreRenderer(
        widget.mapFile!, renderTheme, symbolCache, false,
        useIsolate: false);

    /// and now it is similar to online rendering.

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    /*if (kIsWeb) {
      bitmapCache = await WebTileBitmapCache.create(jobRenderer.getRenderKey());
    } else {
      bitmapCache =
          await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    }*/

    bitmapCache = await FileTileBitmapCache.create(jobRenderer.getRenderKey());

    /// Now we can glue together and instantiate the mapModel and the viewModel. The former holds the
    /// properties for the map and the latter holds the properties for viewing the map
    MapModel mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
      symbolCache: symbolCache,
    );
//0xffff0000 red
//0xff008f39 green
//0xff0000ff blue

    // mapModel.markerDataStores.add(
    //     DebugDatastore(symbolCache: symbolCache, displayModel: displayModel));
    loadCoordinates(mapModel);

    userMarker.latLong = currentLocation;
    if (currentLocation != null) {
      nearestPoint = await getNearedPoint();
      MarkerDataStore markerDataStore = MarkerDataStore();
      markerDataStore.addMarker(CircleMarker(
          center: nearestPoint!,
          radius: 10,
          strokeWidth: 2,
          fillColor: 0xff000000,
          strokeColor: 0xff000000,
          displayModel: displayModel));
      mapModel.markerDataStores.add(markerDataStore);
    }
    distanceToNearesPoint = getDistance(nearestPoint!, currentLocation);
    //print("INITIAL DISTANCE: " + distanceToNearesPoint.toString());
    userMarker.setMarkerCaption(MarkerCaption(
        text: "Distancia total: " + distanceToNearesPoint.toString(),
        displayModel: displayModel));

    markerdemoDatastore.addMarker(userMarker);
    mapModel.markerDataStores.add(markerdemoDatastore);

    return mapModel;
  }

  //Calculating the distance between two points with Geolocator plugin
  getDistance(LatLong point1, LatLong point2) {
    final double distance = Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
    return distance;
  }

  getNearedPoint() async {
    var alberguesDistance = [];
    var sitiosSegurosDistance = [];
    var distanceToDestination;
    var minIndexAlberguesDistance;
    var minIndexSitioSeguroDistance;
    var minAlbergueLatLong;
    var minSitioSeguroLatLong;

    List<List<LatLong>> data = await _loadCSV();
    var albergues = data[0];

    var sitiosSeguros = data[1];
    for (var coordinate in albergues) {
      alberguesDistance.add(getDistance(currentLocation, coordinate));
    }

    for (var coordinate in sitiosSeguros) {
      sitiosSegurosDistance.add(getDistance(currentLocation, coordinate));
    }

    var minAlberguesDistance = alberguesDistance
        .reduce((value, element) => value < element ? value : element);
    var minSitiosSegurosDistance = sitiosSegurosDistance
        .reduce((value, element) => value < element ? value : element);

    if (minAlberguesDistance < minSitiosSegurosDistance) {
      distanceToDestination = minAlberguesDistance;
      minIndexAlberguesDistance =
          alberguesDistance.indexOf(distanceToDestination);
      minAlbergueLatLong = albergues.elementAt(minIndexAlberguesDistance);
      distanceToNearesPoint = distanceToDestination;
      return minAlbergueLatLong;
    }
    distanceToDestination = minSitiosSegurosDistance;
    minIndexSitioSeguroDistance =
        sitiosSegurosDistance.indexOf(distanceToDestination);
    minSitioSeguroLatLong =
        sitiosSeguros.elementAt(minIndexSitioSeguroDistance);
    distanceToNearesPoint = distanceToDestination;
    return minSitioSeguroLatLong;
  }

  Future<void> loadCoordinates(MapModel mapModel) async {
    List<List<LatLong>> data = await _loadCSV();
    var albergues = data[0];
    var sitiosSeguros = data[1];

    for (var coordinate in albergues) {
      MarkerDataStore markerDataStore = MarkerDataStore();
      markerDataStore.addMarker(CircleMarker(
        center: coordinate,
        radius: 15,
        strokeWidth: 2,
        fillColor: 0xffff0000,
        strokeColor: 0xff000000,
        displayModel: displayModel,
      ));
      mapModel.markerDataStores.add(markerDataStore);
    }

    for (var coordinate in sitiosSeguros) {
      MarkerDataStore markerDataStore = MarkerDataStore();
      markerDataStore.addMarker(CircleMarker(
        center: coordinate,
        radius: 15,
        strokeWidth: 2,
        fillColor: 0xff008f39,
        strokeColor: 0xff000000,
        displayModel: displayModel,
      ));
      mapModel.markerDataStores.add(markerDataStore);
    }
  }

  Future<List<List<LatLong>>> _loadCSV() async {
    final _rawData = await rootBundle.loadString("assets/mycsv.csv");
    List<List<dynamic>> _listData =
        const CsvToListConverter().convert(_rawData);
    var _type = null;

    List<List<LatLong>> _data = [];
    List<LatLong> _albergues = [];
    List<LatLong> _sitioSeguro = [];
    var flag = 0;
    for (var val in _listData) {
      if (flag != 0) {
        _type = val[2];
        if (_type == "SS") {
          _sitioSeguro.add(LatLong(val[3], val[4]));
        } else if (_type == "A") {
          _albergues.add(LatLong(val[3], val[4]));
        }
      }
      flag = 1;
    }
    _data.add(_albergues);
    _data.add(_sitioSeguro);
    return _data;
  }

  Future<MapModel> _createOnlineMapModel() async {
    /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
    JobRenderer jobRenderer = widget.mapFileData.mapType == MAPTYPE.OSM
        ? MapOnlineRendererWeb()
        : ArcGisOnlineRenderer();

    /// provide the cache for the tile-bitmaps. In Web-mode we use an in-memory-cache
    final TileBitmapCache bitmapCache;
    if (kIsWeb) {
      bitmapCache = MemoryTileBitmapCache.create();
    } else {
      bitmapCache =
          await FileTileBitmapCache.create(jobRenderer.getRenderKey());
    }

    /// Now we can glue together and instantiate the mapModel and the viewModel. The former holds the
    /// properties for the map and the latter holds the properties for viewing the map
    MapModel mapModel = MapModel(
      displayModel: displayModel,
      renderer: jobRenderer,
      tileBitmapCache: bitmapCache,
    );
    return mapModel;
  }
}
