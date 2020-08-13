import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:quiver/async.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'ad_manager.dart';

format(Duration d) => d.toString().split('.').first.padLeft(8, "0");

class CountdownPage extends StatefulWidget {
  static String routeName = '/countdown';
  @override
  CountdownState createState() => CountdownState();
}

class CountdownState extends State<CountdownPage> {
  Duration _current = Duration(hours: 0, minutes: 30);
  StreamSubscription<CountdownTimer> _sub;
  bool _isInit = false;

  bool _gyroAvailable = false;
  List<double> _gyroData = List.filled(3, 0.0);
  StreamSubscription _gyroSubscription;

  final _player = AudioPlayer();
  final _audioCash = AudioCache();

  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();
  AdmobReward rewardAd;

  @override
  void initState() {
    _checkGyroscopeStatus();

    rewardAd = AdmobReward(
        adUnitId: getRewardBasedVideoAdUnitId(),
        listener: (AdmobAdEvent event, Map<String, dynamic> args) {
          if (event == AdmobAdEvent.closed) rewardAd.load();
          handleEvent(event, args, 'Reward');
        });
    rewardAd.load();
    super.initState();
  }

  @override
  void dispose() {
    _stopGyroscope();
    _player.release();
    super.dispose();
  }

  void _checkGyroscopeStatus() async {
    await SensorManager().isSensorAvailable(Sensors.GYROSCOPE).then((result) {
      setState(() {
        _gyroAvailable = result;
      });
    });
  }

  Future<void> _startGyroscope() async {
    if (_gyroSubscription != null) return;
    if (_gyroAvailable) {
      final stream =
          await SensorManager().sensorUpdates(sensorId: Sensors.GYROSCOPE);
      _gyroSubscription = stream.listen((sensorEvent) {
        setState(() {
          _gyroData = sensorEvent.data;
        });
      });
    }
  }

  void _stopGyroscope() {
    if (_gyroSubscription == null) return;
    _gyroSubscription.cancel();
    _gyroSubscription = null;
  }

  StreamSubscription<CountdownTimer> _startTimer(Duration countDuration) {
    CountdownTimer countDownTimer = new CountdownTimer(
      countDuration, //初期値
      new Duration(seconds: 1), // 減らす幅
    );

    var sub = countDownTimer.listen(null);

    sub.onData((duration) {
      setState(() {
        _current = countDuration - duration.elapsed + Duration(seconds: 1);
      });
    });

    sub.onDone(() {
      print("Done");
      sub.cancel();
      Navigator.of(context).pushReplacementNamed("/timer_setting");
    });

    return sub;
  }

  void init(BuildContext context) async {
    var inputedDuration = ModalRoute.of(context).settings.arguments;
    _current = inputedDuration;
    _sub = _startTimer(inputedDuration);
    await _player.setReleaseMode(ReleaseMode.LOOP);
    File audiofile = await _audioCash.load('alert.wav');
    await _player.setUrl(audiofile.path);
  }

  bool _isHoldPhone() {
    if (_gyroAvailable) {
      var gyro_norm = _gyroData[0] * _gyroData[0] +
          _gyroData[1] * _gyroData[1] +
          _gyroData[2] * _gyroData[2];

      var gyro_threthold = 0.01;
      return gyro_norm > gyro_threthold;
    }
    return false;
  }

  void _startAlert() async {
    await _player.resume();
  }

  void _stopAlert() async {
    await _player.pause();
  }

  void handleEvent(
      AdmobAdEvent event, Map<String, dynamic> args, String adType) {
    switch (event) {
      case AdmobAdEvent.loaded:
        print('New Admob $adType Ad loaded!');
        break;
      case AdmobAdEvent.opened:
        print('Admob $adType Ad opened!');
        break;
      case AdmobAdEvent.closed:
        print('Admob $adType Ad closed!');
        break;
      case AdmobAdEvent.failedToLoad:
        print('Admob $adType failed to load. :(');
        break;
      case AdmobAdEvent.rewarded:
        showDialog(
          context: scaffoldState.currentContext,
          builder: (BuildContext context) {
            return WillPopScope(
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Reward callback fired. Thanks Andrew!'),
                    Text('Type: ${args['type']}'),
                    Text('Amount: ${args['amount']}'),
                  ],
                ),
              ),
              onWillPop: () async {
                scaffoldState.currentState.hideCurrentSnackBar();
                return true;
              },
            );
          },
        );
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      init(context);
      _isInit = true;
    }

    if (_gyroAvailable != null) {
      _startGyroscope();
    }

    if (_isHoldPhone()) {
      Vibration.vibrate();
      _startAlert();
    } else {
      Vibration.cancel();
      _stopAlert();
    }

    return MaterialApp(
      home: Scaffold(
        appBar: new AppBar(
          title: new Text('Don\'t touch timer'),
        ),
        body: Center(
            child: Container(
          padding: EdgeInsets.all(8.0),
          width: 340,
          height: 340,
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Center(
                  child: Text(
                format(_current),
                textAlign: TextAlign.center,
                style: new TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 50.0),
              )),
              RaisedButton(
                  color: Colors.red,
                  onPressed: () async {
                    if (await rewardAd.isLoaded) {
                      _sub.cancel();
                      rewardAd.show();
                      Navigator.of(context)
                          .pushReplacementNamed("/timer_setting");
                    } else {
                      print("Reward ad is still loading...");
                    }
                  },
                  child: new Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white),
                  ))
            ],
          ),
        )),
      ),
    );
  }
}
