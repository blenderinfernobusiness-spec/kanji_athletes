import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Email/password auth + a single-file backup/restore in Firebase Storage —
// deliberately not Google Sign-In, since that needs a separate, clunkier
// OAuth flow on Windows desktop (no native google_sign_in support there);
// email/password is the one sign-in path that behaves identically on
// Android, Windows, and Web. A plain Storage file (rather than Firestore
// documents) is used because the export is already a single JSON string,
// and Firestore's 1MB-per-document cap is a real risk given how large this
// app's exported data already is.
class CloudSyncService {
  CloudSyncService._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signUp({required String email, required String password}) async {
    await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<void> signOut() => _auth.signOut();

  static Reference _backupRef(String uid) => FirebaseStorage.instance.ref('backups/$uid/export.json');

  // Uploads [content] (the same string produced for local export) as this
  // account's single backup file, replacing whatever was there before -
  // "last save wins" across every signed-in device, matching the export
  // format's own replace-not-merge semantics.
  static Future<void> uploadBackup(String content) async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    final bytes = Uint8List.fromList(utf8.encode(content));
    await _backupRef(user.uid).putData(bytes, SettableMetadata(contentType: 'application/json'));
  }

  // Downloads this account's backup file content, or null if none exists yet.
  static Future<String?> downloadBackup() async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    try {
      final bytes = await _backupRef(user.uid).getData(20 * 1024 * 1024); // 20MB cap, well above any real export
      if (bytes == null) return null;
      return utf8.decode(bytes);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  // Last-modified time of the stored backup, or null if none exists yet -
  // shown in the UI so a restore isn't a total guess about what you're pulling.
  static Future<DateTime?> lastBackupTime() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final meta = await _backupRef(user.uid).getMetadata();
      return meta.updated;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  // Permanently deletes this account's cloud backup file and its Auth
  // credentials, satisfying GDPR's "right to be forgotten" on demand rather
  // than via a retention-period cron job. Firebase requires a *recent*
  // sign-in to delete an account; if that's not the case, this throws the
  // same FirebaseAuthException (code 'requires-recent-login') Auth itself
  // would throw, and the caller should ask the user to sign out and back in.
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in');
    try {
      await _backupRef(user.uid).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
    await user.delete();
  }
}
