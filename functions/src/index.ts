import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
admin.initializeApp();

//Topics:

const appName = 'יוגה האוס';

const adminNotificationsTopic = 'admin_notifications';

// const adminTopicUserRegistered =  'user_registered_to_practice';

// const adminTopicUserCancelled = 'user_cancelled_practice';

const homepageMessagesTopic = 'homepage_messages';


//Database Paths

// const clientCancelledDatabasePath = 'Admin_Notifications/User_Cancelled_Practice/Notifications/{document=**}';

// const clientRegisteredDatabasePath = 'Admin_Notifications/User_Registered_To_Practice/Notifications/{document=**}'

const homepageMessagesPath = 'Notifications/Homepage_Messages/Notifications/{document=**}'

const clientNotificationsPath = 'Client_Notifications/{document=**}';

const adminNotificationsPath = 'Admin_Notifications/{document=**}';


const fcm = admin.messaging();

export const sendNewHomepageMsgAlert = functions.firestore
  .document(homepageMessagesPath)
  .onCreate(async (snapshot) => {
    const message = snapshot.data();
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${appName}`,
        body: `${message.msg}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
      },
    };
    return fcm.sendToTopic(homepageMessagesTopic, payload);
  });

export const sendAdminNotification = functions.firestore
  .document(adminNotificationsPath)
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

export const sendClientNotification = functions.firestore
  .document(clientNotificationsPath)
  .onCreate(async (snapshot) => {
    const message = snapshot.data();
    const payload: admin.messaging.MessagingPayload = {
      notification: {
        title: `${message.title}`,
        body: `${message.msg}`,
        click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
      },
    };

    return fcm.sendToTopic(message.targetUserNotificationTopic, payload);
  });


  // export const sendClientRegisteredToWorkoutAdminAlert = functions.firestore
  // .document(clientRegisteredDatabasePath)
  // .onCreate(async (snapshot) => {
  //   const message = snapshot.data();
  //   const payload: admin.messaging.MessagingPayload = {
  //     notification: {
  //       title: `${message.title}`,
  //       body: `${message.msg}`,
  //       click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
  //     },
  //   };

  //   return fcm.sendToTopic(adminTopicUserRegistered, payload);
  // });

  // export const sendClientCancelledWorkoutAdminAlert = functions.firestore
  // .document(clientCancelledDatabasePath)
  // .onCreate(async (snapshot) => {
  //   const message = snapshot.data();
  //   const payload: admin.messaging.MessagingPayload = {
  //     notification: {
  //       title: `${message.title}`,
  //       body: `${message.msg}`,
  //       click_action: "FLUTTER_NOTIFICATION_CLICK", // required only for onResume or onLaunch callbacks
  //     },
  //   };

  //   return fcm.sendToTopic(adminTopicUserCancelled, payload);
  // });
