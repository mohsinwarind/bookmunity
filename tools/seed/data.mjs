// Sample readers for testing the social features.
//
// Book keys must match what the app computes on import
// (EpubMetadataExtractor._bookKey: "title-slug|author-slug" unless the EPUB
// carries an ISBN). These are the Project Gutenberg EPUB3 editions linked
// in README.md, verified by running the app's extractor on the files.

export const BOOKS = {
  pride: {
    key: 'pride-and-prejudice|jane-austen',
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
  },
  frankenstein: {
    key: 'frankenstein-or-the-modern-prometheus|mary-wollstonecraft-shelley',
    title: 'Frankenstein; or, The modern Prometheus',
    author: 'Mary Wollstonecraft Shelley',
  },
  sherlock: {
    key: 'the-adventures-of-sherlock-holmes|arthur-conan-doyle',
    title: 'The Adventures of Sherlock Holmes',
    author: 'Arthur Conan Doyle',
  },
  alice: {
    key: 'alice-s-adventures-in-wonderland|lewis-carroll',
    title: "Alice's Adventures in Wonderland",
    author: 'Lewis Carroll',
  },
  gatsby: {
    key: 'the-great-gatsby|f-scott-fitzgerald',
    title: 'The Great Gatsby',
    author: 'F. Scott Fitzgerald',
  },
  dracula: {
    key: 'dracula|bram-stoker',
    title: 'Dracula',
    author: 'Bram Stoker',
  },
};

// stats: [booksFinished, currentStreak, longestStreak, badgeCount]
export const USERS = [
  {
    username: 'ayesha_reads',
    displayName: 'Ayesha Khan',
    bio: 'Regency romance devotee. Tea, rain and a good Austen.',
    stats: [23, 12, 41, 11],
    reviews: [
      ['pride', 5, 'Elizabeth Bennet is still the sharpest heroine in English fiction. The dialogue sparkles on every reread.'],
      ['gatsby', 4, 'Gorgeous sentences, hollow people — which is exactly the point. The last page gets me every time.'],
      ['alice', 4, 'Pure delightful nonsense. Read it aloud and the wordplay comes alive.'],
    ],
    activity: [['finished', 'pride'], ['started', 'gatsby'], ['badge', 'weekly_reader', 'Weekly Reader']],
  },
  {
    username: 'bilal_pages',
    displayName: 'Bilal Ahmed',
    bio: 'Mysteries before bed, classics on weekends.',
    stats: [9, 3, 15, 7],
    reviews: [
      ['sherlock', 5, 'A Scandal in Bohemia alone is worth it. Holmes and Watson are the original buddy-cop duo.'],
      ['dracula', 4, 'The diary format makes it genuinely creepy. Slow middle, brilliant ending.'],
    ],
    activity: [['finished', 'sherlock'], ['started', 'dracula']],
  },
  {
    username: 'sara_bookworm',
    displayName: 'Sara Malik',
    bio: 'Gothic fiction and very strong coffee.',
    stats: [31, 27, 27, 13],
    reviews: [
      ['frankenstein', 5, 'Not a monster story — a story about loneliness and responsibility. The creature’s chapters are heartbreaking.'],
      ['dracula', 5, 'Atmosphere for days. Reading it at night was a mistake I would make again.'],
      ['pride', 4, 'Witty and warm. Mr Collins made me laugh out loud.'],
    ],
    activity: [['finished', 'frankenstein'], ['badge', 'avid_reader', 'Avid Reader'], ['finished', 'dracula']],
  },
  {
    username: 'hamza_reader',
    displayName: 'Hamza Tariq',
    bio: 'Trying to read 50 books this year. Currently losing.',
    stats: [4, 1, 6, 4],
    reviews: [
      ['gatsby', 3, 'Beautifully written but I couldn’t bring myself to like anyone in it.'],
      ['sherlock', 4, 'Short stories are perfect for a commute. The Red-Headed League is my favourite.'],
    ],
    activity: [['started', 'gatsby'], ['finished', 'sherlock']],
  },
  {
    username: 'zainab_lit',
    displayName: 'Zainab Hussain',
    bio: 'Literature student. I annotate everything.',
    stats: [18, 9, 33, 10],
    reviews: [
      ['frankenstein', 4, 'The framing narrative is so clever — letters inside a story inside a story.'],
      ['alice', 5, 'Every chapter is a little logic puzzle. Carroll was having the time of his life.'],
      ['pride', 5, 'The proposal scene at Hunsford is a masterclass in tension.'],
    ],
    activity: [['finished', 'alice'], ['started', 'frankenstein']],
  },
  {
    username: 'omar_novels',
    displayName: 'Omar Farooq',
    bio: 'Audiobooks on the road, paperbacks at home.',
    stats: [12, 5, 19, 8],
    reviews: [
      ['dracula', 3, 'Great opening in Transylvania. The rest drags a bit for me.'],
      ['gatsby', 5, 'Short, sharp and sad. Read it in one sitting.'],
    ],
    activity: [['finished', 'gatsby'], ['badge', 'bookworm', 'Bookworm']],
  },
  {
    username: 'fatima_tales',
    displayName: 'Fatima Noor',
    bio: 'Fairy tales, folklore and anything with a map in the front.',
    stats: [7, 14, 14, 9],
    reviews: [
      ['alice', 5, 'Read this to my niece and we were both giggling at the Mad Hatter.'],
      ['frankenstein', 4, 'Darker and more thoughtful than I expected.'],
    ],
    activity: [['started', 'alice'], ['badge', 'dedicated_reader', 'Dedicated Reader']],
  },
  {
    username: 'usman_chapters',
    displayName: 'Usman Ali',
    bio: 'Detective stories and history. Night owl reader.',
    stats: [15, 2, 21, 9],
    reviews: [
      ['sherlock', 4, 'Holmes’s deductions never get old, even when you can see them coming.'],
      ['dracula', 4, 'Van Helsing is an absolute legend.'],
    ],
    activity: [['finished', 'dracula'], ['started', 'sherlock']],
  },
  {
    username: 'mariam_reads',
    displayName: 'Mariam Siddiqui',
    bio: 'Book club organiser. Ask me for recommendations!',
    stats: [26, 6, 30, 12],
    reviews: [
      ['pride', 5, 'Our book club’s favourite pick of the year. Everyone had a different favourite Bennet sister.'],
      ['gatsby', 4, 'Sparked the best discussion we have had in months.'],
    ],
    activity: [['finished', 'pride'], ['finished', 'gatsby']],
  },
  {
    username: 'ali_bookshelf',
    displayName: 'Ali Raza',
    bio: 'New to reading for fun. Recommendations welcome.',
    stats: [2, 4, 4, 3],
    reviews: [
      ['alice', 4, 'Weird in the best way. Didn’t expect a kids’ book to be this clever.'],
    ],
    activity: [['started', 'alice'], ['badge', 'first_chapter', 'First Chapter']],
  },
];

// Friendships among the sample readers (so their profiles feel lived in).
export const FRIENDSHIPS = [
  ['ayesha_reads', 'sara_bookworm'],
  ['ayesha_reads', 'mariam_reads'],
  ['bilal_pages', 'usman_chapters'],
  ['zainab_lit', 'fatima_tales'],
  ['omar_novels', 'hamza_reader'],
  ['mariam_reads', 'zainab_lit'],
];

// With --friend: these become the tester's friends (when tester credentials
// are given) or send them requests (otherwise).
export const TESTER_FRIENDS = ['ayesha_reads', 'bilal_pages', 'sara_bookworm', 'zainab_lit', 'mariam_reads'];
// These always leave a pending request so the Requests tab has something.
export const TESTER_REQUESTS = ['hamza_reader', 'fatima_tales'];
