import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lays/markerdemo-contextmenubuilder.dart';
import 'package:lays/markerdemo-datastore.dart';
//import 'package:lays/rotation-overlay.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';

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
  MapViewPageState2 createState() => MapViewPageState2();
}

/////////////////////////////////////////////////////////////////////////////

/// The [State] of the [MapViewPage] Widget.
class MapViewPageState2 extends State<MapViewPage2> {
  final DisplayModel displayModel = DisplayModel(deviceScaleFactor: 1);

  late SymbolCache symbolCache;

  late MarkerdemoDatastore markerdemoDatastore;

  @override
  void initState() {
    super.initState();

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
    return MapviewWidget(
        displayModel: displayModel,
        createMapModel: () async {
          /// instantiate the job renderer. This renderer is the core of the system and retrieves or renders the tile-bitmaps
          return widget.mapFileData.mapType == MAPTYPE.OFFLINE
              ? await _createOfflineMapModel()
              : await _createOnlineMapModel();
        },
        createViewModel: () async {
          return _createViewModel();
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
    viewModel.setMapViewPosition(widget.mapFileData.initialPositionLat,
        widget.mapFileData.initialPositionLong);
    viewModel.setZoomLevel(widget.mapFileData.initialZoomLevel);
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
      markerdemoDatastore.moveMarkerUpdate(event);
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

    markerdemoDatastore.addMarker(CircleMarker(
      center: LatLong(widget.mapFileData.initialPositionLat,
          widget.mapFileData.initialPositionLong),
      radius: 15,
      strokeWidth: 2,
      fillColor: 0xff0000ff,
      strokeColor: 0xff000000,
      displayModel: displayModel,
    ));
    mapModel.markerDataStores.add(markerdemoDatastore);
    return mapModel;
  }

  void loadCoordinates(MapModel mapModel) {
    var albergues = {
      LatLong(-0.995454, -78.584748),
      LatLong(-0.995399, -78.586121),
      LatLong(-0.989938, -78.587724),
      LatLong(-1.009205, -78.583218),
      LatLong(-1.003849, -78.595021),
    };

    var sitiosSeguros = {
      LatLong(-1.004669, -78.576031),
      LatLong(-0.988080, -78.562158),
      LatLong(-0.983243, -78.566101),
      LatLong(-0.976931, -78.583141),
      LatLong(-1.003781, -78.558963)
    };
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
