# RatingBot

RatingBot is a single-window iPhone app for "rating" the track currently playing in the Music app since Apple long ago removed the ability for Siri to star-rate music. It’s geared to rating music in the background by voice while doing other things.

<img width="4260" height="3018" alt="RatingBot-samples" src="https://github.com/user-attachments/assets/1cec6378-a22e-4c06-8687-a6986b01a48b" />

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

Tapping the time remaining will toggle “Speed Mode.” With Speed Mode active, after rating a song the app will do a verbal confirmation of the star rating only and will skip the Music app to the next song.

After a rating session, use the desktop Music app to select all the songs in a RatingBot playlist and assign the appropriate star rating. Those songs can then be removed from the playlist.

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

