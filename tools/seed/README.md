# Sample readers for Bookmunity

`seed.mjs` creates 10 sample readers with cute avatars, bios, reading stats,
activity, friendships among themselves and 21 book reviews, so the Friends tab
and book reviews have something to show while testing.

It uses the normal Firebase client SDK (no admin key): each sample reader is a
real Email/Password account, and every write goes through `firestore.rules`
exactly like the app's own writes.

## One-time Firebase setup (project owner)

1. **Create the database**: Firebase console → *Firestore Database* → *Create
   database* → **Standard edition**, database ID `(default)`, a location near
   your readers (cannot be changed later), start in **production mode**.
2. **Deploy rules and indexes** from the repo root, logged in with an account
   that owns the `bookmunity` project:

   ```bash
   firebase login            # if needed
   firebase deploy --only firestore --project bookmunity
   ```

3. Make sure *Authentication → Sign-in method → Email/Password* is enabled
   (the app already uses it).

## Seed

```bash
cd tools/seed
npm install

# Sample readers only
node seed.mjs seed

# …and connect them to your own account (sign up in the app first).
# With your credentials, 5 readers become your friends immediately and
# 2 more send you friend requests:
TESTER_EMAIL=you@example.com TESTER_PASSWORD='your-password' \
  node seed.mjs seed --friend your_username

# Without credentials, all 7 send you friend requests to accept in the app.
node seed.mjs seed --friend your_username

# Sample readers accept any requests you sent them from the app:
node seed.mjs accept --friend your_username
```

Re-running is safe: accounts, profiles, friendships and activity are reused,
profiles and reviews are refreshed.

Sample accounts sign in as `<username>@seed.bookmunity.app` with password
`bookmunity-seed` (override with `SEED_PASSWORD`), so you can also log in as
one of them to test the other side of a friend request.

Add `--emulator` to target the local emulators
(`firebase emulators:start --only auth,firestore --project demo-bookmunity`,
needs Java 21+).

## Books with sample reviews

Reviews attach to a book by title and author, so they appear once you import
these Project Gutenberg EPUBs (download, then import in the app):

| Book | EPUB |
|---|---|
| Pride and Prejudice | https://www.gutenberg.org/ebooks/1342.epub3.images |
| Frankenstein | https://www.gutenberg.org/ebooks/84.epub3.images |
| The Adventures of Sherlock Holmes | https://www.gutenberg.org/ebooks/1661.epub3.images |
| Alice's Adventures in Wonderland | https://www.gutenberg.org/ebooks/11.epub3.images |
| The Great Gatsby | https://www.gutenberg.org/ebooks/64317.epub3.images |
| Dracula | https://www.gutenberg.org/ebooks/345.epub3.images |

## Removing sample data

Sample accounts can be deleted in *Authentication → Users* (filter by
`seed.bookmunity.app`); their profiles, usernames and reviews are removed in
the Firestore console.
