import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp();

//Topics:

const appName = 'יוגה האוס';

const adminNotificationsTopic = 'admin_notifications';

const adminTopicUserRegistered =  'user_registered_to_practice';

const adminTopicUserCancelled = 'user_cancelled_practice';

//Database Paths

const userCancelledDatabasePath = 'Admin_Notifications/User_Cancelled_Practice/Notifications/{document=**}';

const userRegisteredDatabasePath = 'Admin_Notifications/User_Registered_To_Practice/Notifications/{document=**}'

const fcm = admin.messaging();

export const sendNewHomepageMsgAlert = functions.firestore
  .document(`Admin_Notifications/{document=**}`)
  .onCreate(async (snapshot) => {
    const message = snapshot.data();
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${appName}`,
        body: `${message.msg}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
      },
    };

    return fcm.sendToTopic(`homepage_messages`, payload);
  });

export const sendAdminNotification = functions.firestore
  .document(`Notifications/Homepage_Messages/Notifications/{document=**}`)
  .onCreate(async (snapshot) => {
    const message = snapshot.data();
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${message.title}`,
        body: `${message.msg}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
      },
    };

    return fcm.sendToTopic(adminNotificationsTopic, payload);
  });


  export const sendClientRegisteredToWorkoutAdminAlert = functions.firestore
  .document(userRegisteredDatabasePath)
  .onCreate(async (snapshot) => {
    const message = snapshot.data();
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${message.title}`,
        body: `${message.msg}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
      },
    };

    return fcm.sendToTopic(adminTopicUserRegistered, payload);
  });

  export const sendClientCancelledWorkoutAdminAlert = functions.firestore
  .document(userCancelledDatabasePath)
  .onCreate(async (snapshot) => {
    const message = snapshot.data();
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${message.title}`,
        body: `${message.msg}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
      },
    };

    return fcm.sendToTopic(adminTopicUserCancelled, payload);
  });
