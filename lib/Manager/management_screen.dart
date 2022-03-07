import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:yoga_house/Client/client_home.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/homepage_message_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/notifications_settings.dart';
import 'package:yoga_house/Manager/Management_Screens/practices_history_screen.dart';
import 'package:yoga_house/Practice/practice_templates_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';

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
    final userInfo = context.read<UserInfo>();
    final iconColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    return SettingsSection(
      title: 'ניהול',
      titleTextStyle: theme.textTheme.bodyText1,
      tiles: [
        SettingsTile(
          title: 'רשימת השיעורים',
          leading: Icon(Icons.run_circle_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {
            await RegisterToPracticeScreen.pushToTabBar(
                context, true, userInfo);
          },
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
          onPressed: (context) async {
            await HomepageTextScreen.pushToTabBar(context, false);
          },
        ),
        SettingsTile(
          title: 'הודעה בדף הבית',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.message_outlined, color: iconColor),
          onPressed: (context) async {
            await HomepageTextScreen.pushToTabBar(context, true);
          },
        ),
        SettingsTile(
          title: 'היסטוריית שיעורים',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.history_toggle_off_rounded, color: iconColor),
          onPressed: (context) async {
            await PracticesHistoryScreen.pushToTabBar(context, null, true);
          },
        ),
        SettingsTile(
          title: 'מבט לדף לקוחות',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading: Icon(Icons.person_outline, color: iconColor),
          onPressed: (context) async {
            // ignore: prefer_const_constructors
            await pushNewScreen(context, screen: ClientHome());
          },
        ),
        // SettingsTile(
        //   title: 'סטטיסטיקה חודשית',
        //   titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
        //   leading: Icon(Icons.data_saver_off_outlined, color: iconColor),
        //   onPressed: (context) {}, //TODO next update!
        // ),
        SettingsTile(
          title: 'התראות',
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          leading:
              Icon(Icons.notification_important_outlined, color: iconColor),
          onPressed: (context) async {
            await AdminNotificationsSettings.pushToTabBar(context);
          },
        ),
      ],
    );
  }
}
