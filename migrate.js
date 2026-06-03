const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json'); // Download from Firebase Console
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'himsak-63ae0'
});

const db = admin.firestore();
const storage = admin.storage().bucket();

async function migrateUsers() {
  // Read your MySQL export (JSON format)
  const mysqlData = JSON.parse(fs.readFileSync('users_export.json', 'utf8'));

  for (const user of mysqlData) {
    try {
      // 1. Create user in Firebase Auth (if email/password needed)
      // Skip for now or use Admin SDK to create users

      // 2. Upload IC image to Firebase Storage (if you have local images)
      let icImageUrl = user.ic_image_url;
      if (user.ic_image_path && fs.existsSync(user.ic_image_path)) {
        const fileName = `ic_images/${user.id}.png`;
        const file = storage.file(fileName);
        await file.save(fs.readFileSync(user.ic_image_path));
        icImageUrl = `https://firebasestorage.googleapis.com/.../${fileName}`;
      }

      // 3. Save to Firestore
      await db.collection('users').doc(user.id.toString()).set({
        fullName: user.full_name,
        email: user.email,
        status: user.status || 'Pending Verification',
        role: user.role || 'user',
        icImage: icImageUrl,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`✅ Migrated user: ${user.full_name}`);
    } catch (error) {
      console.error(`❌ Error migrating ${user.email}:`, error);
    }
  }

  console.log('🎉 Migration complete!');
  process.exit(0);
}

migrateUsers();