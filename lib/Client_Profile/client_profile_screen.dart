import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card_view.dart';

class ClientProfileScreen extends StatefulWidget {
  final String uid;
  final FirestoreDatabase database;
  final bool isManagerView;
  final List<UserInfo> allUsers;

  static Future<void> pushToTabBar(BuildContext context, String uid,
      bool isManagerView, List<UserInfo> allUsers) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      screen: ClientProfileScreen(
        database: database,
        uid: uid,
        isManagerView: isManagerView,
        allUsers: allUsers,
      ),
    );
  }

  const ClientProfileScreen({
    Key? key,
    required this.uid,
    required this.database,
    required this.isManagerView,
    required this.allUsers,
  }) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  late UserInfo userInfo;
  @override
  void initState() {
    userInfo =
        widget.allUsers.firstWhere((element) => element.uid == widget.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print(userInfo);
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'פרופיל מתאמן')),
      body: Column(
        children: [
          _buildInfoCard(userInfo, context),
          _buildPunchCard(userInfo, context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(UserInfo userInfo, BuildContext context) {
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
                title: Text(userInfo.name),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: theme.colorScheme.primary),
                title: widget.isManagerView
                    ? Text(Utils.stripPhonePrefix(
                        userInfo.phoneNumber + ' (לחץ להתקשר)'))
                    : Text(Utils.stripPhonePrefix(userInfo.phoneNumber)),
                onTap: () => Utils.call(userInfo.phoneNumber, context),
              ),
              ListTile(
                leading: Icon(Icons.email_outlined,
                    color: theme.colorScheme.primary),
                title: Text(userInfo.email),
                // onTap: () => {},
              ),
            ],
          )),
    );
  }

  Widget _buildPunchCard(UserInfo userInfo, BuildContext context) {
    final theme = Theme.of(context);
    final punchCard = userInfo.punchcard;
    if (punchCard == null) {
      return Text('אין לך כרטיסיה. לרכישה אנא צור קשר.',
          textAlign: TextAlign.center, style: theme.textTheme.bodyText1);
    } else {
      return PunchcardView(
        punchcard: punchCard,
        isManagerView: widget.isManagerView,
        decrementCallback: () async {
          final newPunchcard =
              await userInfo.decrementPunchcard(widget.database, context);
          setState(() {
            this.userInfo = userInfo.copyWith(punchCard: newPunchcard);
          });
        },
        incrementCallback: () async {
          final newPunchcard =
              await userInfo.incrementPunchcard(widget.database, context);
          setState(() {
            this.userInfo = userInfo.copyWith(punchCard: newPunchcard);
          });
        },
      );
    }
  }
}
