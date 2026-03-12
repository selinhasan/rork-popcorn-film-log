# 🍿 Popcorn Film Log

A film diary and social logging app built with React Native (Expo). Log films you've watched, browse trending titles via TMDb, manage a watchlist, and connect with buddies.

---

## Tech Stack

- **React Native** (Expo SDK 52) — iOS, Android, and Web
- **Supabase** — Auth + Postgres database
- **TMDb API** — Film data, posters, and search
- **React Navigation v7** — Bottom tabs + native stack

---

## Prerequisites

- [Node.js](https://nodejs.org/) 18+
- [Expo Go](https://expo.dev/go) app installed on your phone (iOS or Android)
- A [Supabase](https://supabase.com) project
- A [TMDb API key](https://www.themoviedb.org/settings/api)

---

## Getting Started

### 1. Clone and install

```bash
git clone https://github.com/selinhasan/rork-popcorn-film-log.git
cd rork-popcorn-film-log
npm install
```

### 2. Set up environment variables

Create a `.env` file in the project root:

```env
EXPO_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
EXPO_PUBLIC_TMDB_API_KEY=your-tmdb-api-key
```

> Get your Supabase URL and anon key from **Project Settings → API** in your Supabase dashboard.  
> Get your TMDb key from [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api).

### 3. Set up Supabase tables

Run the following SQL in the **Supabase SQL editor**:

```sql
-- Users profile table (RLS disabled)
create table public.users (
  id uuid not null,
  username text not null,
  username_lower text not null,
  email text not null,
  password_hash text not null,
  profile_image_name text null default 'avatar_1',
  custom_profile_image_url text null,
  bio text null default '',
  top_five_films jsonb null default '[]',
  buddy_ids jsonb null default '[]',
  watchlist jsonb null default '[]',
  diary_entries jsonb null default '[]',
  film_lists jsonb null default '[]',
  status text null default 'active',
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  constraint users_pkey primary key (id),
  constraint users_email_key unique (email),
  constraint users_username_lower_key unique (username_lower)
);

-- Film log entries table (RLS disabled)
create table public.filmlogs (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  title text null,
  rating smallint null,
  review text null,
  watched_date date null default now(),
  created_at timestamp without time zone null default now(),
  constraint filmlogs_pkey primary key (id)
);
```

### 4. Start the app

```bash
npm start
```

This opens the Expo developer tools. Then:

| Platform | How to open |
|---|---|
| **Phone (iOS/Android)** | Scan the QR code with the Expo Go app |
| **Web browser** | Press `w` in the terminal, or `npm run web` |
| **iOS Simulator** | Press `i` (requires Xcode on macOS) |
| **Android Emulator** | Press `a` (requires Android Studio) |

---

## Project Structure

```
src/
  context/
    AuthContext.jsx   # Supabase auth + user profile state
    AppContext.jsx    # Diary entries, watchlist, TMDb data
  lib/
    supabase.js       # Supabase client
    tmdb.js           # TMDb API service
  screens/
    LoginScreen.jsx
    RegisterScreen.jsx
    DiaryScreen.jsx
    BrowseScreen.jsx
    BuddiesScreen.jsx
    ProfileScreen.jsx
    LogFilmScreen.jsx
  theme/
    colors.js         # Shared color constants
App.jsx               # Navigation root
```

---

## Deploying to Vercel (Web)

Expo can export the app as a static web build that deploys to Vercel.

### 1. Install the Vercel CLI

```bash
npm install -g vercel
```

### 2. Add an export script to `package.json`

```json
"scripts": {
  "build:web": "expo export -p web"
}
```

### 3. Create `vercel.json` in the project root

```json
{
  "buildCommand": "npm run build:web",
  "outputDirectory": "dist",
  "framework": null
}
```

### 4. Add environment variables to Vercel

In the [Vercel dashboard](https://vercel.com) under **Project → Settings → Environment Variables**, add:

```
EXPO_PUBLIC_SUPABASE_URL
EXPO_PUBLIC_SUPABASE_ANON_KEY
EXPO_PUBLIC_TMDB_API_KEY
```

### 5. Deploy

```bash
vercel
```

Or connect the GitHub repo in the Vercel dashboard for automatic deploys on every push to `main`.

> **Note:** The deployed web version uses `localStorage` for auth session storage. Native features like `expo-secure-store` are automatically skipped on web — the code handles this already.

