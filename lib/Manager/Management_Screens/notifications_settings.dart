import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:yoga_house/Services/notifications.dart';
import 'package:yoga_house/Services/shared_prefs.dart';
import 'package:yoga_house/Services/utils_file.dart';

class AdminNotificationsSettings extends StatefulWidget {
  final SharedPrefs prefs;

  static Future<void> pushToTabBar(BuildContext context) async {
    final prefs = context.read<SharedPrefs>();
    await pushNewScreen(
      context,
      screen: AdminNotificationsSettings(prefs: prefs),
    );
  }

  const AdminNotificationsSettings({Key? key, required this.prefs})
      : super(key: key);

  @override
  AdminNotificationsSettingsState createState() =>
      AdminNotificationsSettingsState();
}

class AdminNotificationsSettingsState
    extends State<AdminNotificationsSettings> {
  late bool clientRegistered;
  late bool clientCancelled;
  @override
  void initState() {
    clientRegistered =
        widget.prefs.adminNotificationClientRegistered.getValue();
    clientCancelled = widget.prefs.adminNotificationClientCancelled.getValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Utils.appBarTitle(context, 'התראות'),
        ),
        body: SettingsList(
          backgroundColor: Colors.white,
          sections: [_notificationsSection()],
        ));
  }

  SettingsSection _notificationsSection() {
    final theme = Theme.of(context);
    return SettingsSection(
      titleTextStyle:
          theme.textTheme.subtitle1?.copyWith(color: theme.colorScheme.primary),
      title: 'אני רוצה לקבל התראות כאשר:',
      tiles: [
        _clientRegisteredToPracticeTile(),
        _clientCancelledTile(),
      ],
    );
  }

  SettingsTile _clientRegisteredToPracticeTile() {
    final notifications = context.read<NotificationService>();
    final theme = Theme.of(context);
    return SettingsTile.switchTile(
      title: 'לקוח נרשם לשיעור',
      titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
      onToggle: (newVal) {
        widget.prefs.toggleAdminNotificationClientRegistered(newVal);
        if (newVal) {
          notifications.adminRegisterToUserRegisteredNotifications();
        } else {
          notifications.adminUnregisterFromUserRegisteredNotifications();
        }
        setState(() {
          clientRegistered =
              widget.prefs.adminNotificationClientRegistered.getValue();
        });
      },
      switchValue: clientRegistered,
      switchActiveColor: theme.colorScheme.primary,
    );
  }

  SettingsTile _clientCancelledTile() {
    final notifications = context.read<NotificationService>();
    final theme = Theme.of(context);
    return SettingsTile.switchTile(
      title: 'לקוח ביטל רישום לשיעור',
      titleTextStyle: theme.textTheme.bodyText1?.copyWith(fontSize: 15),
      onToggle: (newVal) {
        if (newVal) {
          notifications.adminRegisterToUserCancelledNotifications();
        } else {
          notifications.adminUnregisterFromUserCancelledNotifications();
        }
        widget.prefs.toggleAdminNotificationClientCancelled(newVal);
        setState(() {
          clientCancelled =
              widget.prefs.adminNotificationClientCancelled.getValue();
        });
      },
      switchValue: clientCancelled,
      switchActiveColor: theme.colorScheme.primary,
    );
  }
}
