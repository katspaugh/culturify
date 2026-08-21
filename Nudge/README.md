# Nudge (Apple Watch)

A tiny watchOS app that gives your wrist a single tap-like vibration every
20 minutes. Press **Start** once and forget about it; press **Stop** to
silence it.

## How it works

watchOS doesn't let an app run a timer in the background indefinitely, so
Nudge schedules a **repeating local notification** every 20 minutes:

- **App in the background / closed** — the notification arrives and the watch
  plays its haptic. With the watch in **Silent Mode** (which most people use)
  that's just the tap, no sound. If your wrist is raised at that moment,
  you'll also see a small "Nudge" banner.
- **App on screen** — the banner is suppressed and the app plays a plain
  `.click` haptic instead.

The app also shows a live countdown to the next tap.

## Requirements

- Xcode 15 or newer on a Mac
- An Apple Watch on watchOS 10+, paired to an iPhone
- A (free) Apple developer account for signing

There's no Xcode-project generator or dependency here — `Nudge.xcodeproj` is
checked in, and the whole app is two Swift files.

## Install on your watch

1. Open `Nudge/Nudge.xcodeproj` in Xcode.
2. Select the **Nudge Watch App** target → *Signing & Capabilities* → pick
   your **Team** (and change the bundle identifier if Xcode complains it's
   taken).
3. Choose your Apple Watch as the run destination (it appears via the paired
   iPhone; both need to be unlocked and nearby).
4. Press **Run**. First deploys to a watch can take a couple of minutes.
5. On the watch, open Nudge and press **Start**. Allow notifications when
   asked — that's what delivers the taps while the app is closed.

It also runs fine in the watchOS Simulator, though the simulator can't
vibrate — you'll see the notification banner instead.

## Tweaks

- **Cadence**: change the `interval` constant at the top of
  `Nudge Watch App/ContentView.swift` (`20 * 60` seconds).
- **Stronger taps**: on the watch, *Settings → Sounds & Haptics → Haptic
  Alerts → Prominent*.
- The schedule anchors to the moment you press Start, and repeats every 20
  minutes from there.

## Limitations

Apple doesn't allow silent, banner-free background haptics for third-party
apps outside of workout/extended-runtime sessions, so the background tap is
the standard notification haptic (plus a banner if your wrist happens to be
raised). Notifications are delivered only while the watch is on your wrist
and unlocked — taken off, it stays quiet.
