import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wild_radar/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:math' as math;

// Beginpagina van de app - Stateless widget die de basis thema's instelt
class MappingPage extends StatelessWidget {
  const MappingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Configureert de app met Material Design 3 thema
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const NavigationExample(),
    );
  }
}

// New class
  // New class to represent an area of interest
  class AreaOfInterest {
    LatLng location;
    double radius;
    String id;

    AreaOfInterest({
      required this.location, 
      this.radius = 1.0,
      String? id
    }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
  }


// Hoofd navigatie voorbeeld - Stateful widget voor dynamische pagina-interactie
class NavigationExample extends StatefulWidget {

  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {


double _defaultzoom = 7.5;


final MapController _mapController = MapController();


  //bereken de intesiteit van de cirkel
double _calculateScaledRadius(double radiusKm, BuildContext context) {
  // Get the current zoom level of the map

  double currentzoom = _mapController.camera.zoom; // You might need to extract this from your MapController
  print(currentzoom);
  // Scaling factor - adjust these values to fine-tune the scaling
  final zoomFactor = (currentzoom - _defaultzoom) / 2;
  double scaleFactor = 1000 * math.pow(2, zoomFactor).toDouble();
  return radiusKm * scaleFactor;
}

  List<AreaOfInterest> _areasOfInterest = [];


  // Bool om van map te kunnen switchen
  bool _isSatelliteView = false;

  // API service voor gegevensinvoer
  final ApiService _apiService = ApiService();
  List<dynamic>? _data; // Variabele om opgehaalde data op te slaan
  bool _isLoading = true; // Geeft aan of gegevens nog worden geladen

  // Bijhouden van de huidige pagina-index voor navigatie
  int currentPageIndex = 0;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _fetchData(); // Haalt data op zodra de widget wordt geïnitialiseerd
  }

  // Asynchrone functie om data op te halen van de API
  Future<void> _fetchData() async {
    final data = await _apiService.fetchAnimalLocations();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  void _filterAnimals(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = [];
      } else {
        _filteredData = _data?.where((item) {
          final commonName = item['species']['commonName']?.toString().toLowerCase() ?? '';
          final name = item['name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return commonName.contains(searchLower) || name.contains(searchLower);
        }).toList() ?? [];
      }
    });
  }

  void _showMarkerDetails(dynamic item) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog (
        title: Text('locatie details'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Naam: ${item['name'] ?? 'Onbekend'}'),
              Text('Soort: ${item['species']['name'] ?? 'Onbekend'}'),
              Text('Gemeenschappelijke naam: ${item['species']['commonName'] ?? 'Onbekend'}'),
              Text('Locatie:'),
              Text('Latitude: ${item['location']['latitude'] ?? 'Niet beschikbaar'}'),
              Text('Longitude: ${item['location']['longitude'] ?? 'Niet beschikbaar'}'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Sluiten'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}


  // Method to handle map taps
void _onMapTapped(TapPosition tapPosition, LatLng point) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      double initialRadius = 1.0;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Plaats een marker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Wilt u een marker plaatsen op deze locatie?'),
                Slider(
                  value: initialRadius,
                  min: 0.1,
                  max: 10.0,
                  divisions: 100,
                  label: '${initialRadius.toStringAsFixed(1)} km',
                  onChanged: (double value) {
                    setState(() {
                      initialRadius = value;
                    });
                  },
                ),
                Text('Straal: ${initialRadius.toStringAsFixed(1)} km'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Annuleren'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Toevoegen'),
                 onPressed: () {
                  // Ensure the main widget state is updated
                  this.setState(() {
                    _areasOfInterest.add(AreaOfInterest(
                      location: point, 
                      radius: initialRadius * 1000
                    ));
                    print('initiele radius: ${initialRadius}');
                  });
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
      );
    }
  );
}

void _adjustAreaRadius(AreaOfInterest area) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      double currentRadius = area.radius / 1000;
      return AlertDialog(
        title: Text('Pas Straal Aan'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: currentRadius,
                  min: 0.1,
                  max: 10.0,
                  divisions: 100,
                  label: '${currentRadius.toStringAsFixed(1)} km',
                  onChanged: (double value) {
                    setState(() {
                      currentRadius = value;
                    });
                  },
                ),
                Text('Nieuwe straal: ${currentRadius.toStringAsFixed(1)} km'),
              ],
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Verwijderen'),
            onPressed: () {
              setState(() {
                _areasOfInterest.removeWhere((a) => a.id == area.id);
              });
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Bevestigen'),
            onPressed: () {
              setState(() {
                area.radius = currentRadius * 1000;
                print('current radius:${currentRadius}');
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
      title: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.fromLTRB(0, 30, 50, 30.0),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.black,
                  width: 3.0,
                ),
              ),
            ),
            child: Image.asset(
            'lib/assets/images/wildradarlogo.png',
            width: 200,
            ),
          ),
          Expanded(
            child: NavigationBar( 
              backgroundColor: Color.fromRGBO(254, 247, 255, 100),
              onDestinationSelected: (int index) {
                setState(() {
                  currentPageIndex = index;
                });
              },
              indicatorColor: Colors.green,
              selectedIndex: currentPageIndex,
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Kaart',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_sharp), 
                  label: 'Meldingen'
                ),
                NavigationDestination(
                  icon: Badge(
                    label: Text('1'),
                    child: Icon(Icons.favorite),
                  ),
                  label: 'Favorieten',
                ),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Instellingen'),
                NavigationDestination(icon: Icon(Icons.info_outline), label: 'Over'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Profiel'),
              ],
            ),
          ),
        ],
      ),
    ),

      body: <Widget>[
        // Kaartpagina met Flutter Map en API
        _isLoading 
          ? Center(child: CircularProgressIndicator()) 
          : _buildMapWithMarkers(),

        // Meldingenpagina met voorbeeldmeldingen
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Melding 1'),
                  subtitle: Text('Dit is een melding'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Melding 2'),
                  subtitle: Text('Dit is nog een melding'),
                ),
              ),
            ],
          ),
        ),

        Center(child: Text('Favorieten pagina')),
        Center(child: Text('Instellingen Pagina')),
        Center(child: Text('Over pagina')),
        Center(child: Text('Profiel pagina')),
      ][currentPageIndex],
    );
  }




// Nieuwe functie om een kaart te maken met markers
  Widget _buildMapWithMarkers() {

    // Use _filteredData if it's not empty, otherwise use the original _data
    var displayData = _filteredData.isNotEmpty ? _filteredData : _data;

    if (displayData == null || displayData.isEmpty) {
      return Center(child: Text('Geen dierlocaties beschikbaar'));
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(52.370216, 4.895168),
          initialZoom: 7.5,
          minZoom: 7.5,
          maxZoom: 18.0,
          cameraConstraint: CameraConstraint.containCenter(
            bounds: LatLngBounds(
            LatLng(50.5, 3.5), 
            LatLng(53.8, 7.2),
            ),
        ),
        onPositionChanged: (position, bool hasGesture) {
          // Recalculate radius when the zoom level changes
          if (hasGesture) {
            // _updateRadius(position.zoom);
            print('zoom = ${position.zoom}');
          }
        },
        onTap: _onMapTapped,
      ),
      children: [
        TileLayer(
          urlTemplate: _isSatelliteView 
          ? "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}" 
          : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          tileProvider: CancellableNetworkTileProvider(),
          userAgentPackageName: 'com.example.app',
        ),

          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 120,
              size: Size(50, 50),
              markers: [ 
              ...displayData.map((item) {
                double lat = item['location']['latitude'] ?? 52.370216;
                double lon = item['location']['longitude'] ?? 4.895168;

                return Marker(
                  point: LatLng(lat, lon),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      _showMarkerDetails(item);
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.pets,
                          color: Colors.green,
                          size: 30,
                        ),
                        FittedBox(
                          child: Text(
                            item['species']['commonName'] ?? 'onbekend',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              //Area of interest cluster
              ..._areasOfInterest.map((area) =>
                Marker(
                  point: area.location,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _adjustAreaRadius(area),
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                )
              ).toList(),
              ],
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          CircleLayer(
            circles: _areasOfInterest.map((area) {
              return CircleMarker(
                point: area.location,
                // point: LatLng(52.2677, 5.1689),
                //radius: _calculateScaledRadius(area.radius, context), // convert km to meters
                useRadiusInMeter: true,
                radius: area.radius,
                color: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blue,
                borderStrokeWidth: 2,
              );
            }).toList(),
          ),
          
          MarkerLayer(
              markers: _areasOfInterest.map((area) =>
                Marker(
                  point: area.location,
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _adjustAreaRadius(area),
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                )
              ).toList(),
            ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
              ),
              TextSourceAttribution(
                'Sources: Esri, DigitalGlobe, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community',
                onTap: () => launchUrl(Uri.parse('https://www.esri.com/')),
              )
            ],
          ),
        ],
      ),
            // Overlay Cards at the bottom
      Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Card 1: Animals
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.10 * 0.9,
              child: Card(
                elevation: 4,
                color: _isSatelliteView ? Colors.green.shade100 : null, // Optional visual indication
                child: InkWell( // Use InkWell for tap effects
                  onTap: () {
                    setState(() {
                      _isSatelliteView = !_isSatelliteView;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSatelliteView ? Icons.satellite : Icons.map, 
                          color: Colors.green, 
                          size: 20
                        ),
                        Text(
                          _isSatelliteView ? 'Satelliet' : 'Kaart', 
                          style: TextStyle(fontSize: 16)
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

              // Card 2: Locations
              if(_areasOfInterest.isNotEmpty)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.10 * 0.9,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: Colors.blue, size: 20),
                        Text('Gebieden van interesse: ${_areasOfInterest.length}'),
                        // Text('${_data?.length ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _areasOfInterest.clear();
                            });
                          },
                          child: Text('Wis alle gebieden'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Card 3: Last Update
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.10 * 0.9,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pets, color: Colors.orange, size: 20),
                        Text('Zie alle dieren', style: TextStyle(fontSize: 16)),
                        // Text(DateTime.now().toString().substring(0, 16), style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),

              // Card 4: Details
              
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.10 * 0.9,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pets, color: Colors.purple, size: 20),
                            SizedBox(width: 8),
                            Text('Zoek dieren', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Zoek op soort of naam',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          ),
                          onChanged: (value) {
                            _filterAnimals(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
          Positioned(
      top: 20, // Adjust positioning as needed
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<double>(
            stream: _mapController.mapEventStream
                .map((event) => event.camera.zoom),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Text('Loading...');
              
              double zoom = snapshot.data!;
              
              // Calculate approximate meters per pixel at this zoom level
              double metersPerPixel = 156543.03392 * math.cos(52.370216 * math.pi / 180) / math.pow(2, zoom);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zoom Level: ${zoom.toStringAsFixed(2)}'),
                  Text('Meters per Pixel: ${metersPerPixel.toStringAsFixed(2)}'),
                ],
              );
            },
          ),
        ),
      ),
    ),
    ],
  );
} // end of widget


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

// End of code
}