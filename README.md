# RatingBot

RatingBot is a single-window iPhone app for rating the track currently playing in Apple Music.

## What It Does

- Shows the current song title and artist from the Music app
- Creates five app-maintained playlists on first launch:
  - `RatingBot 1`
  - `RatingBot 2`
  - `RatingBot 3`
  - `RatingBot 4`
  - `RatingBot 5`
- Adds the current song to the matching playlist when the user picks a rating
- Speaks a confirmation like `4 stars, Song Title by Artist Name`
- Highlights the assigned rating button until the now-playing track changes
- Exposes the same rating actions through App Shortcuts and Siri

The playlists are looked up by stable app-maintained identifiers, so they continue to work even if the user moves them into subfolders in the Music app.

## Requirements

- Xcode with an iOS 17 SDK or newer
- A physical iPhone signed into Apple Music
- Media Library permission granted on first launch

## Siri and Shortcuts

RatingBot registers five App Shortcuts, one for each rating from 1 through 5.

Supported phrasing includes variations like:

- `Give this song five with RatingBot`
- `Give this song 5 stars using RatingBot`
- `Give this track three with RatingBot`
- `Give this track 1 star using RatingBot`

The app name is usually part of the built-in shortcut phrase matching. If you want a more customized Siri phrase, add one in the Shortcuts app after installing the app on your device.
