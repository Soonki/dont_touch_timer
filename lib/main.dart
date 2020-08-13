import 'package:flutter/material.dart';

import 'timer_setting_page.dart';
import 'countdown_page.dart';

import 'package:admob_flutter/admob_flutter.dart';
import 'ad_manager.dart';

void main() {
  Admob.initialize(getAppId());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TimerSettingPage(),
      routes: <String, WidgetBuilder>{
        '/timer_setting': (context) => TimerSettingPage(),
        CountdownPage.routeName: (context) => CountdownPage()
      },
    );
  }
}
