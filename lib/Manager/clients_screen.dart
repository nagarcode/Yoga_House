import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Client/health_assurance_screen.dart';
import 'package:yoga_house/Client/register_to_practice_screen.dart';
import 'package:yoga_house/Client_Profile/client_profile_screen.dart';
import 'package:yoga_house/Client_Profile/punch_card_history_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/cancellation_history_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/practices_history_screen.dart';
import 'package:yoga_house/Manager/Management_Screens/repeating_practices_screen.dart';
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
    final user = context.read<UserInfo>();
    if (user.isTest()) {
      return const Center(
        child: Text('TBD'),
      );
    }
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
          appBar: AppBar(title: Utils.appBarTitle(context, '??????????????')),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildSearch(allUsers),
                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _count(usersToDisplay))),
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
        hintText: '?????????? ?????? ???? ???? ??????????',
        onChanged: (query) => _searchUser(query, allUsers),
      );

  _buildList(List<UserInfo> allUsers) {
    usersToDisplay?.sort((a, b) => a.name.compareTo(b.name));
    final usrsTodspl = usersToDisplay;
    if (usrsTodspl == null) {
      return const SplashScreen();
    }
    if (usrsTodspl.isEmpty) {
      return const Center(
        child: Text('?????? ?????????????? ??????????????.'),
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
        '???????????? ??????????',
        Icon(Icons.person, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await ClientProfileScreen.pushToTabBar(
              context, userInfo.uid, true, allUsers);
        },
      ),
      CardSelectionTile(
        innerContext,
        '?????? ?????????? ????????????????',
        Icon(Icons.add, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await RegisterToPracticeScreen.pushToTabBar(context, true, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        '?????? ????????????',
        Icon(FontAwesomeIcons.whatsapp, color: theme.colorScheme.primary),
        (cardContext) {
          Utils.launchWhatsapp(userInfo.phoneNumber);
        },
      ),
      CardSelectionTile(
        innerContext,
        '?????????? ????????????',
        Icon(Icons.health_and_safety_outlined,
            color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await HealthAssuranceScreen.pushToTabBar(context, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        '?????????????????? ??????????????',
        Icon(Icons.run_circle_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await PracticesHistoryScreen.pushToTabBar(context, userInfo, false);
        },
      ),
      CardSelectionTile(
        innerContext,
        '?????????????????? ????????????????',
        Icon(Icons.history_toggle_off_outlined,
            color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await PunchcardHistoryScreen.pushToTabBar(context, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        '?????????????????? ??????????????',
        Icon(Icons.auto_delete_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await CancellationHistoryScreen.pushToTabBar(context, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        '???????? ??????????????',
        Icon(Icons.card_membership_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await NewPunchcardForm.show(context, userInfo);
        },
      ),
      CardSelectionTile(
        innerContext,
        '???????? ???????????? ????????',
        Icon(Icons.loop_outlined, color: theme.colorScheme.primary),
        (cardContext) async {
          Navigator.of(cardContext).pop();
          await RepeatingPracticesScreen.pushToTabBar(context, userInfo);
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

  _count(List<UserInfo>? usersToDisplay) {
    return Text('????????????: ' +
        (usersToDisplay != null ? usersToDisplay.length.toString() : '0'));
  }
}
