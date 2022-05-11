import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Manager/manager_calendar.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/notifications.dart';
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
    final notifications = context.read<NotificationService>();
    // final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'יוגה  האוס'),
        actions: [_lockIconButton(), _unlockIconButton()],
      ),
      body: ManagerCalendar(
        prefs,
        notifications,
        parentScaffoldKey: _scaffoldKey,
        database: database,
      ),
    );
  }

  Widget _lockIconButton() {
    return IconButton(
        onPressed: _lockAll, icon: const Icon(Icons.lock_outline));
  }

  Widget _unlockIconButton() {
    return IconButton(
        onPressed: _unlockAll, icon: const Icon(Icons.lock_open_outlined));
  }

  Future<void> _lockAll() async {
    final database = context.read<FirestoreDatabase>();
    if (await shouldLock()) {
      final practices = context.read<List<Practice>>();
      for (var practice in practices) {
        if (!practice.isLocked) practice.lockWithoutPromt(database);
      }
    }
  }

  void _unlockAll() async {
    final database = context.read<FirestoreDatabase>();
    if (await shouldUnLock()) {
      final practices = context.read<List<Practice>>();
      for (var practice in practices) {
        if (practice.isLocked) practice.unlockWithoutPromt(database);
      }
    }
  }

  Future<bool> shouldLock() async {
    return await showOkCancelAlertDialog(
            context: context,
            title: 'נעל הכל',
            message: 'האם לנעול את כל השיעורים?') ==
        OkCancelResult.ok;
  }

  Future<bool> shouldUnLock() async {
    return await showOkCancelAlertDialog(
            context: context,
            title: 'בטל נעילה להכל',
            message: 'האם לשחרר את נעילת כל השיעורים?') ==
        OkCancelResult.ok;
  }
}
