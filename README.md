# Song Rater

Song Rater is a single-window iOS app for rating the track currently playing in Apple Music.

The app reads the Music app's current song, adds it to one of five playlists named `Rate 1` through `Rate 5`, and speaks the rating confirmation. App Intents expose the same rating actions to Siri and Shortcuts.

## Requirements

- Xcode with iOS 17 SDK or newer
- A physical iPhone signed into Apple Music
- Media Library permission granted on first launch

## Siri

The project registers five App Shortcuts:

- "Give this song one with Song Rater"
- "Give this song two with Song Rater"
- "Give this song three with Song Rater"
- "Give this song four with Song Rater"
- "Give this song five with Song Rater"

iOS-provided App Shortcut phrases generally include the app name. To use the exact phrase "Hey Siri, give this song n", add a custom voice phrase to the shortcut in the Shortcuts app.
