import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client_Profile/client_profile_screen.dart';
import 'package:yoga_house/Manager/new_punchcard_form.dart';
import 'package:yoga_house/Manager/search_widget.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/card_selection_tile.dart';

class ClientsScreen extends StatefulWidget {
  final FirestoreDatabase database;
  const ClientsScreen({Key? key, required this.database}) : super(key: key);

  @override
  _ClientsScreenState createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late Stream<List<UserInfo>> allUsersInfoStream;
  late List<UserInfo>? usersToDisplay;
  late List<UserInfo> allUsers;
  String query = '';

  @override
  void initState() {
    allUsersInfoStream = widget.database.allUsersInfoStream();
    usersToDisplay = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'מתאמנים')),
      body: StreamBuilder<List<UserInfo>>(
          stream: allUsersInfoStream,
          builder: (context, allUsersInfoSnapshot) {
            if (Utils.connectionStateInvalid(allUsersInfoSnapshot)) {
              return const SplashScreen();
            }
            final data = allUsersInfoSnapshot.data;
            if (data == null) return const SplashScreen();
            allUsers = data;
            if (usersToDisplay == null || usersToDisplay!.isEmpty) {
              usersToDisplay = allUsers;
            }
            return Column(
              children: [
                _buildSearch(),
                _buildList(),
              ],
            );
          }),
    );
  }

  _buildSearch() => SearchWidget(
        text: query,
        hintText: 'חיפוש לפי שם או טלפון',
        onChanged: _searchUser,
      );

  _buildList() {
    final usrsTodspl = usersToDisplay;
    if (usrsTodspl == null) {
      return const SplashScreen();
    }
    if (usrsTodspl.isEmpty) {
      return const Center(
        child: Text('אין משתמשים מתאימים.'),
      );
    }

    return ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        shrinkWrap: true,
        itemCount: usrsTodspl.length,
        itemBuilder: (context, index) {
          final user = usrsTodspl[index];
          return _buildUser(user);
        });
  }

  Widget _buildUser(UserInfo user) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.person,
        color: theme.colorScheme.primary,
      ),
      title: Text(user.name),
      subtitle: Text(Utils.stripPhonePrefix(user.phoneNumber)),
      onTap: () => _showChoiceDialog(user),
    );
  }

  _showChoiceDialog(UserInfo userInfo) async {
    await showDialog(
        context: context,
        builder: (context) => Utils.cardSelectionDialog(
            context, _choiceTiles(context, userInfo)));
  }

  List<CardSelectionTile> _choiceTiles(
      BuildContext innerContext, UserInfo userInfo) {
    final theme = Theme.of(innerContext);

    return [
      CardSelectionTile(
        innerContext,
        'פרופיל מתאמן',
        Icon(Icons.person, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await ClientProfileScreen.pushToTabBar(context, userInfo, true);
        },
      ),
      CardSelectionTile(
        innerContext,
        'שלח ווטסאפ',
        Icon(FontAwesomeIcons.whatsapp, color: theme.colorScheme.primary),
        (cardContext) {
          Utils.launchWhatsapp(userInfo.phoneNumber);
        },
      ),
      CardSelectionTile(
        innerContext,
        'הוסף כרטיסיה',
        Icon(Icons.card_membership_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await NewPunchcardForm.show(context, userInfo);
        },
      ),
    ];
  }

  void _searchUser(String query) {
    final newUsersToDisplay = allUsers.where((user) {
      final phone = user.phoneNumber;
      return user.name.contains(query) ||
          Utils.stripPhonePrefix(phone).contains(query);
    }).toList();

    setState(() {
      this.query = query;
      usersToDisplay = newUsersToDisplay;
    });
  }
}
