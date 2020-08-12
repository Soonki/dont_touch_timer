import 'package:flutter/material.dart';

import 'timer_setting_page.dart';
import 'countdown_page.dart';

void main() {
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
