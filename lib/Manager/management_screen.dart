import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:yoga_house/Practice/practice_templates_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({Key? key}) : super(key: key);

  @override
  _ManagementScreenState createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'ראשי'),
        actions: [_signOutBtn()],
      ),
      body: SettingsList(
          backgroundColor: Colors.white, sections: [_managementSection()]),
    );
  }

  Widget _signOutBtn() {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () => Utils.signOut(context),
      child: Text(
        'התנתק',
        style: theme.textTheme.subtitle1?.copyWith(color: Colors.white),
      ),
    );
  }

  SettingsSection _managementSection() {
    final iconColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    return SettingsSection(
      title: 'ניהול',
      titleTextStyle: theme.textTheme.bodyText1,
      tiles: [
        SettingsTile(
          title: 'רשימת שיעורים',
          leading: Icon(Icons.run_circle_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {},
        ),
        SettingsTile(
          title: 'תבניות שיעור',
          leading: Icon(Icons.run_circle_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {
            await PracticeTemplatesScreen.pushToTabBar(context);
          },
        ),
        SettingsTile(
          title: 'שלח הודעה ללקוחות',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.edit_notifications_outlined, color: iconColor),
        ),
        SettingsTile(
          title: 'הודעה בדף הבית',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.message_outlined, color: iconColor),
        ),
        SettingsTile(
          title: 'היסטוריית אימונים',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.history_toggle_off_rounded, color: iconColor),
        ),
        SettingsTile(
          title: 'סטטיסטיקה חודשית',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.data_saver_off_outlined, color: iconColor),
        ),
        SettingsTile(
          title: 'התראות',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading:
              Icon(Icons.notification_important_outlined, color: iconColor),
        ),
        SettingsTile(
          title: 'מבט לדף לקוחות',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.person_outline_outlined, color: iconColor),
        ),
      ],
    );
  }
}
