import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';

class HomepageTextScreen extends StatefulWidget {
  final FirestoreDatabase database;
  final AppInfo appInfo;
  final bool shouldChangeHomescreenText;

  const HomepageTextScreen({
    Key? key,
    required this.database,
    required this.appInfo,
    required this.shouldChangeHomescreenText,
  }) : super(key: key);

  static Future<void> pushToTabBar(
      BuildContext context, bool shouldChangeHomescreenText) async {
    final database = Provider.of<FirestoreDatabase>(context, listen: false);
    final appInfo = Provider.of<AppInfo>(context, listen: false);
    await pushNewScreen(
      context,
      screen: HomepageTextScreen(
          appInfo: appInfo,
          database: database,
          shouldChangeHomescreenText: shouldChangeHomescreenText),
    );
  }

  @override
  _HomepageTextScreenState createState() => _HomepageTextScreenState();
}

class _HomepageTextScreenState extends State<HomepageTextScreen> {
  final _homepageTextController = TextEditingController();
  final _notificationTextController = TextEditingController();
  @override
  void initState() {
    _homepageTextController.text = widget.appInfo.homepageText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'הודעה ללקוחות'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (widget.shouldChangeHomescreenText) _heading(theme),
            const SizedBox(height: 20),
            if (widget.shouldChangeHomescreenText)
              _homepageMessageTextField(theme),
            if (widget.shouldChangeHomescreenText)
              _submitHomepageMessageButton(theme),
            if (!widget.shouldChangeHomescreenText)
              _singleNotificationHeading(theme),
            if (!widget.shouldChangeHomescreenText)
              _singleNotificationTextField(theme),
            if (!widget.shouldChangeHomescreenText)
              _submitSingleNotificationButton(theme),
          ],
        ),
      ),
    );
  }

  ElevatedButton _submitHomepageMessageButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _submitHomepageMessage,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      child: const Text(
        "עדכן הודעה",
        style: TextStyle(fontSize: 15),
      ),
    );
  }

  _submitSingleNotificationButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _submitSingleNotification,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      child: const Text(
        "שלח התראה",
        style: TextStyle(fontSize: 15),
      ),
    );
  }

  _submitHomepageMessage() async {
    if (_homepageTextController.text.isEmpty) {
      return;
    }
    final shouldSend = await _didConfirm(notificationType.homepageNotification);
    if (!shouldSend) return;
    await widget.database
        .setHomepageText(_homepageTextController.text, widget.appInfo);
    await widget.database.addHomepageMessage(_homepageTextController.text);
    Navigator.of(context).pop();
  }

  Future<void> _submitSingleNotification() async {
    if (_notificationTextController.text.isEmpty) {
      return;
    }
    final shouldSend = await _didConfirm(notificationType.singleNotification);
    if (!shouldSend) return;
    await widget.database.addHomepageMessage(_notificationTextController.text);
    Navigator.of(context).pop();
  }

  _heading(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        "הודעה לדף הבית שתישלח גם התראה:",
        style: theme.textTheme.bodyText1?.copyWith(fontSize: 18),
      ),
    );
  }

  _singleNotificationHeading(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        "שלח התראה לכל הלקוחות הקיימים:",
        style: theme.textTheme.bodyText1?.copyWith(fontSize: 18),
      ),
    );
  }

  _homepageMessageTextField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: TextField(
        controller: _homepageTextController,
        decoration: const InputDecoration(
          labelText: "הודעה בדף הבית",
          border: OutlineInputBorder(),
        ),
        minLines: 7,
        maxLines: 7,
        maxLength: 250,
      ),
    );
  }

  _singleNotificationTextField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: TextField(
        controller: _notificationTextController,
        decoration: const InputDecoration(
          labelText: "התראה",
          border: OutlineInputBorder(),
        ),
        minLines: 3,
        maxLines: 3,
        maxLength: 100,
      ),
    );
  }

  Future<bool> _didConfirm(notificationType type) async {
    final text = type == notificationType.homepageNotification
        ? 'הודעה זו גם תחליף את ההודעה בדף הבית של הלקוחות וגם תישלח בתור נוטיפיקציה לכולם.'
        : 'הודעה זו תישלח לכל הלקוחות, אך לא תחליף את ההודעה בדף הבית';
    final didConfirm = await showOkCancelAlertDialog(
        context: context, title: 'שים לב', message: text, okLabel: 'שלח');
    return didConfirm == OkCancelResult.ok;
  }
}

enum notificationType { singleNotification, homepageNotification }
