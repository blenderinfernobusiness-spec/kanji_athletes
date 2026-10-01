// Same email/password account system as the app's Cloud Backup
// (lib/cloud_sync_service.dart), reimplemented over Firebase's REST APIs
// instead of the JS SDK - see config.js's comment for why.

const els = {
  signedOutView: document.getElementById('signedOutView'),
  signedInView: document.getElementById('signedInView'),
  formTitle: document.getElementById('formTitle'),
  emailInput: document.getElementById('emailInput'),
  passwordInput: document.getElementById('passwordInput'),
  authError: document.getElementById('authError'),
  submitAuthBtn: document.getElementById('submitAuthBtn'),
  toggleModeBtn: document.getElementById('toggleModeBtn'),
  accountEmail: document.getElementById('accountEmail'),
  signOutBtn: document.getElementById('signOutBtn'),
  backupStatus: document.getElementById('backupStatus'),
  downloadBtn: document.getElementById('downloadBtn'),
  syncBtn: document.getElementById('syncBtn'),
  syncHint: document.getElementById('syncHint'),
  autoPauseToggle: document.getElementById('autoPauseToggle'),
  opStatus: document.getElementById('opStatus'),
};

let isCreatingAccount = false;

function storageGet(key) {
  return new Promise((resolve) => chrome.storage.local.get(key, (result) => resolve(result[key])));
}

function storageSet(obj) {
  return new Promise((resolve) => chrome.storage.local.set(obj, resolve));
}

function storageRemove(key) {
  return new Promise((resolve) => chrome.storage.local.remove(key, resolve));
}

function setOpStatus(text) {
  els.opStatus.textContent = text || '';
}

// --- Auth ---

async function signUpOrIn(email, password) {
  const endpoint = isCreatingAccount ? 'signUp' : 'signInWithPassword';
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${KA_FIREBASE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  const json = await res.json();
  if (!res.ok) throw new Error(json.error?.message || 'Authentication failed');
  const expiresAt = Date.now() + Number(json.expiresIn) * 1000;
  await storageSet({
    [KA_STORAGE_KEYS.auth]: {
      idToken: json.idToken,
      refreshToken: json.refreshToken,
      uid: json.localId,
      email: json.email,
      expiresAt,
    },
  });
}

async function refreshIdTokenIfNeeded(auth) {
  if (Date.now() < auth.expiresAt - 60000) return auth; // still valid for at least a minute
  const res = await fetch(`https://securetoken.googleapis.com/v1/token?key=${KA_FIREBASE_API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=refresh_token&refresh_token=${encodeURIComponent(auth.refreshToken)}`,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(json.error?.message || 'Session expired, please sign in again');
  const updated = {
    ...auth,
    idToken: json.id_token,
    refreshToken: json.refresh_token,
    expiresAt: Date.now() + Number(json.expires_in) * 1000,
  };
  await storageSet({ [KA_STORAGE_KEYS.auth]: updated });
  return updated;
}

async function signOut() {
  await storageRemove(KA_STORAGE_KEYS.auth);
  await storageRemove(KA_STORAGE_KEYS.backup);
  render();
}

// --- Storage (backup file) ---

async function downloadBackup() {
  setOpStatus('Downloading…');
  try {
    let auth = await storageGet(KA_STORAGE_KEYS.auth);
    auth = await refreshIdTokenIfNeeded(auth);
    const path = encodeURIComponent(kaBackupObjectPath(auth.uid));
    const res = await fetch(
      `https://firebasestorage.googleapis.com/v0/b/${KA_FIREBASE_STORAGE_BUCKET}/o/${path}?alt=media`,
      { headers: { Authorization: `Bearer ${auth.idToken}` } }
    );
    if (res.status === 404) {
      setOpStatus('No backup found for this account yet - upload one from the app first.');
      return;
    }
    if (!res.ok) throw new Error(`Download failed (${res.status})`);
    const data = await res.json();
    await storageSet({
      [KA_STORAGE_KEYS.backup]: { data, downloadedAt: new Date().toISOString(), unsyncedCount: 0 },
    });
    setOpStatus('Downloaded.');
  } catch (e) {
    setOpStatus(`Download failed: ${e.message}`);
  } finally {
    render();
  }
}

async function uploadBackup() {
  setOpStatus('Syncing…');
  try {
    let auth = await storageGet(KA_STORAGE_KEYS.auth);
    auth = await refreshIdTokenIfNeeded(auth);
    const backup = await storageGet(KA_STORAGE_KEYS.backup);
    if (!backup) throw new Error('Nothing to sync yet');
    const path = encodeURIComponent(kaBackupObjectPath(auth.uid));
    const res = await fetch(
      `https://firebasestorage.googleapis.com/v0/b/${KA_FIREBASE_STORAGE_BUCKET}/o?uploadType=media&name=${path}`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${auth.idToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(backup.data),
      }
    );
    if (!res.ok) throw new Error(`Upload failed (${res.status})`);
    await storageSet({ [KA_STORAGE_KEYS.backup]: { ...backup, unsyncedCount: 0 } });
    setOpStatus('Synced to cloud.');
  } catch (e) {
    setOpStatus(`Sync failed: ${e.message}`);
  } finally {
    render();
  }
}

// --- Rendering ---

async function render() {
  const auth = await storageGet(KA_STORAGE_KEYS.auth);
  if (!auth) {
    els.signedOutView.classList.remove('hidden');
    els.signedInView.classList.add('hidden');
    return;
  }
  els.signedOutView.classList.add('hidden');
  els.signedInView.classList.remove('hidden');
  els.accountEmail.textContent = auth.email;

  const backup = await storageGet(KA_STORAGE_KEYS.backup);
  if (backup) {
    const when = new Date(backup.downloadedAt).toLocaleString();
    const deckCount = Array.isArray(backup.data?.studyDecks) ? backup.data.studyDecks.length : 0;
    els.backupStatus.textContent = `Downloaded ${deckCount} deck(s) - ${when}`;
    els.syncHint.classList.add('hidden');
    els.syncBtn.disabled = !backup.unsyncedCount;
    els.syncBtn.textContent = backup.unsyncedCount
      ? `Sync ${backup.unsyncedCount} change(s) to cloud`
      : 'Sync changes to cloud';
  } else {
    els.backupStatus.textContent = 'Not downloaded yet.';
    els.syncHint.classList.remove('hidden');
    els.syncBtn.disabled = true;
  }

  const settings = (await storageGet(KA_STORAGE_KEYS.settings)) || { autoPause: true };
  els.autoPauseToggle.checked = settings.autoPause !== false;
}

function updateFormMode() {
  els.formTitle.textContent = isCreatingAccount ? 'Create an account' : 'Sign in';
  els.submitAuthBtn.textContent = isCreatingAccount ? 'Create account' : 'Sign in';
  els.toggleModeBtn.textContent = isCreatingAccount
    ? 'Already have an account? Sign in'
    : "Don't have an account? Create one";
}

// --- Wiring ---

els.toggleModeBtn.addEventListener('click', () => {
  isCreatingAccount = !isCreatingAccount;
  updateFormMode();
});

els.submitAuthBtn.addEventListener('click', async () => {
  const email = els.emailInput.value.trim();
  const password = els.passwordInput.value;
  els.authError.classList.add('hidden');
  if (!email || !password) {
    els.authError.textContent = 'Enter an email and password';
    els.authError.classList.remove('hidden');
    return;
  }
  els.submitAuthBtn.disabled = true;
  try {
    await signUpOrIn(email, password);
    await render();
  } catch (e) {
    els.authError.textContent = e.message;
    els.authError.classList.remove('hidden');
  } finally {
    els.submitAuthBtn.disabled = false;
  }
});

els.signOutBtn.addEventListener('click', signOut);
els.downloadBtn.addEventListener('click', downloadBackup);
els.syncBtn.addEventListener('click', uploadBackup);

els.autoPauseToggle.addEventListener('change', async () => {
  await storageSet({ [KA_STORAGE_KEYS.settings]: { autoPause: els.autoPauseToggle.checked } });
});

updateFormMode();
render();
