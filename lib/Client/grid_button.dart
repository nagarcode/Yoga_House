import 'package:flutter/material.dart';

class GridButton extends StatelessWidget {
  final String text;
  final Function onClick;
  final ThemeData theme;
  final IconData icon;

  const GridButton({
    Key? key,
    required this.text,
    required this.onClick,
    required this.theme,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onClick(),
      child: Card(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: theme.colorScheme.primary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                flex: 2,
                child: Center(
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                )),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 15, color: Colors.white),
                  // style: theme.textTheme.button
                  //     ?.copyWith(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
