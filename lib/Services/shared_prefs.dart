import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:yoga_house/Practice/practice.dart';
import 'package:yoga_house/Practice/practice_template.dart';

class SharedPrefs {
  final Preference<PracticeTemplate> practiceTemplate1;

  SharedPrefs(StreamingSharedPreferences prefs)
      : practiceTemplate1 = prefs.getCustomValue(
          'practiceTemplate1',
          defaultValue: PracticeTemplate.empty(),
          adapter: JsonAdapter(
            deserializer: (value) => PracticeTemplate.fromJson(value),
          ),
        );
  // final Preference<String> id1;
  // final Preference<String> name1;
  // final Preference<String> description1;
  // final Preference<int> level1;
  // final Preference<String> id2;
  // final Preference<String> name2;
  // final Preference<String> description2;
  // final Preference<int> level2;
  // final Preference<String> id3;
  // final Preference<String> name3;
  // final Preference<String> description3;
  // final Preference<int> level3;
  // final Preference<String> id4;
  // final Preference<String> name4;
  // final Preference<String> description4;
  // final Preference<int> level4;
  // final Preference<String> id5;
  // final Preference<String> name5;
  // final Preference<String> description5;
  // final Preference<int> level5;
  // SharedPrefs(StreamingSharedPreferences preferences)
  //     : id1 = preferences.getString('id1', defaultValue: ''),
  //       name1 = preferences.getString('name1', defaultValue: ''),
  //       description1 = preferences.getString('description1', defaultValue: ''),
  //       level1 = preferences.getInt('level1', defaultValue: -1),
  //       id2 = preferences.getString('id2', defaultValue: ''),
  //       name2 = preferences.getString('name2', defaultValue: ''),
  //       description2 = preferences.getString('description2', defaultValue: ''),
  //       level2 = preferences.getInt('level2', defaultValue: -1),
  //       id3 = preferences.getString('id3', defaultValue: ''),
  //       name3 = preferences.getString('name3', defaultValue: ''),
  //       description3 = preferences.getString('description3', defaultValue: ''),
  //       level3 = preferences.getInt('level3', defaultValue: -1),
  //       id4 = preferences.getString('id4', defaultValue: ''),
  //       name4 = preferences.getString('name4', defaultValue: ''),
  //       description4 = preferences.getString('description4', defaultValue: ''),
  //       level4 = preferences.getInt('level4', defaultValue: -1),
  //       id5 = preferences.getString('id5', defaultValue: ''),
  //       name5 = preferences.getString('name5', defaultValue: ''),
  //       description5 = preferences.getString('description5', defaultValue: ''),
  //       level5 = preferences.getInt('level5', defaultValue: -1);

  // PracticeTemplate getPracticeTemplate1() {
  //   return PracticeTemplate(id1.getValue(), name1.getValue(),
  //       description1.getValue(), Practice.intToLevel(level1.getValue()));
  // }

  // PracticeTemplate getPracticeTemplate2() {
  //   return PracticeTemplate(id2.getValue(), name2.getValue(),
  //       description2.getValue(), Practice.intToLevel(level2.getValue()));
  // }

  // PracticeTemplate getPracticeTemplate3() {
  //   return PracticeTemplate(id3.getValue(), name3.getValue(),
  //       description3.getValue(), Practice.intToLevel(level3.getValue()));
  // }

  // PracticeTemplate getPracticeTemplate4() {
  //   return PracticeTemplate(id4.getValue(), name4.getValue(),
  //       description4.getValue(), Practice.intToLevel(level4.getValue()));
  // }

  // PracticeTemplate getPracticeTemplate5() {
  //   return PracticeTemplate(id5.getValue(), name5.getValue(),
  //       description5.getValue(), Practice.intToLevel(level5.getValue()));
  // }
}
