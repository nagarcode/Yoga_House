import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:yoga_house/Practice/practice_template.dart';

class SharedPrefs {
  final Preference<PracticeTemplate> practiceTemplate1;
  final Preference<PracticeTemplate> practiceTemplate2;
  final Preference<PracticeTemplate> practiceTemplate3;
  final Preference<PracticeTemplate> practiceTemplate4;
  final Preference<bool> adminNotificationClientRegistered;
  final Preference<bool> adminNotificationClientCancelled;

  SharedPrefs(StreamingSharedPreferences prefs)
      : practiceTemplate1 = prefs.getCustomValue(
          'practiceTemplate1',
          defaultValue: PracticeTemplate.empty(),
          adapter: JsonAdapter(
            deserializer: (value) => PracticeTemplate.fromJson(value),
          ),
        ),
        practiceTemplate2 = prefs.getCustomValue(
          'practiceTemplate2',
          defaultValue: PracticeTemplate.empty(),
          adapter: JsonAdapter(
            deserializer: (value) => PracticeTemplate.fromJson(value),
          ),
        ),
        practiceTemplate3 = prefs.getCustomValue(
          'practiceTemplate3',
          defaultValue: PracticeTemplate.empty(),
          adapter: JsonAdapter(
            deserializer: (value) => PracticeTemplate.fromJson(value),
          ),
        ),
        practiceTemplate4 = prefs.getCustomValue(
          'practiceTemplate4',
          defaultValue: PracticeTemplate.empty(),
          adapter: JsonAdapter(
            deserializer: (value) => PracticeTemplate.fromJson(value),
          ),
        ),
        adminNotificationClientCancelled = prefs
            .getBool('adminNotificationClientCancelled', defaultValue: false),
        adminNotificationClientRegistered = prefs
            .getBool('adminNotificationClientRegistered', defaultValue: false);

  void toggleAdminNotificationClientRegistered(bool newVal) async {
    await adminNotificationClientRegistered.setValue(newVal);
  }

  void toggleAdminNotificationClientCancelled(bool newVal) async {
    await adminNotificationClientCancelled.setValue(newVal);
  }

  List<PracticeTemplate> practiceTemplates() {
    return [
      practiceTemplate1.getValue(),
      practiceTemplate2.getValue(),
      practiceTemplate3.getValue(),
      practiceTemplate4.getValue(),
    ];
  }

  List<Preference<PracticeTemplate>> _prefTemplates() {
    return [
      practiceTemplate1,
      practiceTemplate2,
      practiceTemplate3,
      practiceTemplate4,
    ];
  }

  int emptyTemplateIndex() {
    if (practiceTemplate1.getValue().name == '') return 1;
    if (practiceTemplate2.getValue().name == '') return 2;
    if (practiceTemplate3.getValue().name == '') return 3;
    if (practiceTemplate4.getValue().name == '') return 4;

    return 0;
  }

  void deleteTemplate(PracticeTemplate data) {
    for (var template in _prefTemplates()) {
      if (data.id == template.getValue().id) {
        template.clear();
        return;
      }
    }
  }
}
