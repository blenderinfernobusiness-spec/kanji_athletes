// Same Firebase project as the Flutter app (see lib/firebase_options.dart's
// "windows" block, which is shared with Web). No Firebase JS SDK here -
// Manifest V3's script-src 'self' CSP blocks the SDK's own remote-loaded
// pieces, and bundling it would mean a build step for a plain-JS extension.
// Plain REST calls avoid both problems.
const KA_FIREBASE_API_KEY = 'AIzaSyBPsqLHIl7R87qFtaBcplvgwFHCOp-zWFc';
const KA_FIREBASE_PROJECT_ID = 'kanji-athletes';
const KA_FIREBASE_STORAGE_BUCKET = 'kanji-athletes.firebasestorage.app';

const KA_ACCENT_COLOR = '#9A00FE';

// chrome.storage.local keys, shared between popup.js and content.js.
const KA_STORAGE_KEYS = {
  auth: 'kaAuth', // { idToken, refreshToken, uid, email, expiresAt }
  backup: 'kaBackup', // { data: <parsed export.json>, downloadedAt, unsyncedCount }
  settings: 'kaSettings', // { autoPause: bool }
};

function kaBackupObjectPath(uid) {
  return `backups/${uid}/export.json`;
}
