import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

class HomePage extends StatefulWidget {

  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   Position _currentPosition=new Position(longitude: 86.78, latitude: 173.587, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 0, speedAccuracy: 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_currentPosition != null) Text(
                "LAT: ${_currentPosition.latitude}, LNG: ${_currentPosition.longitude}"
            ),
            TextButton(
              child: Text("Get location"),
              onPressed:(){_startService();
              },
            ),
          ],
        ),
      ),
    );
  }
/*
   @override
   void initState() {
     Workmanager.initialize(
       callbackDispatcher,
       isInDebugMode: true,
     );

     Workmanager.registerPeriodicTask(
       "1",
       fetchBackground,
       frequency: Duration(minutes: 30),
     );
   }
   */


   _getCurrentLocation() async {
     await Geolocator
         .getCurrentPosition(desiredAccuracy: LocationAccuracy.best, forceAndroidLocationManager: true)
         .then((Position position) {
       setState(() {
         _currentPosition = position;
         createAlbum(position);
       });
     }).catchError((e) {
       print(e);
     });
   }


    Future<void> _startService() async {
      late LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 1),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.fitness,
          distanceFilter: 1,
          pauseLocationUpdatesAutomatically: true,
        );
      } else {
        print("errore");
        locationSettings = LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 1,
        );
      }
      StreamSubscription<ServiceStatus> serviceStatusStream = Geolocator
          .getServiceStatusStream().listen(
              (ServiceStatus status) {
            print(status);
          });
      startForegroundService();
      StreamSubscription<Position> positionStream = await Geolocator
          .getPositionStream(locationSettings: locationSettings).listen(
              (Position? position) {
            print("chiamata");

            if (position != null) {
              createAlbum(position);
            }
          });
    }
  void startForegroundService() async {
    await FlutterForegroundPlugin.setServiceMethodInterval(seconds: 5);
    await FlutterForegroundPlugin.setServiceMethod(globalForegroundService);
    await FlutterForegroundPlugin.startForegroundService(
      holdWakeLock: false,
      onStarted: () {
        print("Foreground on Started");
      },
      onStopped: () {
        print("Foreground on Stopped");
      },
      title: "Flutter Foreground Service",
      content: "This is Content",
      iconName: "ic_stat_hot_tub",
    );
  }

   Future<http.Response> createAlbum(Position position) async {
     return http.post(
       Uri.parse('http://192.168.1.122:3000/api/data/location/send'),
       headers: <String, String>{
         'Content-Type': 'application/json; charset=UTF-8',
       },
       body: jsonEncode(<String, dynamic>{
         'user_id': 1,
         'latitude':position.latitude,
         'longitude':position.longitude,
       }),
     );
   }

  

}
