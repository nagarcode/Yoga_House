import 'package:yoga_house/Services/utils_file.dart';

const serviceGiverID = 'Yuval Giat';

class APIPath {
  static String userInfo(String uid) => 'users/$uid';

  static String userInfoCollection() => 'users';

  static String userFuturePractices(String uid) =>
      '${userInfo(uid)}/Future_Practices';

  static String practiceInUserInfo(String uid, String practiceID) =>
      '${userInfo(uid)}/Future_Practices/$practiceID';

  static String fcmToken(String uid, String fcmToken) =>
      'users/$uid/tokens/$fcmToken'; //NOTE: no prefix

  static String appInfo() => 'App_Info_Collection/app_info';

  static String futurePractices() => 'Practices';

  static String futurePractice(String id) => 'Practices/$id';

  static String pastPractices() => 'Past_Practices';

  static String pastPractice(String id) => 'Past_Practices/$id';

  static String userPunchCardHistoryCollection(String uid) =>
      'users/$uid/Punchcard_History';

  static String userPunchCardFromHistory(String uid, DateTime purchasedOn) =>
      'users/$uid/Punchcard_History/${Utils.idFromPastTime(purchasedOn)}';

  //Assets:
  static String logo() => 'assets/images/cropped_logo.png';

  //FCM topics
  static String homepageTextTopic() => '_homepage_text';

  static String userNotificationsTopic(String uid) => uid.toLowerCase();
}
