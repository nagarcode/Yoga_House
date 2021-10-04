import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';
import 'package:yoga_house/common_widgets/punch_card.dart';
import 'package:yoga_house/common_widgets/punch_card_view.dart';

class PunchcardHistoryScreen extends StatefulWidget {
  final UserInfo userInfo;
  final FirestoreDatabase database;

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo userInfo) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      screen: PunchcardHistoryScreen(
        database: database,
        userInfo: userInfo,
      ),
    );
  }

  const PunchcardHistoryScreen(
      {Key? key, required this.userInfo, required this.database})
      : super(key: key);

  @override
  _PunchcardHistoryScreenState createState() => _PunchcardHistoryScreenState();
}

class _PunchcardHistoryScreenState extends State<PunchcardHistoryScreen> {
  late Future<List<Punchcard>> punchcardsFuture;

  @override
  void initState() {
    punchcardsFuture = widget.database.userPunchcardsFuture(widget.userInfo);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Punchcard>>(
      future: punchcardsFuture,
      builder: (context, snapshot) {
        if (Utils.connectionStateInvalid(snapshot)) return const SplashScreen();
        final punchcards = snapshot.data;
        if (punchcards == null) return const SplashScreen();
        return Scaffold(
            appBar: AppBar(
              title: Utils.appBarTitle(context, 'היסטוריית כרטיסיות'),
            ),
            body: _punchcardListView(punchcards));
      },
    );
  }

  Widget _punchcardListView(List<Punchcard> punchcards) {
    final punchcardsViews = _buildPunchcardsViews(punchcards);
    if (punchcards.isEmpty) {
      return const Center(
        child: Text('טרם נרכשו כרטיסיות'),
      );
    }
    return ListView(
      children: punchcardsViews,
    );
  }

  List<PunchcardView> _buildPunchcardsViews(List<Punchcard> punchcards) {
    return punchcards
        .map(
          (punchcard) => PunchcardView(
            punchcard: punchcard,
            isManagerView: false,
            decrementCallback: () {},
            incrementCallback: () {},
          ),
        )
        .toList();
  }
}
