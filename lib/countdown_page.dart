import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:quiver/async.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:flutter_sensors/flutter_sensors.dart';

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

  bool _accelAvailable = false;
  bool _gyroAvailable = false;
  List<double> _accelData = List.filled(3, 0.0);
  List<double> _gyroData = List.filled(3, 0.0);
  StreamSubscription _accelSubscription;
  StreamSubscription _gyroSubscription;

  final _player = AudioPlayer();
  final _audioCash = AudioCache();

  @override
  void initState() {
    _checkAccelerometerStatus();
    _checkGyroscopeStatus();
    super.initState();
  }

  @override
  void dispose() {
    _stopAccelerometer();
    _stopGyroscope();
    _player.release();
    super.dispose();
  }

  void _checkAccelerometerStatus() async {
    await SensorManager()
        .isSensorAvailable(Sensors.ACCELEROMETER)
        .then((result) {
      setState(() {
        _accelAvailable = result;
      });
    });
  }

  Future<void> _startAccelerometer() async {
    if (_accelSubscription != null) return;
    if (_accelAvailable) {
      final stream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: Sensors.SENSOR_DELAY_FASTEST,
      );
      _accelSubscription = stream.listen((sensorEvent) {
        setState(() {
          _accelData = sensorEvent.data;
        });
      });
    }
  }

  void _stopAccelerometer() {
    if (_accelSubscription == null) return;
    _accelSubscription.cancel();
    _accelSubscription = null;
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

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      init(context);
      _isInit = true;
    }

    if (_accelAvailable != null) {
      _startAccelerometer();
    }

    if (_gyroAvailable != null) {
      _startGyroscope();
    }

    // print(_accelData);
    // print(_gyroData);
    print(_isHoldPhone());
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
        body: Container(
          padding: EdgeInsets.all(16.0),
          alignment: AlignmentDirectional.topCenter,
          child: Column(
            children: <Widget>[
              Text(format(_current)),
              RaisedButton(
                onPressed: () {
                  _sub.cancel();
                  Navigator.of(context).pushReplacementNamed("/timer_setting");
                },
                child: new Text('CANCEL'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
