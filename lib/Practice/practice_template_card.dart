import 'package:flutter/material.dart';
import 'package:yoga_house/Practice/practice_template.dart';

class PracticeTemplateCard extends StatelessWidget {
  final bool isRepeatingPractice;
  final PracticeTemplate data;
  final Function deleteTemplateCallback;
  final bool selectionScreen;
  final Function(PracticeTemplate)? onClicked;
  const PracticeTemplateCard(
    this.data,
    this.deleteTemplateCallback, {
    Key? key,
    this.selectionScreen = false,
    this.onClicked,
    this.isRepeatingPractice = false,
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
    final text =
        'רמה: ${data.level}\nמיקום: ${data.location}\nמשך: ${data.durationMinutes} דקות\nמספר משתתפים מקסימלי: ${data.maxParticipants}\nתאור: ${data.description}';
    if (!selectionScreen) {
      return ListTile(
        title: Text(data.name),
        subtitle: Text(
          text,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever_outlined),
          onPressed: () => deleteTemplateCallback(),
        ),
      );
    } else {
      return ListTile(
        onTap: onClicked != null ? () => onClicked!(data) : () {},
        title: Text(data.name),
        subtitle: Text(text),
      );
    }
  }
}
