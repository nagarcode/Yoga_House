import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String msg;
  final void Function()? onTap;
  Color? color;

  CustomButton({Key? key, required this.msg, required this.onTap, Color? color})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    offset: const Offset(2, 1),
                    blurRadius: 2)
              ],
              color: color ?? Colors.white,
              borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  msg,
                  style: theme.textTheme.button,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
