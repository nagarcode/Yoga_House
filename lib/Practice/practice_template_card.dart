import 'package:flutter/material.dart';
import 'package:yoga_house/Practice/practice_template.dart';

class PracticeTemplateCard extends StatelessWidget {
  final PracticeTemplate data;
  const PracticeTemplateCard(this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView(
        shrinkWrap: true,
        children: _buildCard(context),
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }

  List<Widget> _buildCard(BuildContext context) {
    return [
      Text(data.name),
      Text(data.description),
      Text(data.level.toString())
    ];
  }
}
