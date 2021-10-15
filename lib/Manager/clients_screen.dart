import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yoga_house/Client/health_assurance_screen.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Client_Profile/client_profile_screen.dart';
import 'package:yoga_house/Client_Profile/punch_card_history_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/cancellation_history_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/practices_history_screen.dart';
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
  // late List<UserInfo> allUsers;
  String query = '';

  @override
  void initState() {
    allUsersInfoStream = widget.database.allUsersInfoStream();
    usersToDisplay = [];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserInfo>>(
      stream: allUsersInfoStream,
      builder: (context, allUsersInfoSnapshot) {
        var allUsers = <UserInfo>[];
        if (Utils.connectionStateInvalid(allUsersInfoSnapshot)) {
          return const SplashScreen();
        }
        final data = allUsersInfoSnapshot.data;
        if (data == null) return const SplashScreen();
        allUsers = data;
        if (usersToDisplay == null || usersToDisplay!.isEmpty) {
          usersToDisplay = allUsers;
        }
        // print(allUsers.first.punchcard?.punchesRemaining);
        return Scaffold(
          appBar: AppBar(title: Utils.appBarTitle(context, 'מתאמנים')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildSearch(allUsers),
                _buildList(allUsers),
              ],
            ),
          ),
        );
      },
    );
  }

  _buildSearch(List<UserInfo> allUsers) => SearchWidget(
        text: query,
        hintText: 'חיפוש לפי שם או טלפון',
        onChanged: (query) => _searchUser(query, allUsers),
      );

  _buildList(List<UserInfo> allUsers) {
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
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (context, index) => const Divider(),
        shrinkWrap: true,
        itemCount: usrsTodspl.length,
        itemBuilder: (context, index) {
          final user = usrsTodspl[index];
          return _buildUser(user, allUsers);
        });
  }

  Widget _buildUser(UserInfo user, List<UserInfo> allUsers) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.person,
        color: theme.colorScheme.primary,
      ),
      title: Text(user.name),
      subtitle: Text(Utils.stripPhonePrefix(user.phoneNumber)),
      onTap: () => _showChoiceDialog(user, allUsers),
    );
  }

  _showChoiceDialog(UserInfo userInfo, List<UserInfo> allUsers) async {
    await showDialog(
        context: context,
        builder: (context) => Utils.cardSelectionDialog(
            context, _choiceTiles(context, userInfo, allUsers)));
  }

  List<CardSelectionTile> _choiceTiles(
      BuildContext innerContext, UserInfo userInfo, List<UserInfo> allUsers) {
    final theme = Theme.of(innerContext);
    return [
      CardSelectionTile(
        innerContext,
        'פרופיל מתאמן',
        Icon(Icons.person, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await ClientProfileScreen.pushToTabBar(
              context, userInfo.uid, true, allUsers);
        },
      ),
      CardSelectionTile(
        innerContext,
        'נהל רישום לשיעורים',
        Icon(Icons.add, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await RegisterToPracticeScreen.pushToTabBar(context, true, userInfo);
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
        'הצהרת בריאות',
        Icon(Icons.health_and_safety_outlined,
            color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await HealthAssuranceScreen.pushToTabBar(context, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        'היסטוריית שיעורים',
        Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await PracticesHistoryScreen.pushToTabBar(context, userInfo, false);
        },
      ),
      CardSelectionTile(
        innerContext,
        'היסטוריית כרטיסיות',
        Icon(Icons.history_toggle_off_outlined,
            color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await PunchcardHistoryScreen.pushToTabBar(context, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        'היסטוריית ביטולים',
        Icon(Icons.auto_delete_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await CancellationHistoryScreen.pushToTabBar(context, userInfo);
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

  void _searchUser(String query, List<UserInfo> allUsers) {
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
