import 'package:flutter/material.dart';

class ColorsDisplayScreen extends StatelessWidget {
  const ColorsDisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final purp = Colors.purple[200];
    final pink = Colors.deepOrange[50];
    final cyan = Colors.teal[200];
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'כותרת',
            style: TextStyle(color: purp),
          ),
          backgroundColor: pink,
          actions: [
            TextButton(
                onPressed: () {},
                child: Text('התנתק', style: TextStyle(color: cyan))),
          ],
        ),
        body: Center(
          child: Column(
            children: [
              // Container(
              //   color: Colors.deepOrange[50],
              //   height: 50,
              //   width: double.infinity,
              //   child: const Text('background'),
              // ),
              // Container(
              //   color: cyan,
              //   width: double.infinity,
              //   height: 50,
              //   child: const Text(
              //     'error',
              //   ),
              // ),
              // // ElevatedButton(onPressed: () {}, child: Text('Ayo')),
              // TextButton(
              //     onPressed: () {},
              //     child: Text(
              //       'Ayo',
              //       style: TextStyle(color: purp),
              //     )),
              ListTile(
                leading: Icon(Icons.textsms_outlined, color: purp),
                title: Text(
                  'דוגמא דוגמא',
                  style: TextStyle(color: purp),
                ),
              ),
              // Container(
              //   color: Colors.cyanAccent[100],
              //   width: double.infinity,
              //   height: 50,
              //   child: const Text('onBackground'),
              // ),
              // Container(
              //   height: 50,
              //   color: scheme.background,
              //   width: double.infinity,
              //   child: const Text('background'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.error,
              //   child: const Text('error'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.onBackground,
              //   child: const Text('onBackground'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.onError,
              //   child: const Text('onError'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.onPrimary,
              //   child: const Text('onPrimary'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.onSecondary,
              //   child: const Text('onSecondary'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.onSurface,
              //   child: const Text('onSurface'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.primary,
              //   child: const Text('primary'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.primaryVariant,
              //   child: const Text('primaryVariant'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.secondary,
              //   child: const Text('secondary'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.secondaryVariant,
              //   child: const Text('secondaryVariant'),
              // ),
              // Container(
              //   width: double.infinity,
              //   height: 50,
              //   color: scheme.surface,
              //   child: const Text('surface'),
              // ),
            ],
          ),
        ));
  }
}
