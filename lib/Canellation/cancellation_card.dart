import 'package:flutter/material.dart';
import 'package:yoga_house/Services/utils_file.dart';

import 'cancellation.dart';

class CancellationCard extends StatelessWidget {
  final Cancellation cancellation;

  const CancellationCard({Key? key, required this.cancellation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = cancellation.practice.name;
    final date =
        Utils.numericDayMonthYearFromDateTime(cancellation.practiceWasOn);
    final enoughTime = cancellation.isEnoughTimeInAdvance
        ? 'התבקש מספיק זמן מראש. קיבל זיכוי.'
        : 'לא התבקש מספיק זמן מראש. לא קיבל זיכוי.';
    final requestedHoursInAdvance = cancellation.practice.startTime
        .difference(cancellation.requestedOn)
        .inHours;
    return ListTile(
      title: Text('$title, $date'),
      subtitle:
          Text('התבקש $requestedHoursInAdvance שעות לפני השיעור.\n$enoughTime'),
      leading: const Icon(Icons.more_vert_rounded),
      trailing: _trailingIcon(context),
    );
  }

  Widget _trailingIcon(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    if (cancellation.isEnoughTimeInAdvance) {
      return Icon(
        Icons.check,
        color: color,
      );
    } else {
      return const Icon(Icons.maximize);
    }
  }
}
