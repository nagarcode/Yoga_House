import 'package:flutter/material.dart';

class CardSelectionTile extends StatelessWidget {
  final BuildContext context;
  final String titleText;
  final Widget leading;
  final Function(BuildContext context) onTap;

  const CardSelectionTile(
      this.context, this.titleText, this.leading, this.onTap,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(titleText),
      leading: leading,
      onTap: () => onTap(context),
      trailing: const Icon(Icons.arrow_forward_ios_outlined),
    );
  }
}
