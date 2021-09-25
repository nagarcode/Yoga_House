import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Services/api_path.dart';
import 'package:yoga_house/Services/app_info.dart';
import 'package:yoga_house/Services/auth.dart';
import 'package:yoga_house/Services/utils_file.dart';

class ClientMainScreen extends StatefulWidget {
  final AppInfo appInfo;
  const ClientMainScreen({Key? key, required this.appInfo}) : super(key: key);

  @override
  _ClientMainScreenState createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'יוגה  האוס'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _logo(),
              _homepageText(theme, widget.appInfo),
              SizedBox(
                height: 60,
                child: _registerToPracticeButton,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _registerToPracticeButton => Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40))),
          child: const Text(
            'רישום לתרגול',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () async {
            await RegisterToPracticeScreen.pushToTabBar(context);
          },
        ),
      );

  Widget _logo() {
    return SizedBox(
        height: 140,
        width: 50,
        child: Image.asset(
          APIPath.logo(),
          fit: BoxFit.cover,
        ));
  }

  void _signOut() async {
    final auth = context.read<AuthBase>();
    final didRequestLeave = await showOkCancelAlertDialog(
        context: context,
        isDestructiveAction: true,
        okLabel: 'התנתק',
        cancelLabel: 'ביטול',
        title: 'התנתקות',
        message: 'האם להתנתק מהמערכת?');
    if (didRequestLeave == OkCancelResult.ok) auth.signOut();
  }

  _homepageText(ThemeData theme, AppInfo appInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8.0),
      child: Center(
        child: Text(
          appInfo.homepageText,
          textAlign: TextAlign.center,
          style: theme.textTheme.headline6,
        ),
      ),
    );
  }
}
