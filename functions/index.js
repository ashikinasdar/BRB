const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Sends a notification to topic 'announcements' when a new announcement is created
exports.sendAnnouncementNotification = functions.firestore
  .document('announcements/{announcementId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const title = data.title || 'New Announcement';
    const body = data.body || '';

    const message = {
      notification: { title: title, body: body },
      topic: 'announcements',
      webpush: {
        fcmOptions: { link: '/' }
      }
    };

    try {
      const resp = await admin.messaging().send(message);
      console.log('Sent notification:', resp);
    } catch (err) {
      console.error('Error sending notification', err);
    }
  });
