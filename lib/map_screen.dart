import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}
class DraggableMarker extends StatelessWidget {
  final LatLng point;
  final Function(LatLng) onDragEnd;
  DraggableMarker({required this.point, required this.onDragEnd});

  @override
  Widget build(BuildContext context) {
    return Draggable(
      feedback: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.location_on),
        color: Colors.black,
        iconSize: 45,
      ),
      onDragEnd: (details) {
        onDragEnd(LatLng(details.offset.dy, details.offset.dx));
      },
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.location_on),
        color: Colors.black,
        iconSize: 45,
      ),
    );
  }
}

class _MapScreenState extends State<MapScreen> {
  LatLng? myPoint; // Tipo de dato LatLang
  // 2 parametros
  bool isLoading = false;
  bool showAdditionalButtons = false;
  TextEditingController searchController = TextEditingController();
  LatLng? searchLocation;
  final MapController mapController = MapController();
  Future<void> determineAndSetPosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied';
      }
    }
    final Position position = await Geolocator.getCurrentPosition();
    setState(() {
      myPoint = LatLng(position.latitude, position.longitude);
    });
    mapController.move(myPoint!, 10);
  }
  Future<Position> determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'error';
      }
    }
    return await Geolocator.getCurrentPosition();
  }


  Future<void> searchAndMoveToPlace(String query) async {
    List<Location> locations = await locationFromAddress(query);
    if (locations.isNotEmpty) {
      final LatLng newLocation =
      LatLng(locations[0].latitude, locations[0].longitude);
      setState(() {
        searchLocation = newLocation;
      });
      mapController.move(newLocation, 10);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('No se encontró ningún lugar con esta búsqueda.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }


  List listOfPoints = [];
  List<LatLng> points = [];
  List<Marker> markers = [];

  Future<void> getCoordinates(LatLng lat1, LatLng lat2) async {
    setState(() {
      isLoading = true;
    });

    final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf62481d15c38eda2742818d1b9ff0e510ca77',
    );

    final List<ORSCoordinate> routeCoordinates =
        await client.directionsRouteCoordsGet(
      startCoordinate:
          ORSCoordinate(latitude: lat1.latitude, longitude: lat1.longitude),
      endCoordinate:
          ORSCoordinate(latitude: lat2.latitude, longitude: lat2.longitude),
    );

    final List<LatLng> routePoints = routeCoordinates
        .map((coordinate) => LatLng(coordinate.latitude, coordinate.longitude))
        .toList();

    setState(() {
      points = routePoints;
      isLoading = false;
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(     appBar: AppBar(
      title: const Text(
        'Open Street Map',
        style: TextStyle(fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white10,
      centerTitle: true,
    ),
      body: Center(
        child: myPoint == null
            ? ElevatedButton(
          onPressed: () {
            determineAndSetPosition();
          },
          child: const Text('Activar localización'),
        )
            : contenidodelmapa(),
      ),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
           FloatingActionButton( // Botton de mostrar la buqueda
             backgroundColor: Colors.blue,
            onPressed: () {
              setState(() {
                showAdditionalButtons = !showAdditionalButtons;
              });
            },
            child: Icon(
                Icons.map,
                color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton( //Boton de zoom
            backgroundColor: Colors.black,
            onPressed: () {
              mapController.move(mapController.center, mapController.zoom + 1);
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton( // Boton de no hacer zoom
            backgroundColor: Colors.black,
            onPressed: () {
              mapController.move(mapController.center, mapController.zoom - 1);
            },
            child: const Icon(
              Icons.remove,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  // Funcion para trazar la ruta
  void _handleTap2(LatLng latLng) {
    setState(() {
      if (markers.length < 6) {
        markers.add(
          Marker(
            point: latLng,
            width: 80,
            height: 80,
            child: Builder(
              builder: (BuildContext context) {
                return DraggableMarker(
                  point: latLng,
                  onDragEnd: (newLatLng) {
                    setState(() {
                      int markerIndex =
                      markers.indexWhere((marker) => marker.point == latLng);
                      markers[markerIndex] = Marker(
                        point: newLatLng,
                        width: 80,
                        height: 80,
                        child: Builder(
                          builder: (BuildContext context) {
                            return DraggableMarker(
                              point: newLatLng,
                              onDragEnd: (details) {
                                setState(() {
                                  print(
                                      "Latitude: ${newLatLng.latitude}, Longitude: ${newLatLng.longitude}");
                                });
                              },
                            );
                          },
                        ),
                      );
                    });
                  },
                );
              },
            ),
          ),
        );
      }

      if (markers.length == 5) {
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            isLoading = true;
          });

          _getRouteForAllPoints(markers.map((marker) => marker.point).toList());
        });

        LatLngBounds bounds = LatLngBounds.fromPoints(
            markers.map((marker) => marker.point).toList());
        mapController.fitBounds(bounds);
      }
    });
  }


  Future<void> _getRouteForAllPoints(List<LatLng> points) async {
    List<LatLng> allRoutePoints = [];

    for (int i = 0; i < points.length - 1; i++) {
      List<LatLng> segmentPoints =
      await _getSegmentRoute(points[i], points[i + 1]);
      allRoutePoints.addAll(segmentPoints);
    }

    setState(() {
      this.points = allRoutePoints;
      isLoading = false;
    });
  }

  Future<List<LatLng>> _getSegmentRoute(LatLng start, LatLng end) async {
    final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf62481d15c38eda2742818d1b9ff0e510ca77',
    );

    final List<ORSCoordinate> routeCoordinates =
    await client.directionsRouteCoordsGet(
      startCoordinate:
      ORSCoordinate(latitude: start.latitude, longitude: start.longitude),
      endCoordinate:
      ORSCoordinate(latitude: end.latitude, longitude: end.longitude),
    );

    return routeCoordinates
        .map((coordinate) => LatLng(coordinate.latitude, coordinate.longitude))
        .toList();
  }




  Widget _handleTap(LatLng latLng) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Posicion : ' + latLng.toString()),
          actions: <Widget>[
            TextButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
      return Container(); // Retorna un widget vacío ya que el showDialog no espera un retorno
    }


  Widget contenidodelmapa()
  {
    return Stack(
    children: [
      FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialZoom: 16,
          maxZoom: 20,
          minZoom: 1,
          initialCenter: myPoint!,
          onTap: (tapPosition, latLng) => _handleTap2(latLng),
          interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.doubleTapDragZoom),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: myPoint!,
                width: 60,
                height: 60,
                alignment: Alignment.centerLeft,
                child: const Icon(
                  Icons.person_pin_circle_sharp,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: Colors.black,
                strokeWidth: 5,
              ),
            ],
          ),
        ],
      ),
      Visibility(
        visible: isLoading,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + 20.0,
        left: MediaQuery.of(context).size.width / 2 - 110,
        child: Align(
          child: TextButton(
            onPressed: () {
              if (markers.isEmpty) {
                // Se os marcadores estiverem vazios
                print('Marcar puntos en el mapa');
              } else {
                setState(() {
                  markers = [];
                  points = [];
                });
              }
            },
            child: Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                child: Text(
                  markers.isEmpty ? "Marcar ruta del mapa" : "Limpar ruta",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
      if (showAdditionalButtons)
        Positioned(
          bottom: 220,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Buscar ubicación'),
                        content: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Ingrese la ubicación',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              searchAndMoveToPlace(searchController.text);
                              Navigator.of(context).pop();
                            },
                            child: Text('Buscar'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Icon(Icons.search),
              ),
              SizedBox(height: 16),
              FloatingActionButton(
                onPressed: () {
                  determineAndSetPosition();
                },
                child: Icon(Icons.location_pin),
              ),
            ],
          ),
        ),
    ],
    );
  }
}
