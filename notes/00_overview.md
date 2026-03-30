# FruitClip — Overview

## What it is

FruitClip is a lightweight native macOS menu bar clipboard manager. It lives exclusively in the menu bar (no Dock icon), captures clipboard history in the background, and surfaces it via a floating popup triggered by a global hotkey.

## Who it serves

Single-user personal tool. No accounts, no network, no sharing.

## Primary problem solved

macOS has no built-in clipboard history. FruitClip lets you re-access the last N items you copied (text and images) without switching apps, using a keyboard-first popup that auto-pastes back into the previously focused window.

## Core user journey

1. Copy things normally throughout the day.
2. Press `⌘⇧V` (or custom hotkey) to open the floating popup.
3. Arrow-key through history, hit Enter — the item is pasted directly into whatever app you were in.
4. Dismiss with Escape or by clicking outside.

## Current maturity

**Confirmed from code** — Feature-complete v1. All documented features work. No CI/CD, no notarization, ad-hoc signed only.

## Repo reality

| Claim | Status |
|-------|--------|
| Clipboard polling (text + image) | Confirmed from code |
| Global hotkey via Carbon API | Confirmed from code |
| Floating popup with search + keyboard nav | Confirmed from code |
| Auto-paste via CGEvent Cmd+V synthesis | Confirmed from code |
| Pinned items | Confirmed from code |
| Persistent history (survives relaunch) | Confirmed from code |
| Launch at Login (ServiceManagement) | Confirmed from code — wired, needs polish |
| Configurable hotkey in Preferences | Confirmed from code |
| Dismiss on mouse move option | Confirmed from code |
| Update checker | Not found in repository (removed in c316141) |
| Notarization / App Store distribution | Not found in repository |
