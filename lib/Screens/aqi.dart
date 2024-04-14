import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:air_watch/Util/open_whether_api.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Strings/strings.dart';
import '../Util/location.dart';
import '../Util/notify.dart';

class Aqi extends StatefulWidget {
  const Aqi({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<Aqi> createState() => _AqiState();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class _AqiState extends State<Aqi> {
  late String _aqiStatus;
  late String _aqiImage;
  late Color currentColor;
  String currentAddress = "";
  AirQualityData airQualityData = AirQualityData(aqi: 1, gases: {});
  bool isMapvisible = false;
  int currentAQIIndex = 1;

  Timer? _timer;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    Noti.initialize(flutterLocalNotificationsPlugin);
    _aqiStatus = "Good";
    _aqiImage = aqi_1; // Placeholder for your image asset
    currentColor = Colors.green;
    currentAQIIndex = 1;

    getLocation();
    startTimer(); // Start the timer for periodic updates
    startListening();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _positionStreamSubscription?.cancel();

    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 30), (Timer timer) {
      getLocation(); // Fetch AQI every 30 minutes
    });
  }

  Future<void> startListening() async {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          distanceFilter: 50, accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      Fluttertoast.showToast(
          msg: "Refreshing",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0);

      getLocation();
    });
  }

  Future<void> getLocation() async {
    Position position = await determinePosition();

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    var address = placemarks[0];
    currentAddress =
        "${address.subLocality} ${address.locality} ${address.administrativeArea} ${address.country}";

    fetchAQI(position.latitude, position.longitude);
  }

  Future<void> fetchAQI(double lat, double lon) async {
    OpenWeatherMapApi openW = OpenWeatherMapApi();

    airQualityData = (await openW.fetchAirQuality(lat, lon))!;
    int? aqi = airQualityData.aqi;

    getAQIUpdate(aqi);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        MoveToBackground.moveTaskToBack();
        return false;
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: isMapvisible == false
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton(
                  child: const Icon(Icons.refresh),
                  onPressed: () async {
                    Fluttertoast.showToast(
                        msg: "Refreshing",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.black87,
                        textColor: Colors.white,
                        fontSize: 16.0);
                    await getLocation();
                  },
                ),
              )
            : null,
        appBar: AppBar(
          title: Text(
            "AirWatch",
            style: GoogleFonts.poppins(
                textStyle: Theme.of(context).textTheme.titleSmall),
          ),
        ),
        body: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (isMapvisible == true) {
                          isMapvisible = false;
                        } else {
                          isMapvisible = true;
                        }
                        setState(() {});
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            borderRadius: BorderRadius.circular(15)),
                        child: const Icon(
                          Icons.location_on_sharp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          currentAddress,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: Container(
                    height: MediaQuery.sizeOf(context).height / 6,
                    decoration: BoxDecoration(
                      color: currentColor,
                      border: Border.all(color: Colors.black87),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(_aqiImage))),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentAQIIndex.toString(),
                              style: GoogleFonts.poppins(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w500,
                                  textStyle:
                                      Theme.of(context).textTheme.bodyMedium),
                            ),
                            const Text("AQI"),
                          ],
                        ),
                        Text(
                          _aqiStatus,
                          style: GoogleFonts.poppins(
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                              textStyle:
                                  Theme.of(context).textTheme.bodyMedium),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: airQualityData.gases.length,
                    itemBuilder: (context, index) {
                      Iterable<String> gases = airQualityData.gases.keys;

                      return Center(
                        child: Container(
                          height: 80,
                          width: 60,
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.black87),
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.deepPurpleAccent.withOpacity(0.1)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(gases.elementAt(index)),
                              Text(
                                  "${airQualityData.gases[gases.elementAt(index)]}")
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "Change the notification settings",
                      style: GoogleFonts.poppins(
                          textStyle: Theme.of(context).textTheme.titleSmall),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FlutterToggleTab(
                        width: 50,
                        borderRadius: 15,
                        selectedIndex:
                            widget.prefs.getBool("Notification_Allowed")! ==
                                    true
                                ? 1
                                : 0,
                        selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        unSelectedTextStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                        labels: const ["OFF", "ON"],
                        icons: const [
                          Icons.notifications_off,
                          Icons.notifications
                        ],
                        selectedLabelIndex: (index) async {
                          if (index == 0) {
                            await widget.prefs
                                .setBool("Notification_Allowed", false);
                          } else {
                            await widget.prefs
                                .setBool("Notification_Allowed", true);
                          }
                          setState(() {
                            // _tabIconIndexSelected = index;
                          });
                        },
                        marginSelected: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          Visibility(
            visible: isMapvisible,
            child: OpenStreetMapSearchAndPick(
                buttonColor: Colors.deepPurpleAccent,
                buttonText: 'Set Current Location',
                onPicked: (pickedData) {
                  fetchAQI(pickedData.latLong.latitude,
                      pickedData.latLong.longitude);
                  currentAddress = pickedData.addressName;
                  isMapvisible = false;
                  setState(() {});
                }),
          )
        ]),
      ),
    );
  }

  void getAQIUpdate(int aqi) {
    bool send = false;
    if (currentAQIIndex != aqi) {
      send = true;
    }
    if (aqi == 1) {
      currentColor = Colors.green;
      _aqiStatus = "Good";
      _aqiImage = aqi_1;
      currentAQIIndex = 1;
    }

    if (aqi == 2) {
      currentColor = Colors.yellow;
      _aqiStatus = "Fair";
      _aqiImage = aqi_2;
      currentAQIIndex = 2;
    }

    if (aqi == 3) {
      currentColor = Colors.deepOrangeAccent;
      _aqiStatus = "Moderate";
      _aqiImage = aqi_3;
      currentAQIIndex = 3;
    }

    if (aqi == 4) {
      currentColor = Colors.red;
      _aqiStatus = "Poor";
      _aqiImage = aqi_4;
      currentAQIIndex = 4;
    }

    if (aqi == 5) {
      currentColor = Colors.deepPurpleAccent;
      _aqiStatus = "Very Poor";
      _aqiImage = aqi_5;
      currentAQIIndex = 5;
    }

    setState(() {}); // Update the UI with new AQI data
    if (send) {
      if (widget.prefs.getBool("Notification_Allowed")!) {
        Noti.showBigTextNotification(
            title: currentAQIIndex > 3 ? "Wear Mask" : "Remove Mask",
            body: "Pollution : $_aqiStatus",
            fln: flutterLocalNotificationsPlugin);
      }
    }
  }
}
