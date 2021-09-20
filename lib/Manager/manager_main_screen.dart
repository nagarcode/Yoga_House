import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Manager/manager_calendar.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({Key? key}) : super(key: key);

  @override
  _ManagerMainScreenState createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  late GlobalKey<ScaffoldState> _scaffoldKey;
  @override
  void initState() {
    _scaffoldKey = GlobalKey<ScaffoldState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final database = context.read<FirestoreDatabase>();
    final prefs = context.read<SharedPrefs>();
    final theme = Theme.of(context);
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Utils.appBarTitle(context, 'ראשי'),
        ),
        body: ManagerCalendar(prefs,
            parentScaffoldKey: _scaffoldKey, database: database));
  }
}
