# FruitClip — Overview

## What it is

FruitClip is a lightweight native macOS menu bar clipboard manager. It lives exclusively in the menu bar (no Dock icon), captures clipboard history in the background, and surfaces it via a floating popup triggered by a global hotkey.

## Who it serves

Single-user personal tool. No accounts, no network, no sharing.

## Primary problem solved

macOS has no built-in clipboard history. FruitClip lets you re-access the last N items you copied (text and images) without switching apps, using a keyboard-first popup that auto-pastes back into the previously focused window.

## Core user journey

1. Copy things normally throughout the day.
2. Press `⌘⇧V` (or your customized Open Board shortcut) to open the floating popup on the Board tab. An optional second shortcut opens directly on the Star tab.
3. Arrow-key through history, hit Enter — the item is pasted directly into whatever app you were in.
4. Press `S` on a row to star it — it stays in the Star tab and survives Board pruning.
5. Dismiss with Escape or by clicking outside.

## Current maturity

**Confirmed from code** — Feature-complete v1. All documented features work. No CI/CD, no notarization, ad-hoc signed only.

## Repo reality

| Claim | Status |
|-------|--------|
| Clipboard polling (text + image) | Confirmed from code |
| Global hotkey via Carbon API (dual: Open Board + optional Open Star) | Confirmed from code |
| Floating popup with Board / Star tabs, search + keyboard nav | Confirmed from code |
| Auto-paste via CGEvent Cmd+V synthesis | Confirmed from code |
| Starred items (dedicated tab, separate retention) | Confirmed from code |
| Persistent history with versioned `StorageEnvelope` (schema v3) and legacy migration | Confirmed from code |
| Launch at Login (ServiceManagement) with user-visible error alerts | Confirmed from code |
| Multi-shortcut Settings (open / star / delete / switch / copy / focus search) | Confirmed from code |
| Hotkey conflict detection (alert + jump to Settings on collision) | Confirmed from code |
| Dismiss on mouse move option (50pt accumulated delta) | Confirmed from code |
| Configurable popup font size (11–15pt) and retention policies | Confirmed from code |
| `install.sh` / `uninstall.sh` for end-user deployment | Confirmed from code |
| Update checker | Not found in repository (removed in c316141) |
| Notarization / App Store distribution | Not found in repository |
