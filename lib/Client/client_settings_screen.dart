import 'package:flutter/material.dart';
import 'package:yoga_house/Services/utils_file.dart';

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({Key? key}) : super(key: key);

  @override
  _ClientSettingsScreenState createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends State<ClientSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Utils.appBarTitle(context, 'הגדרות'),
        actions: [_signOutBtn()],
      ),
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
}
