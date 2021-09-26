import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card_view.dart';

class ClientProfileScreen extends StatefulWidget {
  final UserInfo userInfo;
  final FirestoreDatabase database;
  final bool isManagerView;

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo userInfo, bool isManagerView) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      screen: ClientProfileScreen(
        database: database,
        userInfo: userInfo,
        isManagerView: isManagerView,
      ),
    );
  }

  const ClientProfileScreen(
      {Key? key,
      required this.userInfo,
      required this.database,
      required this.isManagerView})
      : super(key: key);

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'פרופיל מתאמן')),
      body: Column(
        children: [_buildInfoCard(), _buildPunchCard()],
      ),
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);
    return SizedBox(
      // height: 240,
      width: double.infinity,
      child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.grey[50],
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person, color: theme.colorScheme.primary),
                title: Text(widget.userInfo.name),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: theme.colorScheme.primary),
                title: Text(Utils.stripPhonePrefix(
                    widget.userInfo.phoneNumber + ' (לחץ להתקשר)')),
                onTap: () => Utils.call(widget.userInfo.phoneNumber, context),
              ),
              ListTile(
                leading: Icon(Icons.email_outlined,
                    color: theme.colorScheme.primary),
                title: Text(widget.userInfo.email),
                // onTap: () => {},
              ),
            ],
          )),
    );
  }

  Widget _buildPunchCard() {
    final theme = Theme.of(context);
    final punchCard = widget.userInfo.punchcard;
    if (punchCard == null) {
      return Text('טרם נרכשה כרטיסיה. לרכישה אנא צור קשר.',
          textAlign: TextAlign.center, style: theme.textTheme.bodyText1);
    } else {
      return PunchcardView(punchcard: punchCard);
    }
  }
}
