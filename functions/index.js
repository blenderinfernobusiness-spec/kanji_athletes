// CORS proxy + shared cache for Tatoeba example sentences.
//
// The web build can't call Tatoeba's API directly: it sends no
// Access-Control-Allow-Origin header, so browsers block reading the
// response (confirmed via a manual curl check - Windows/Android aren't
// affected since CORS is a browser-only restriction). Server-to-server
// requests aren't subject to CORS, so this function does the fetch here
// instead and hands the result back with its own CORS headers.
//
// It also owns the vulgar-tag + keyword filtering that used to live in
// lib/tatoeba_service.dart, and caches each word's filtered result in
// Firestore (no sign-in required, no expiry - mirrors the app's own local
// cache's lack of a TTL) so repeat lookups of the same word, even from
// different members, don't need to hit Tatoeba again.
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// Deliberately focused on clearly explicit content rather than mild
// profanity, to avoid over-blocking ordinary sentences - kept in sync with
// the list this replaced in lib/tatoeba_service.dart.
const BLOCKED_KEYWORDS = [
  "masturbat", "orgasm", "ejaculat", "penis", "vagina", "porn", "fetish",
  "furry", "furries", "bestiality", "incest", "pedophil", "rape", "nude",
  "naked", "boob", "nipple", "genital", "erotic", "horny", "fuck", "blowjob",
  "cock", "pussy", "kinky", "bdsm",
];

// Only a handful of Japanese sentences carry this tag, so refreshing it
// once a day per warm instance is plenty - see lib/tatoeba_service.dart's
// equivalent (now-removed) comment for why the tag alone is grossly
// insufficient on its own and the keyword list is the real defense.
let vulgarIdsCache = null;
let vulgarIdsCacheTime = 0;
const VULGAR_IDS_TTL_MS = 24 * 60 * 60 * 1000;

async function getVulgarIds() {
  if (vulgarIdsCache && Date.now() - vulgarIdsCacheTime < VULGAR_IDS_TTL_MS) {
    return vulgarIdsCache;
  }
  try {
    const res = await fetch(
      "https://tatoeba.org/en/api_v0/search?from=jpn&tags=vulgar&limit=100",
      { headers: { Accept: "application/json" } }
    );
    const json = await res.json();
    const ids = new Set((json.results || []).map((r) => r.id));
    vulgarIdsCache = ids;
    vulgarIdsCacheTime = Date.now();
    return ids;
  } catch (_) {
    return vulgarIdsCache || new Set();
  }
}

function isFlagged(text, translation, id, vulgarIds) {
  if (id != null && vulgarIds.has(id)) return true;
  const haystack = `${text} ${translation || ""}`.toLowerCase();
  return BLOCKED_KEYWORDS.some((k) => haystack.includes(k));
}

function shuffle(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

async function fetchAndFilter(word) {
  const uri = `https://tatoeba.org/en/api_v0/search?from=jpn&query=${encodeURIComponent(word)}&limit=30`;
  const response = await fetch(uri, { headers: { Accept: "application/json" } });
  if (!response.ok) throw new Error(`Tatoeba responded ${response.status}`);
  const decoded = await response.json();
  const results = decoded.results || [];
  const vulgarIds = await getVulgarIds();

  const seen = new Set();
  const entries = [];
  for (const r of results) {
    const text = (r.text || "").trim();
    if (!text || seen.has(text)) continue;
    seen.add(text);

    let translation = null;
    outer: for (const group of r.translations || []) {
      if (!Array.isArray(group)) continue;
      for (const t of group) {
        if (t.lang === "eng") {
          const tText = (t.text || "").trim();
          if (tText) {
            translation = tText;
            break outer;
          }
        }
      }
    }

    if (isFlagged(text, translation, r.id, vulgarIds)) continue;

    entries.push({
      id: r.id ?? null,
      text,
      translation,
      username: r.user?.username ?? null,
      license: r.license ?? null,
    });
  }

  const lowerWord = word.toLowerCase();
  const matching = entries.filter((e) => e.text.toLowerCase().includes(lowerWord));
  const pool = matching.length ? matching : entries;
  return shuffle(pool).slice(0, 10);
}

exports.tatoebaSentences = onRequest({ cors: true }, async (req, res) => {
  const word = (req.query.word || "").toString().trim();
  if (!word) {
    res.status(400).json({ error: "missing word query param" });
    return;
  }

  const cacheRef = db.collection("tatoebaCache").doc(word);
  try {
    const cached = await cacheRef.get();
    // Empty entries were cached by an earlier version whenever Tatoeba failed,
    // so they're treated as a miss and refetched rather than trusted.
    if (cached.exists && cached.data().sentences?.length) {
      res.json(cached.data().sentences);
      return;
    }
  } catch (e) {
    // Firestore hiccup - fall through and serve a live (uncached) fetch
    // rather than failing the whole request.
  }

  try {
    const sentences = await fetchAndFilter(word);
    if (sentences.length) {
      cacheRef.set({ sentences, cachedAt: new Date().toISOString() }).catch(() => {});
    }
    res.json(sentences);
  } catch (e) {
    res.status(502).json({ error: "fetch failed", details: String(e) });
  }
});
