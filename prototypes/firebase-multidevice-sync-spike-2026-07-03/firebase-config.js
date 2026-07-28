// PROTOTYPE - NOT FOR PRODUCTION
// Question: Firebase multi-device real-time sync spike
// Date: 2026-07-03
//
// Fill in with a free Firebase project's client config (Project Settings ->
// General -> Your apps -> Web app -> SDK setup and configuration -> Config).
// These values are NOT secret — they identify the project to Firebase's
// client SDK, the same way they'd appear in any shipped web/mobile app.
// Do not use a production project. Create a disposable throwaway project
// for this spike and delete it afterward (or leave it, it's free-tier and
// unused after this test).
//
// Firestore must be enabled (Native mode) in the project, with rules open
// for this spike only, e.g.:
//   rules_version = '2';
//   service cloud.firestore {
//     match /databases/{database}/documents {
//       match /spike/{doc} { allow read, write: if true; }
//     }
//   }
// (Open rules are fine for a throwaway project nobody else knows exists —
// never do this on a real project.)

export const firebaseConfig = {
  apiKey: "AIzaSyDp00dBlj7_eWYLAwCA6T5vaUgKMMcGMNQ",
  authDomain: "pet-quest-39d38.firebaseapp.com",
  projectId: "pet-quest-39d38",
  storageBucket: "pet-quest-39d38.firebasestorage.app",
  messagingSenderId: "417003786612",
  appId: "1:417003786612:web:07427a5bda38b891c01c21"
};
