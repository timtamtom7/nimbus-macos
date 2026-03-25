# Nimbus — Brand Guide

## App Overview

Nimbus is a fast file search and clipboard intelligence tool for macOS. It indexes local files and integrates with Google Drive, providing smart paste suggestions, file search, favorites management, and clipboard history. It lives in the menu bar and responds to global hotkeys.

---

## Icon Concept

**Primary icon:** A stylized cloud (representing Google Drive and cloud storage) with a small file/document emerging from it — suggesting "files from the cloud." The cloud is rendered with soft, rounded bumps; the file has a subtle folded corner. A small sparkle near the top of the cloud indicates "fresh" or "synced" state.

**Alternative compositions:**
- A magnifying glass with a cloud inside the lens, suggesting "searching the cloud"
- A small nimbus cloud (fluffy, rounded) with a subtle downward arrow suggesting download/sync

**Design principles:** The cloud is the unifying symbol — it represents both Google Drive integration and the "up in the air / everywhere" nature of a clipboard intelligence tool. The cloud should feel light and approachable, not heavy or industrial. All variants work on light and dark backgrounds.

**Do NOT:** Use a generic folder icon — that's Finder's territory. Don't use a hard drive. The cloud is the differentiator.

---

## Color Palette

| Role | Name | Hex | Usage |
|------|------|-----|-------|
| Background | Mist | `#F8FAFC` | Main popover background (light) |
| Background Alt | Midnight | `#0F172A` | Main popover background (dark) |
| Surface | White | `#FFFFFF` | Cards, list rows, inputs |
| Surface Alt | Slate | `#1E293B` | Cards in dark mode |
| Border | Silver | `#E2E8F0` | Row separators, input borders |
| Text Primary | Deep Navy | `#0F172A` | Headings, filenames |
| Text Secondary | Cool Slate | `#64748B` | Paths, timestamps, metadata |
| Accent | Sky Blue | `#0EA5E9` | Primary actions, selected states, links |
| Accent Alt | Indigo | `#6366F1` | Google Drive brand accent, sync indicators |
| Success | Emerald | `#10B981` | Synced, copied, confirmed |
| Warning | Amber | `#F59E0B` | Pending sync, offline indicator |
| Danger | Rose | `#F43F5E` | Sync errors, failed uploads |

> **Note:** The two brand accent colors are **sky blue** (`#0EA5E9`) for primary actions and local features, and **indigo** (`#6366F1`) for Google Drive–specific features. Use them distinctly — blue for Nimbus-native actions, indigo for Drive/sync operations.

---

## Typography

**Font family:** SF Pro (system font)

| Element | Weight | Size |
|---------|--------|------|
| Filename / Search Result | Medium | 12pt |
| Path / Metadata | Regular | 11pt |
| Section Header | Semibold | 11pt, uppercase, letter-spaced 0.05em |
| Keyboard Shortcut | SF Mono | 10pt |
| Timestamp | Regular | 10pt |
| Empty State | Regular | 12pt, italic |

**Guidelines:**
- Search results show filename prominently, path in a smaller, muted style beneath it
- Timestamps use relative format ("2 min ago", "Yesterday") in `#64748B`
- Section headers are ALL CAPS with wide letter-spacing to visually separate groups
- No custom fonts

---

## Visual Motif

**Core motif: The cloud and the search path.**
The visual language centers on the journey from cloud → local: files flow down from the cloud into Nimbus's search index, and back up to the cloud when shared or synced.

**Key visual elements:**
- **Search result rows:** Each row shows a file icon (SF Symbol by type), filename, path breadcrumb (muted), and a small timestamp. A subtle `#E2E8F0` separator between rows. The selected/highlighted row uses `#0EA5E9` at 8% opacity as background.
- **Google Drive indicator:** When a file is on Drive, a small indigo `#6366F1` cloud badge appears in the corner of the file icon. When syncing, a circular progress arc rotates around the cloud badge.
- **Clipboard history:** Shown as a vertical stack of cards, each with a small "clipboard" icon. Text entries show a truncated preview. Image entries show a thumbnail.
- **Smart paste suggestions:** A small popover with 2–3 suggested paste items, each with a small confidence score bar (thin, `#0EA5E9` fill).
- **Sync status dot:** A small 6pt circle in the status bar area: green = synced, amber = pending, rose = error.

**Icon library:** SF Symbols. Key symbols: `doc`, `doc.text`, `photo`, `film`, `folder`, `cloud`, `cloud.fill`, `magnifyingglass`, `doc.on.clipboard`, `pin`, `arrow.up.circle`, `checkmark.circle`.

**Patterns:** No decorative patterns. A subtle horizontal line separator (1pt, `#E2E8F0`) is the primary structural divider.

---

## Size Behavior

| Context | Width | Height | Notes |
|---------|-------|--------|-------|
| Menu bar popover | 480pt | 400pt | Search results + clipboard history |
| Status popover (small) | 320pt | 240pt | Quick paste suggestions |
| Settings window | 520pt | 440pt | Full settings, Drive account management |
| File preview panel | 280pt | 400pt | Slides in from right in search results |
| Smart paste overlay | 320pt | auto | Floating panel near cursor |

**Adaptive:** The popover is fixed at 480×400pt. The file preview panel overlays the results rather than pushing them. Minimum supported popover width: 360pt.
