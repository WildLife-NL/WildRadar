import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wild_radar/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:wildlife_api_connection/models/location.dart';
import 'package:intl/intl.dart';

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

// CLASS TO SHOWCASE ANIMALS LOCATION (WILL BE CHANGED AFTER TUESDAY 17 DECEMBER)
class TrackedAnimal {
  final String name;
  final String species;
  final String commonName;
  final List<LatLng> locations;

  TrackedAnimal({
    required this.name,
    required this.species,
    required this.commonName,
    required this.locations,
  });
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


// TRACKED ANIMAL TO SHOWCASE ANIMALS LOCATION (WILL BE CHANGED AFTER TUESDAY 17 DECEMBER)
TrackedAnimal? _trackedAnimal;
int _currentlocationIndex = 0;
bool _isTrackedAnimalVisible = false;

final MapController _mapController = MapController();


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

    _trackedAnimal = TrackedAnimal(
      name: 'Edelhert (Test)', 
      species: 'Cervus elaphus', 
      commonName: 'Edelhert', 
      locations: [
        // Random places
        LatLng(52.402285, 4.567020),   
        LatLng(52.408434, 4.578950),       
        LatLng(52.401952, 4.585567),      
        ],
      );
  }

  // Asynchrone functie om data op te halen van de API
  Future<void> _fetchData() async {
    final data = await _apiService.fetchAnimalLocations();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

// Move to the location of the animal
void _moveMapToLocation(dynamic item) {
  double lat = item['location']['latitude'] ?? '51.30832';
  double lon = item['location']['longitude'] ?? '5.65502';

  // Move the map to that location
  _mapController.move(LatLng(lat, lon), 16.0);

  setState(() {
    currentPageIndex = 1;
  });

  _showMarkerDetails(item);
}

// Add a new method to show animal details
void _showTrackedAnimalDetails() {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, dialogSetState) {
          return Container(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Dier Tracking Details', 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  )
                ),
                SizedBox(height: 10),
                Text('Naam: ${_trackedAnimal!.name}'),
                Text('Soort: ${_trackedAnimal!.species}'),
                Text('Gemeenschappelijke naam: ${_trackedAnimal!.commonName}'),
                SizedBox(height: 10),
                Slider(
                  value: _currentlocationIndex.toDouble(),
                  min: 0,
                  max: (_trackedAnimal!.locations.length - 1).toDouble(),
                  divisions: _trackedAnimal!.locations.length - 1,
                  label: 'Locatie: ${_currentlocationIndex + 1}',
                  onChanged: (double value) {
                    // Use the main widget's setState
                    setState(() {
                      _currentlocationIndex = value.toInt();
                      // Center map to location
                      _mapController.move(
                        _trackedAnimal!.locations[_currentlocationIndex],
                        15.0
                      );
                    });
                    // Update the dialog's local state to refresh the label
                    dialogSetState(() {});
                  },
                ),
                Text(
                  'Huidige locatie: '
                  '${_trackedAnimal!.locations[_currentlocationIndex].latitude.toStringAsFixed(4)},'
                  '${_trackedAnimal!.locations[_currentlocationIndex].longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    },
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
  );
}


void _filterAnimals(String query) {
  setState(() {
    _filteredData = query.isEmpty 
      ? [] 
      : (_data ?? []).where((item) {
          final commonName = item['species']['commonName']?.toString().toLowerCase() ?? '';
          final name = item['name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return commonName.contains(searchLower) || name.contains(searchLower);
        }).toList();
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
              Text('Laatste update: ${item['locationTimestamp'] != null 
              ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(item['locationTimestamp']))
              : 'Niet beschikbaar'}'
              ),
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
      // De intiële radius = 1.0 wat 1 kilometer betekend
      double initialRadius = 1.0;
      return StatefulBuilder(
        builder: (context, setState) {
          // Hierbij volgt een dialoog box waarbij er opties worden getoond
          return AlertDialog(
            title: Text('Plaats een marker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Wilt u een marker plaatsen op deze locatie?'),
                // De slider geeft de kans om zelf een waarde te kunnen invullen
                Slider(
                  value: initialRadius,
                  min: 0.1,
                  max: 10.0,
                  divisions: 100,
                  label: '${initialRadius.toStringAsFixed(1)} km',
                  onChanged: (double value) {
                    setState(() {
                      // veranderd de radius naar de waarde die de gebruiker heeft ingevuld
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
                  // zorgt ervoor dat de widget wordt geupdate
                  this.setState(() {
                    _areasOfInterest.add(AreaOfInterest(
                      location: point, 
                      radius: initialRadius * 1000
                    ));
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

    // Use _filteredData if it's not empty, otherwise use the original _data
    var displayData = _filteredData.isNotEmpty ? _filteredData : _data;

    if (displayData == null || displayData.isEmpty) {
      return Center(child: Text('Geen dierlocaties beschikbaar'));
    }

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
                  icon: Icon(Icons.favorite),
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
        _isLoading
        ? Center(child: CircularProgressIndicator())
        : Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  children: <Widget>[
                    if (_data != null && _data!.isNotEmpty)
                    Card(
                      child: ListTile(
                        leading: Image.asset('lib/assets/images/zwijn.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.pets, size: 25);
                        },
                      ),
                      title: Text(
                        'Melding 1',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _data![18]['name'] ?? 'Onbekend dier',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Soort: ${_data![18]['species']['commonName'] ?? 'Niet beschikbaar'}'),
                          Text('Locatie: ${_data![18]['location']['latitude'] ?? 'Onbekend'}, '
                          '${_data![18]['location']['longitude'] ?? 'Onbekend'}'),
                          Text(
                            'Laatste update: ${_data![18]['locationTimestamp'] != null
                            ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(_data![18]['locationTimestamp']))
                            : 'Onbekend'}'
                            ),
                        ],
                      ),
                      trailing: Icon(Icons.info_outline),
                      onTap: () => _moveMapToLocation(_data![18]),
                    ),
                  ),
                  Card(
                      child: ListTile(
                        leading: Image.asset('lib/assets/images/zwijn.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.pets, size: 25);
                        },
                      ),
                      title: Text(
                        'Melding 2',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _data![17]['name'] ?? 'Onbekend dier',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Soort: ${_data![17]['species']['commonName'] ?? 'Niet beschikbaar'}'),
                          Text('Locatie: ${_data![17]['location']['latitude'] ?? 'Onbekend'}, '
                          '${_data![17]['location']['longitude'] ?? 'Onbekend'}'),
                          Text(
                            'Laatste update: ${_data![17]['locationTimestamp'] != null
                            ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(_data![18]['locationTimestamp']))
                            : 'Onbekend'}'
                            ),
                        ],
                      ),
                      trailing: Icon(Icons.info_outline),
                      onTap: () => _moveMapToLocation(_data![17]),
                    ),
                  ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FlutterMap(
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
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteView
                    ? "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}"
                    : "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    tileProvider: CancellableNetworkTileProvider(),
                    userAgentPackageName: 'com.example.app',
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
                  // Map attributions (things on the map)
                  Positioned(
                    left: 10,
                    child: Scalebar(
                      lineColor: Colors.black,
                      textStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      padding: EdgeInsets.all(10),
                      length: ScalebarLength.l,
                    ),
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(51.307352, 5.658018), 
                        radius: 350,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 3,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(51.307352, 5.658018), 
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 120,
                      size: Size(50, 50),
                      disableClusteringAtZoom: 16,
                      markers: [ 
                      ...displayData.asMap().entries.where((entry) {
                        int index = entry.key;
                        return index == 16 || index == 17;
                      }).map((entry) {
                        var item = entry.value;
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
                                      fontSize: 12,
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
                ],
              ),
            ),
          ],
        ),
        Center(child: Text('favorieten Pagina')),
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
        Positioned(
          left: 10,
          child:Scalebar(
              lineColor: Colors.black,
              textStyle: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              padding: EdgeInsets.all(10),
              length: ScalebarLength.l,
          ),
        ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 120,
              size: Size(50, 50),
              disableClusteringAtZoom: 16,
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

              if(_trackedAnimal != null)
        ..._trackedAnimal!.locations.asMap().entries.map((entry) {
          int index = entry.key;
          LatLng location = entry.value;
          return Marker(
            point: location,
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () {
                if (index == 0) {
                  _mapController.move(location, 15.0);
                  _showTrackedAnimalDetails();
                }
              },
              child: Icon(
                Icons.pets,
                color: index == 0 ? Colors.black : Colors.blue,
                size: 30,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 2.0,
                  )
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
            // pakt de locatie die is meegegeven vanuit AreaOfInterest()
            circles: _areasOfInterest.map((area) {
              return CircleMarker(
                point: area.location,
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
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _adjustAreaRadius(area),
                  ),
                )
              ).toList(),
            ),
          if (_trackedAnimal != null && _currentlocationIndex > 0)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _trackedAnimal!.locations.sublist(0, _currentlocationIndex + 1),
                strokeWidth: 4.0,
                color: Colors.red.withOpacity(0.7),
              ),
            ],
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
      // ADD SLIDER
      
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
                color: _isSatelliteView ? Colors.green.shade100 : null, // visuele interactie (licht op)
                child: InkWell( // gebruik InkWell voor tap effecten
                  onTap: () {
                    setState(() {
                      _isSatelliteView = !_isSatelliteView;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
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
                width: MediaQuery.of(context).size.width * 0.25 * 0.9,
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
                            Icon(Icons.location_on, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('Gebieden van interesse: ${_areasOfInterest.length}', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        SizedBox(height: 21),
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
              // SizedBox(
              //   width: MediaQuery.of(context).size.width * 0.10 * 1,
              //   child: Card(
              //     elevation: 4,
              //     color: _isTrackedAnimalVisible ? Colors.green.shade100 : null,
              //     child: Padding(
              //       padding: const EdgeInsets.all(8.0),
              //       child: Column(
              //         mainAxisSize: MainAxisSize.min,
              //         children: [
              //           Icon(Icons.pets, color: Colors.orange, size: 20),
              //           Text('Zie alle dieren', style: TextStyle(fontSize: 16)),
              //           Text(DateTime.now().toString().substring(0, 16), style: TextStyle(fontSize: 10)),
              //         ],
              //       ),
              //       ),
              //     ),
              //   ),

              // Card 4: Details
              
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.15 * 0.9,
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
                          // Heeft een _searchcontroller die er voor zorgt dat het woord mee kan worden gegeven
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
                            //roept _filterAnimals aan waarbij de functie gaat filteren
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
      if (_trackedAnimal != null && _isTrackedAnimalVisible)
      Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Card(
          margin: EdgeInsets.all(16.0),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Locatie van: ${_trackedAnimal!.name} (${_trackedAnimal!.commonName})',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Slider(
                  value: _currentlocationIndex.toDouble(),
                  min: 0,
                  max: (_trackedAnimal!.locations.length - 1).toDouble(),
                  divisions: _trackedAnimal!.locations.length -1,
                  label: 'Locatie: ${_currentlocationIndex + 1}',
                  onChanged: (double value) {
                    setState(() {
                      _currentlocationIndex = value.toInt();
                      //Center map to location
                      _mapController.move(
                        _trackedAnimal!.locations[_currentlocationIndex],
                        15.0
                      );
                    });
                  },
                ),
                Text(
                  'Locatie Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                Text(
                  'Locatie: ${_currentlocationIndex + 1}:'
                  '${_trackedAnimal!.locations[_currentlocationIndex].latitude.toStringAsFixed(4)},'
                  '${_trackedAnimal!.locations[_currentlocationIndex].longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 10),
                ),
              ],
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