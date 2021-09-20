const serviceGiverID = 'Yuval Giat';

class APIPath {
  static String userInfo(String uid) => 'users/$uid';

  static String fcmToken(String uid, String fcmToken) =>
      'users/$uid/tokens/$fcmToken'; //NOTE: no prefix

  static String appInfo() => 'App_Info_Collection/app_info';

  static String practice(String id) => 'Practices/$id';

  //FCM topics
  static String homepageTextTopic() => '_homepage_text';

  static String userNotificationsTopic(String uid) => uid.toLowerCase();
}
