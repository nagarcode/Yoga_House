import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:provider/provider.dart';
import 'package:yoga_house/Canellation/cancellation.dart';
import 'package:yoga_house/Canellation/cancellation_card.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/splash_screen.dart';
import 'package:yoga_house/Services/utils_file.dart';
import 'package:yoga_house/User_Info/user_info.dart';

class CancellationHistoryScreen extends StatefulWidget {
  final FirestoreDatabase database;
  final UserInfo userInfo;

  const CancellationHistoryScreen(
      {Key? key, required this.database, required this.userInfo})
      : super(key: key);

  static Future<void> pushToTabBar(
      BuildContext context, UserInfo userInfo) async {
    final database = context.read<FirestoreDatabase>();
    await pushNewScreen(
      context,
      screen: CancellationHistoryScreen(
        database: database,
        userInfo: userInfo,
      ),
    );
  }

  @override
  _CancellationHistoryScreenState createState() =>
      _CancellationHistoryScreenState();
}

class _CancellationHistoryScreenState extends State<CancellationHistoryScreen> {
  late Future<List<Cancellation>> cancellationsFuture;

  @override
  void initState() {
    cancellationsFuture =
        widget.database.cancellationsFuture(widget.userInfo.uid);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Utils.appBarTitle(context, 'היסטוריית ביטולים')),
      body: FutureBuilder<List<Cancellation>>(
          future: cancellationsFuture,
          builder: (context, snapshot) {
            if (Utils.connectionStateInvalid(snapshot)) {
              return const SplashScreen();
            }
            final cancellations = snapshot.data;
            if (cancellations == null) return const SplashScreen();
            if (cancellations.isEmpty) {
              return const Center(
                  child: Text('טרם נרשמו ביטולים עבור לקוח זה'));
            }
            return ListView(
              children: _cancellationCards(cancellations),
            );
          }),
    );
  }

  List<Widget> _cancellationCards(List<Cancellation> cancellations) {
    final cards = <CancellationCard>[];
    for (var cancellation in cancellations) {
      cards.add(CancellationCard(cancellation: cancellation));
    }
    return cards;
  }
}
