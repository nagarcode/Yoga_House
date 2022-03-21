import 'package:yoga_house/Services/utils_file.dart';

const serviceGiverID = 'Yuval_Giat';

class APIPath {
  static String userInfo(String uid) => 'users/$uid';

  static String repeatingPracticesCollection() => 'Repeating_Practices';

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

  static String repeatingPractice(String id) =>
      '${repeatingPracticesCollection()}/$id';

  static String pastPracticesByMonthCollection(DateTime date) {
    String monthYear = Utils.numericMonthYear(date);
    return 'Practices_History/$serviceGiverID/$monthYear';
  }

  // static String pastPracticeSingleDoc(DateTime date) {
  //   final monthYear = Utils.numericMonthYear(date);
  //   return 'Practices_History/$serviceGiverID/History/$monthYear';
  // }
  static String pastPracticeDoc(DateTime startTime, String id) {
    final monthYear = Utils.numericMonthYear(startTime);
    return 'Practices_History/$serviceGiverID/$monthYear/$id';
  }

  static String userPunchCardHistoryCollection(String uid) =>
      'users/$uid/Punchcard_History';

  static String userPunchCardFromHistory(String uid, DateTime purchasedOn) =>
      'users/$uid/Punchcard_History/${Utils.idFromPastTime(purchasedOn)}';

  static String newHealthAssuranceInHistory(String uid) =>
      'users/$uid/Health_Assurance_History/${DateTime.now()}';

  static String newUserCancellation(String uid) =>
      'users/$uid/Cancellation_History/${DateTime.now()}';

  static String userCancellationsCollection(String uid) =>
      'users/$uid/Cancellation_History';

  //Assets:

  static String logo() => 'assets/images/logo.jpeg';

//Notifications:

  static newUserNotification() => 'Client_Notifications/${DateTime.now()}';

  static String newAdminNotification() =>
      'Admin_Notifications/${DateTime.now()}';

  static String adminNotifications() => 'Admin_Notifications';

  // static String newUserCancelledAdminNotification() =>
  //     'Admin_Notifications/User_Cancelled_Practice/Notifications/${DateTime.now()}';

  // static String newUserRegisteredAdminNotification() =>
  //     'Admin_Notifications/User_Registered_To_Practice/Notifications/${DateTime.now()}';

  static String newHomepageMessage() =>
      'Notifications/Homepage_Messages/Notifications/${DateTime.now()}';

  //FCM topics
  static String adminNotificationsTopic() => 'admin_notifications';

  static String clientNotificationsTopic(String uid) => uid.toLowerCase();

  static String homepageTextTopic() => 'homepage_messages';

  static String userNotificationsTopic(String uid) => uid.toLowerCase();

  // static String adminTopicUserRegistered() => 'user_registered_to_practice';

  // static String adminTopicUserCancelled() => 'user_cancelled_practice';
}
