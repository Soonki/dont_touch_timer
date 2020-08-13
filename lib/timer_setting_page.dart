import 'package:dont_touch_timer/countdown_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_duration_picker/flutter_duration_picker.dart';
import 'ad_manager.dart';
import 'package:admob_flutter/admob_flutter.dart';

class TimerSettingPage extends StatefulWidget {
  @override
  TimerSettingState createState() => TimerSettingState();
}

class TimerSettingState extends State<TimerSettingPage> {
  Duration _duration = Duration(hours: 0, minutes: 30);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Don\'t touch timer'),
      ),
      body: new Center(
          child: Container(
              height: 360,
              width: 360,
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  new Expanded(
                      child: DurationPicker(
                    height: 240,
                    width: 240,
                    duration: _duration,
                    onChange: (val) {
                      this.setState(() => _duration = val);
                    },
                    snapToMins: 5.0,
                  )),
                  RaisedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed(
                        CountdownPage.routeName,
                        arguments: _duration),
                    child: new Text('START',
                        style: new TextStyle(color: Colors.white)),
                    color: Colors.green,
                  )
                ],
              ))),
    );
  }
}
