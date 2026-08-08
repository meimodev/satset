#!/usr/bin/env node
// Publishes the release gate (ADR-0087) from a git tag.
//
//   node tool/publish_release_gate.mjs v1.2.0-breaking
//
// Reads the service-account JSON from $FIREBASE_SERVICE_ACCOUNT — the same
// secret Codemagic already injects for App Distribution — mints an access token
// and PATCHes `config/release_gate` over the Firestore REST API. A service
// account bypasses firestore.rules, which is why the rules deny every client
// write.
//
// ponytail: no npm dependency. firebase-admin would be a package install in CI
// for one document write; node:crypto signs the RS256 assertion and fetch is
// global from Node 18. If this ever needs a second call, revisit.
//
// Run LAST in the workflow, after `gh release create` succeeds. A floor that
// rises while the APK is still uploading points the fleet at a download that
// does not exist yet, and there is no recovery for that inside the app.

import crypto from "node:crypto";

const FIELDS = ["min", "recommended", "latest"];
const SEMVER_RE = /^\d+\.\d+\.\d+$/;

/** `v1.2.0-breaking` → `{ version: "1.2.0", severity: "breaking" }`. */
function parseTag(tag) {
  const t = String(tag || "").trim().replace(/^v/, "");
  const [version, severity = "plain"] = t.split("-");
  if (!SEMVER_RE.test(version)) {
    throw new Error(`Tag "${tag}" is not v<MAJOR>.<MINOR>.<PATCH>[-severity].`);
  }
  if (!["plain", "recommended", "breaking"].includes(severity)) {
    throw new Error(`Unknown severity "${severity}" in tag "${tag}".`);
  }
  return { version, severity };
}

/**
 * The cascade. `-breaking` sets all three, `-recommended` sets two, a plain tag
 * sets only `latest`; untouched floors keep whatever they held. This is where
 * `min <= recommended <= latest` is guaranteed — the readers never check it.
 */
function cascade(prev, { version, severity }) {
  return {
    latest: version,
    recommended: severity === "plain" ? prev.recommended ?? null : version,
    min: severity === "breaking" ? version : prev.min ?? null,
  };
}

async function accessToken(sa) {
  const now = Math.floor(Date.now() / 1000);
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const unsigned = `${b64({ alg: "RS256", typ: "JWT" })}.${b64(claim)}`;
  const sig = crypto
    .createSign("RSA-SHA256")
    .update(unsigned)
    .sign(sa.private_key)
    .toString("base64url");

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${sig}`,
    }),
  });
  if (!res.ok) throw new Error(`token exchange ${res.status}: ${await res.text()}`);
  return (await res.json()).access_token;
}

const toFields = (o) =>
  Object.fromEntries(
    Object.entries(o).map(([k, v]) => [k, v == null ? { nullValue: null } : { stringValue: v }]),
  );

const fromFields = (f = {}) =>
  Object.fromEntries(FIELDS.map((k) => [k, f[k]?.stringValue ?? null]));

async function main() {
  const tag = process.argv[2] || process.env.CM_TAG;
  const parsed = parseTag(tag);

  const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT || "");
  const token = await accessToken(sa);
  const base = `https://firestore.googleapis.com/v1/projects/${sa.project_id}/databases/(default)/documents/config/release_gate`;
  const headers = { authorization: `Bearer ${token}`, "content-type": "application/json" };

  // Read-modify-write rather than three independent field writes: a plain tag
  // must leave an existing `min` standing, and the merge has to see it.
  const got = await fetch(base, { headers });
  const prev = got.ok ? fromFields((await got.json()).fields) : {};
  const next = cascade(prev, parsed);

  // updatedBy names CI so the fleet audit's "who moved this" question has an
  // answer for both writers. The console override stamps a uid here instead.
  const body = {
    fields: {
      ...toFields(next),
      updatedAt: { timestampValue: new Date().toISOString() },
      updatedBy: { stringValue: `ci:${tag}` },
    },
  };
  const mask = [...FIELDS, "updatedAt", "updatedBy"]
    .map((f) => `updateMask.fieldPaths=${f}`)
    .join("&");

  const res = await fetch(`${base}?${mask}`, { method: "PATCH", headers, body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`firestore PATCH ${res.status}: ${await res.text()}`);

  console.log(`release gate ← ${JSON.stringify(next)} (from ${tag})`);
}

// Self-check: `node tool/publish_release_gate.mjs --selftest` exercises the two
// pure functions without touching the network or needing a service account.
if (process.argv[2] === "--selftest") {
  const assert = (c, m) => {
    if (!c) throw new Error(`selftest: ${m}`);
  };
  assert(parseTag("v1.2.0").severity === "plain", "plain tag");
  assert(parseTag("v1.2.0-breaking").version === "1.2.0", "breaking version");
  let e = null;
  try {
    parseTag("v1.2");
  } catch (err) {
    e = err;
  }
  assert(e, "short version rejected");
  e = null;
  try {
    parseTag("v1.2.0-urgent");
  } catch (err) {
    e = err;
  }
  assert(e, "unknown severity rejected");

  const prev = { min: "1.0.0", recommended: "1.1.0", latest: "1.1.0" };
  assert(
    JSON.stringify(cascade(prev, parseTag("v1.2.0"))) ===
      JSON.stringify({ latest: "1.2.0", recommended: "1.1.0", min: "1.0.0" }),
    "plain tag moves only latest",
  );
  assert(
    JSON.stringify(cascade(prev, parseTag("v1.2.0-recommended"))) ===
      JSON.stringify({ latest: "1.2.0", recommended: "1.2.0", min: "1.0.0" }),
    "recommended tag moves two",
  );
  assert(
    JSON.stringify(cascade(prev, parseTag("v1.2.0-breaking"))) ===
      JSON.stringify({ latest: "1.2.0", recommended: "1.2.0", min: "1.2.0" }),
    "breaking tag moves all three",
  );
  assert(
    JSON.stringify(cascade({}, parseTag("v1.0.0"))) ===
      JSON.stringify({ latest: "1.0.0", recommended: null, min: null }),
    "first release leaves the floors unset",
  );
  console.log("selftest ok");
} else {
  main().catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
}
