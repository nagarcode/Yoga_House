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

  const InfoScreen(this.pageType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // TODO change
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
        break;
      case PageType.clientTerminated:
        return _clientTerminatedText();
      default:
        return _clientTerminatedText();
    }
  }

  Widget _adminTerminatedText() {
    return Text(
      'גישתך לאפליקציה נחסמה אוטומטית. יכולות להיות מספר סיבות לכך - אי תשלום חודשי בזמן, הפרת חוזה יסודית, או סיבה אחרת. לפרטים צרי קשר. שימי לב! כרגע ללקוחות יש גישה כשרגיל לאפליקציה והן יכולות לקבוע תורים, אך במידה ומדובר בהפרת חוזה ולא תסדירי את העניין בתוך שלושה ימי עסקים - גם הגישה ללקוחות תיחסם. פעולה זו היא אוטומטיתץ.',
      textAlign: TextAlign.center,
    );
  }

  Widget _clientTerminatedText() {
    return Text('האפליקציה מושבתת באופן זמני. עמכם הסליחה.');
  }
}

enum PageType { managerTerminated, clientTerminated }
