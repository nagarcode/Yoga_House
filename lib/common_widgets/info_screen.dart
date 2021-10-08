import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  final PageType pageType;

  static create(BuildContext context, PageType pageType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => InfoScreen(pageType),
      ),
    );
  }

  const InfoScreen(this.pageType, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: _infoText(),
        ),
      ),
    );
  }

  Widget _infoText() {
    switch (pageType) {
      case PageType.managerTerminated:
        return _adminTerminatedText();
      case PageType.clientTerminated:
        return _clientTerminatedText();
      default:
        return _clientTerminatedText();
    }
  }

  Widget _adminTerminatedText() {
    return const Text(
      'גישתך לאפליקציה נחסמה אוטומטית. יכולות להיות מספר סיבות לכך - אי תשלום חודשי בזמן, הפרת חוזה יסודית, או סיבה אחרת. לפרטים צור קשר. שים לב! כרגע ללקוחות יש גישה כרגיל לאפליקציה והם יכולים לקבוע תורים, אך במידה ומדובר בהפרת חוזה ולא תסדיר את העניין בתוך שלושה ימי עסקים - גם הגישה ללקוחות תיחסם. פעולה זו היא אוטומטית.',
      textAlign: TextAlign.center,
    );
  }

  Widget _clientTerminatedText() {
    return const Text('האפליקציה מושבתת באופן זמני. עמכם הסליחה.');
  }
}

enum PageType { managerTerminated, clientTerminated }
