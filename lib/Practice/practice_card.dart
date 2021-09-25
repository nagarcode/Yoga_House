import 'package:flutter/material.dart';
import 'package:yoga_house/Services/utils_file.dart';

import 'practice.dart';

class PracticeCard extends StatelessWidget {
  final Practice data;
  final bool isRegistered;
  final Function registerCallback;
  final Function unregisterCallback;
  final Function waitingListCallback;

  const PracticeCard({
    Key? key,
    required this.data,
    required this.isRegistered,
    required this.registerCallback,
    required this.unregisterCallback,
    required this.waitingListCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final hour = Utils.hourFromDateTime(data.startTime);
    final durationMinutes = data.endTime.difference(data.startTime).inMinutes;
    final text =
        '$durationMinutes דקות\nרמה: ${data.level}\nמיקום: ${data.location}';

    return ListTile(
      leading: Icon(Icons.more_vert, color: theme.colorScheme.primary),
      title: Text('$hour\n${data.name}'),
      trailing: _trailing(theme),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(text)],
      ),
    );
  }

  Widget _trailing(ThemeData theme) {
    final isFull = data.maxParticipants == data.numOfRegisteredParticipants;

    final maxParticipants = data.maxParticipants;
    final registered = data.numOfRegisteredParticipants;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  TextButton _registerOrWaitingListButton(ThemeData theme, bool isFull) {
    final registeredStyle =
        theme.textTheme.subtitle1?.copyWith(color: theme.colorScheme.primary);
    return TextButton(
      onPressed: () {
        if (isRegistered) {
          unregisterCallback();
        } else if (data.isFull()) {
          waitingListCallback();
        } else {
          registerCallback();
        }
      },
      child: Text(
        isRegistered
            ? 'רשום. לחץ לביטול רישום'
            : isFull
                ? 'לרשימת המתנה'
                : 'הירשם',
        style: isRegistered ? registeredStyle : theme.textTheme.subtitle1,
      ),
    );
  }
}
