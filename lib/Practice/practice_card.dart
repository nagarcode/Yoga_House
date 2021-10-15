import 'package:flutter/material.dart';
import 'package:yoga_house/Services/database.dart';
import 'package:yoga_house/Services/utils_file.dart';

import 'practice.dart';

class PracticeCard extends StatefulWidget {
  final Practice data;
  final bool isRegistered;
  final bool isInWaitingList;
  final Function registerCallback;
  final Function unregisterCallback;
  final Function waitingListCallback;
  final bool managerView;
  final FirestoreDatabase database;
  final bool isHistory;

  const PracticeCard({
    Key? key,
    required this.data,
    required this.isRegistered,
    required this.registerCallback,
    required this.unregisterCallback,
    required this.waitingListCallback,
    required this.managerView,
    required this.database,
    required this.isHistory,
    required this.isInWaitingList,
  }) : super(key: key);

  @override
  State<PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<PracticeCard> {
  bool expand = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final hour = Utils.hourFromDateTime(widget.data.startTime);
    final durationMinutes =
        widget.data.endTime.difference(widget.data.startTime).inMinutes;
    final text =
        '$durationMinutes דקות\nרמה: ${widget.data.level}\nמיקום: ${widget.data.location}';

    return ListTile(
      leading: IconButton(
          icon: const Icon(Icons.more_vert),
          color: theme.colorScheme.primary,
          onPressed: widget.managerView && !widget.isHistory
              ? () => widget.data.onTap(context, widget.database)
              : null),
      title: RichText(
        text: TextSpan(
          text: hour + '\n',
          style:
              theme.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.bold),
          children: <TextSpan>[
            TextSpan(text: widget.data.name, style: theme.textTheme.subtitle1),
          ],
        ),
      ),
      trailing: _trailing(theme),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (expand && widget.managerView) _usersListView(),
          if (expand && !widget.managerView) descriptionView(),
        ],
      ),
      onTap: _toggleExpand,
    );
  }

  void _toggleExpand() {
    setState(() {
      expand = !expand;
    });
  }

  Widget _trailing(ThemeData theme) {
    final isFull =
        widget.data.maxParticipants == widget.data.numOfRegisteredParticipants;

    final maxParticipants = widget.data.maxParticipants;
    final registered = widget.data.numOfRegisteredParticipants;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // if (!widget.managerView)
        Expanded(
          child: _registerOrWaitingListButton(theme, isFull),
        ),
        _registeredParticipants(registered, maxParticipants, theme, isFull),
      ],
    );
  }

  Widget _registeredParticipants(
      int registered, int maxParticipants, ThemeData theme, bool isFull) {
    final regularStyle =
        theme.textTheme.subtitle1?.copyWith(color: Colors.grey);
    final numbersColor = isFull ? theme.errorColor : Colors.grey;
    return RichText(
      text: TextSpan(
        style: regularStyle,
        children: [
          const TextSpan(text: 'רשומים: '),
          TextSpan(
            text: '$registered/$maxParticipants',
            style: regularStyle!.copyWith(color: numbersColor),
          )
        ],
      ),
    );
  }

  Widget _registerOrWaitingListButton(ThemeData theme, bool isFull) {
    // final registeredStyle =
    //     theme.textTheme.subtitle1?.copyWith(color: theme.colorScheme.primary);
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        onPressed: () {
          if (widget.isRegistered) {
            widget.unregisterCallback();
          } else if (widget.data.isFull()) {
            widget.waitingListCallback();
          } else {
            widget.registerCallback();
          }
        },
        child: Text(
          widget.isRegistered
              ? 'רשום. קליק לביטול'
              : isFull
                  ? widget.isInWaitingList
                      ? 'צא מרשימת המתנה'
                      : 'לרשימת המתנה'
                  : 'הירשם',
          // style:
          //     widget.isRegistered ? registeredStyle : theme.textTheme.subtitle1,
        ),
      ),
    );
  }

  _usersListView() {
    final theme = Theme.of(context);
    final users = widget.data.registeredParticipants;
    final desc = widget.data.description;
    var descText =
        Text(desc, style: theme.textTheme.subtitle1!.copyWith(fontSize: 15));
    const registeredText = Text('רשומים:');
    final rows = <Widget>[descText, registeredText];
    if (users.isEmpty) return Text(desc + '\n' + 'טרם נרשמו מתאמנים לשיעור זה');
    for (var user in users) {
      final tile = ListTile(
        dense: true,
        title: Text('- ' + user.name,
            style: theme.textTheme.subtitle1!.copyWith(fontSize: 15)),
        onTap: () {},
      );
      rows.add(tile);
    }
    return ListView(
      shrinkWrap: true,
      children: rows,
    );
  }

  descriptionView() {
    final theme = Theme.of(context);
    return Text(widget.data.description,
        style: theme.textTheme.subtitle1!.copyWith(fontSize: 15));
  }
}
