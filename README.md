<p align="center">
  <img src="assets/icon-256.png" width="128" alt="Red Mode icon">
</p>

<h1 align="center">Red Mode</h1>

<p align="center">One click and your whole Windows screen goes red. Click again and it's back to normal.</p>

---

If you've ever been on a boat at night, out stargazing, or in a dark room where someone's trying to sleep, you know how brutal a bright screen is. Your eyes take 20-30 minutes to fully adjust to the dark, and one glance at a white web page wipes that out.

That's why pilots, astronomers and the military use red light. Your rod cells (the ones doing the work in the dark) barely respond to deep red, so you can read what's in front of you without wrecking your night vision.

Night Light and "warm" filters don't really cut it. They just tint things orange and there's still plenty of green and blue getting through. Red Mode is the real thing: **every pixel on every monitor is converted to red only.** Green and blue are switched off completely. Your mouse pointer goes red too.

## What it looks like

Everything keeps its shape and contrast, it's just red. White becomes bright red, black stays black, and everything in between becomes a shade of red based on how bright it was. Text stays perfectly readable.

## Install

You need Windows 10 or 11. No admin rights, nothing to download besides this repo.

1. Download or clone this repo.
2. Right-click `install.ps1` and choose **Run with PowerShell**.

Or from a terminal:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

That builds the app (using the C# compiler that's already part of Windows), copies it to `%LOCALAPPDATA%\RedMode`, and puts a **Red Mode** icon on your Desktop and in the Start menu.

## Use it

- **Double-click the Red Mode icon** to turn it on. Double-click again to turn it off.
- Or press **Ctrl + Alt + R** from anywhere.

That's it. There's no window, no tray icon, no settings. It's on or it's off.

**Tip:** turn your screen brightness down too. Red light is much kinder to your night vision than white light, but a blazing red screen is still a blazing screen. Dim red is the goal.

## Good to know

- **It covers all your monitors** at once.
- **Some things might not turn red.** DRM-protected video (some Netflix-type players) and HDR displays can bypass the filter.
- **If you kill it from Task Manager** instead of toggling it off, your screen goes back to normal but the mouse pointers stay red. Just turn Red Mode on and off again and they'll reset. (Signing out also fixes it.)
- **Animated pointers** like the spinning "busy" circle show as a still red version while Red Mode is on.

## How it works

It's about 150 lines of C# in [`src/RedMode.cs`](src/RedMode.cs), so feel free to read the whole thing.

- The screen colour comes from Windows' own Magnification API (`MagSetFullscreenColorEffect`), the same system the built-in Magnifier and colour filters use. I give it a colour matrix that takes the brightness of each pixel and puts it all into the red channel.
- The mouse pointer isn't affected by that filter, so the app makes red copies of your current pointers (keeping your size and scheme) and swaps them in. When you turn it off, Windows reloads your normal ones.
- Clicking the icon a second time doesn't start a new copy. It tells the running one to shut down, which restores everything.

Nothing is installed as a service, nothing runs at startup, and it doesn't touch the network.

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```

Turns it off if it's on and removes the app and both shortcuts.

## Building it yourself

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

You'll get `bin\RedMode.exe`. The icon is drawn by a script too, if you want to tweak it:

```powershell
powershell -ExecutionPolicy Bypass -File assets\make-icon.ps1 -PreviewPng assets\icon-256.png
```

## License

MIT. Do whatever you like with it.
