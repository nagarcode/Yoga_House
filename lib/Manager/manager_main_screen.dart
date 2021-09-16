import 'package:flutter/material.dart';
import 'package:yoga_house/Manager/manager_calendar.dart';
import 'package:yoga_house/Services/utils_file.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({Key? key}) : super(key: key);

  @override
  _ManagerMainScreenState createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
          title: Utils.appBarTitle(context, 'ראשי'),
        ),
        body: ManagerCalendar());
  }
}
