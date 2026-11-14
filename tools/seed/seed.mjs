#!/usr/bin/env node
// Seeds sample readers into Bookmunity's Firestore using the normal client
// SDK, so every write goes through firestore.rules exactly like the app's.
//
//   node seed.mjs seed   [--friend <username>] [--emulator]
//   node seed.mjs accept --friend <username>   [--emulator]
//
// Environment:
//   SEED_PASSWORD                  password for all sample accounts
//                                  (default "bookmunity-seed")
//   TESTER_EMAIL, TESTER_PASSWORD  your own account; with --friend this
//                                  makes the sample readers your friends
//                                  right away instead of just requesting.
//
// Safe to re-run: existing accounts, profiles, friendships and activity are
// reused, profiles and reviews are refreshed.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { initializeApp } from 'firebase/app';
import {
  connectAuthEmulator,
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import {
  addDoc,
  collection,
  connectFirestoreEmulator,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  limit,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

import { BOOKS, FRIENDSHIPS, TESTER_FRIENDS, TESTER_REQUESTS, USERS } from './data.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const command = args[0] ?? 'seed';
const flag = (name) => {
  const index = args.indexOf(`--${name}`);
  return index === -1 ? undefined : args[index + 1];
};
const useEmulator = args.includes('--emulator');
const friendUsername = flag('friend');
const password = process.env.SEED_PASSWORD ?? 'bookmunity-seed';

// --------------------------------------------------------------- config

function webConfig() {
  const source = readFileSync(join(here, '../../lib/firebase_options.dart'), 'utf8');
  const block = source.slice(source.indexOf('FirebaseOptions web'));
  const field = (name) => block.match(new RegExp(`${name}: '([^']+)'`))?.[1];
  return {
    apiKey: field('apiKey'),
    authDomain: field('authDomain'),
    projectId: useEmulator ? `demo-${field('projectId')}` : field('projectId'),
    appId: field('appId'),
  };
}

const app = initializeApp(webConfig());
const auth = getAuth(app);
const db = getFirestore(app);
if (useEmulator) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
}

const emailFor = (username) => `${username}@seed.bookmunity.app`;
const log = (...parts) => console.log(...parts);

// -------------------------------------------------------------- helpers

async function signInAs(email, pass, { create = false } = {}) {
  await signOut(auth);
  try {
    return (await signInWithEmailAndPassword(auth, email, pass)).user;
  } catch (error) {
    const missing = ['auth/user-not-found', 'auth/invalid-credential', 'auth/invalid-login-credentials'];
    if (!create || !missing.includes(error.code)) throw error;
    return (await createUserWithEmailAndPassword(auth, email, pass)).user;
  }
}

async function profileOf(uid) {
  const snapshot = await getDoc(doc(db, 'profiles', uid));
  return snapshot.exists() ? snapshot.data() : null;
}

async function uidForUsername(username) {
  const snapshot = await getDoc(doc(db, 'usernames', username.toLowerCase()));
  return snapshot.exists() ? snapshot.data().uid : null;
}

// Mirrors SocialRepository.createProfile.
async function ensureProfile(uid, user) {
  const [booksFinished, currentStreak, longestStreak, badgeCount] = user.stats;
  const stats = { booksFinished, currentStreak, longestStreak, badgeCount };
  const existing = await profileOf(uid);
  if (existing) {
    await updateDoc(doc(db, 'profiles', uid), {
      displayName: user.displayName,
      bio: user.bio,
      ...stats,
      updatedAt: serverTimestamp(),
    });
    return 'updated';
  }
  const lower = user.username.toLowerCase();
  await runTransaction(db, async (transaction) => {
    const claimed = await transaction.get(doc(db, 'usernames', lower));
    if (claimed.exists()) throw new Error(`username ${user.username} is taken by someone else`);
    transaction.set(doc(db, 'usernames', lower), { uid });
    transaction.set(doc(db, 'profiles', uid), {
      uid,
      username: user.username,
      usernameLower: lower,
      displayName: user.displayName,
      bio: user.bio,
      hasPhoto: false,
      ...stats,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  });
  return 'created';
}

// Mirrors SocialRepository.saveReview.
async function saveReview(uid, user, [bookId, rating, text]) {
  const book = BOOKS[bookId];
  const ref = doc(db, 'books', book.key, 'reviews', uid);
  const existing = await getDoc(ref);
  await setDoc(ref, {
    uid,
    username: user.username,
    displayName: user.displayName,
    rating,
    text,
    title: book.title,
    author: book.author,
    createdAt: existing.exists() ? existing.data().createdAt : serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

// Mirrors SocialRepository.postActivity. Only posts when the user has none,
// so re-running does not duplicate the feed.
async function seedActivity(uid, user) {
  const existing = await getDocs(query(collection(db, 'users', uid, 'activity'), limit(1)));
  if (!existing.empty) return 0;
  const reviewed = new Map(user.reviews.map(([bookId, rating]) => [bookId, rating]));
  const entries = [...user.activity];
  // Each review also appears in the feed.
  for (const [bookId] of user.reviews.slice(0, 1)) entries.push(['review', bookId]);
  for (const [type, a, b] of entries) {
    const book = type === 'badge' ? null : BOOKS[a];
    await addDoc(collection(db, 'users', uid, 'activity'), {
      type,
      title: book?.title ?? '',
      author: book?.author ?? '',
      bookKey: book?.key ?? '',
      badgeId: type === 'badge' ? a : '',
      badgeTitle: type === 'badge' ? b : '',
      rating: type === 'review' ? reviewed.get(a) ?? 0 : 0,
      createdAt: serverTimestamp(),
    });
  }
  return entries.length;
}

const requestId = (from, to) => `${from}_${to}`;

async function areFriends(ownerUid, otherUid) {
  return (await getDoc(doc(db, 'users', ownerUid, 'friends', otherUid))).exists();
}

// Signed in as the sender. Mirrors SocialRepository.sendRequest.
async function sendRequest(fromUid, from, toUid, to) {
  if (await areFriends(fromUid, toUid)) return 'already friends';
  await setDoc(doc(db, 'friendRequests', requestId(fromUid, toUid)), {
    fromUid,
    toUid,
    fromUsername: from.username,
    fromDisplayName: from.displayName,
    toUsername: to.username,
    toDisplayName: to.displayName,
    createdAt: serverTimestamp(),
  });
  return 'requested';
}

// Signed in as the recipient. Mirrors SocialRepository.acceptRequest.
async function acceptRequest(meUid, me, fromUid, from) {
  const request = await getDoc(doc(db, 'friendRequests', requestId(fromUid, meUid)));
  if (!request.exists()) return false;
  const batch = writeBatch(db);
  batch.set(doc(db, 'users', meUid, 'friends', fromUid), {
    uid: fromUid,
    username: from.username,
    displayName: from.displayName,
    since: serverTimestamp(),
  });
  batch.set(doc(db, 'users', fromUid, 'friends', meUid), {
    uid: meUid,
    username: me.username,
    displayName: me.displayName,
    since: serverTimestamp(),
  });
  batch.delete(request.ref);
  await batch.commit();
  return true;
}

// ------------------------------------------------------------- commands

async function seed() {
  log(`Seeding ${useEmulator ? 'the local emulator' : `project ${webConfig().projectId}`}…`);
  const uids = {};
  for (const user of USERS) {
    const account = await signInAs(emailFor(user.username), password, { create: true });
    uids[user.username] = account.uid;
    const profile = await ensureProfile(account.uid, user);
    for (const review of user.reviews) await saveReview(account.uid, user, review);
    const posted = await seedActivity(account.uid, user);
    log(`  @${user.username}: profile ${profile}, ${user.reviews.length} reviews, ${posted} activity`);
  }

  const byName = Object.fromEntries(USERS.map((user) => [user.username, user]));
  for (const [a, b] of FRIENDSHIPS) {
    await signInAs(emailFor(a), password);
    const sent = await sendRequest(uids[a], byName[a], uids[b], byName[b]);
    if (sent === 'requested') {
      await signInAs(emailFor(b), password);
      await acceptRequest(uids[b], byName[b], uids[a], byName[a]);
    }
    log(`  friends: @${a} + @${b}`);
  }

  if (friendUsername) await connectTester(uids, byName);
  await signOut(auth);
  log('Done.');
}

async function connectTester(uids, byName) {
  await signInAs(emailFor(USERS[0].username), password);
  const testerUid = await uidForUsername(friendUsername);
  if (!testerUid) throw new Error(`No profile with username @${friendUsername}. Sign up in the app first.`);
  const tester = await profileOf(testerUid);
  const testerEmail = process.env.TESTER_EMAIL;
  const testerPassword = process.env.TESTER_PASSWORD;

  for (const name of TESTER_FRIENDS) {
    if (testerEmail && testerPassword) {
      await signInAs(testerEmail, testerPassword);
      const sent = await sendRequest(testerUid, tester, uids[name], byName[name]);
      if (sent === 'requested') {
        await signInAs(emailFor(name), password);
        await acceptRequest(uids[name], byName[name], testerUid, tester);
      }
      log(`  @${friendUsername} is friends with @${name}`);
    } else {
      await signInAs(emailFor(name), password);
      const sent = await sendRequest(uids[name], byName[name], testerUid, tester);
      log(`  @${name} → @${friendUsername}: ${sent}`);
    }
  }
  for (const name of TESTER_REQUESTS) {
    await signInAs(emailFor(name), password);
    const sent = await sendRequest(uids[name], byName[name], testerUid, tester);
    log(`  @${name} → @${friendUsername}: ${sent}`);
  }
}

/** Every sample reader accepts any pending request from --friend. */
async function accept() {
  if (!friendUsername) throw new Error('accept needs --friend <username>');
  for (const user of USERS) {
    const account = await signInAs(emailFor(user.username), password);
    const testerUid = await uidForUsername(friendUsername);
    if (!testerUid) throw new Error(`No profile with username @${friendUsername}.`);
    const tester = await profileOf(testerUid);
    if (await acceptRequest(account.uid, user, testerUid, tester)) {
      log(`  @${user.username} accepted @${friendUsername}`);
    }
  }
  await signOut(auth);
  log('Done.');
}

const commands = { seed, accept };
if (!commands[command]) {
  console.error(`Unknown command "${command}". Use: seed | accept`);
  process.exit(1);
}
commands[command]()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(`\nFailed: ${error.code ?? ''} ${error.message}`);
    if (error.code === 'permission-denied') {
      console.error('Are the latest rules deployed?  firebase deploy --only firestore');
    }
    process.exit(1);
  });
