import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:yoga_house/Client/health_assurance_screen.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Client_Profile/client_profile_screen.dart';
import 'package:yoga_house/Client_Profile/punch_card_history_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/practices_history_screen.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';

class ClientPersonalScreen extends StatefulWidget {
  final UserInfo user;
  final FirestoreDatabase database;
  final AppInfo appInfo;

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo userInfo) async {
    final database = context.read<FirestoreDatabase>();
    final appInfo = context.read<AppInfo>();
    await pushNewScreen(
      context,
      screen: ClientPersonalScreen(
        database: database,
        user: userInfo,
        appInfo: appInfo,
      ),
    );
  }

  const ClientPersonalScreen(
      {Key? key,
      required this.user,
      required this.database,
      required this.appInfo})
      : super(key: key);

  @override
  _ClientPersonalScreenState createState() => _ClientPersonalScreenState();
}

class _ClientPersonalScreenState extends State<ClientPersonalScreen> {
  late bool isManagerTerminated;
  late bool isClientTerminated;

  @override
  void initState() {
    isManagerTerminated = widget.appInfo.isManagerTerminated;
    isClientTerminated = widget.appInfo.isClientTerminated;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'אישי'),
        actions: [_signOutBtn()],
      ),
      body: SettingsList(backgroundColor: Colors.white, sections: [
        _personalSection(),
        if (_isTomer()) _tomerSection(),
      ]),
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

  SettingsSection _personalSection() {
    final iconColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    return SettingsSection(
      title: 'אישי',
      titleTextStyle: theme.textTheme.bodyText1,
      tiles: [
        SettingsTile(
          title: 'פרופיל וכרטיסיה',
          leading: Icon(Icons.card_membership_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {
            await ClientProfileScreen.pushToTabBar(context, widget.user, false);
          },
        ),
        SettingsTile(
          title: 'היסטוריית כרטיסיות',
          leading: Icon(Icons.history_toggle_off_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {
            await PunchcardHistoryScreen.pushToTabBar(context, widget.user);
          },
        ),
        SettingsTile(
          title: 'היסטוריית שיעורים',
          leading: Icon(Icons.run_circle_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {
            await PracticesHistoryScreen.pushToTabBar(
                context, widget.user, false);
          },
        ),
        SettingsTile(
          title: 'הצהרת בריאות',
          leading: Icon(Icons.health_and_safety_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onPressed: (context) async {
            await HealthAssuranceScreen.pushToTabBar(context, widget.user);
          },
        ),
      ],
    );
  }

  _isTomer() {
    return widget.user.isTomer();
  }

  _tomerSection() {
    final appInfo = context.read<AppInfo>();
    final iconColor = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);
    return SettingsSection(
      title: 'האיזור של תומר',
      // titleTextStyle: theme.textTheme.bodyText1,
      tiles: [
        SettingsTile.switchTile(
          title: 'השבת מנהל',
          switchValue: isManagerTerminated,
          leading: Icon(Icons.card_membership_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onToggle: _toggleTerminateManager,
        ),
        SettingsTile.switchTile(
          title: 'השבת לקוחות',
          switchValue: isClientTerminated,
          leading: Icon(Icons.history_toggle_off_outlined, color: iconColor),
          titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
          onToggle: _toggleTerminateClients,
        ),
      ],
    );
  }

  _toggleTerminateClients(bool newValue) async {
    await widget.database.toggleTerminateClient(newValue);
    setState(() {
      isClientTerminated = newValue;
    });
  }

  _toggleTerminateManager(bool newValue) async {
    await widget.database.toggleTerminateManager(newValue);
    setState(() {
      isManagerTerminated = newValue;
    });
  }
}
