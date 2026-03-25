# Nimbus — Onboarding Screens

Nimbus is a productivity multiplier. Onboarding should show it off — the instant search, the Google Drive integration, the smart clipboard. 4 screens that communicate "this is the tool you've been missing."

---

## Screen 1 — Welcome / Connect Google Drive

**Trigger:** First launch

**Layout:** Centered layout — large cloud illustration, headline, two CTAs.

**Illustration concept:**
A large, friendly cloud illustration in the center, rendered in soft `#0EA5E9` (sky blue) with subtle inner shading to give depth. Small file icons (doc, photo, spreadsheet) are floating slightly inside/beneath the cloud, as if emerging from it. A small checkmark or sparkle is on the right side of the cloud to suggest "connected" or "synced."

The illustration is contained within a circular soft-glow background — a very subtle `#0EA5E9` radial gradient at 10% opacity.

**Visual style:**
- Cloud: `#0EA5E9` fill, no stroke, soft rounded bumps, 120pt wide
- File icons: white fill, soft drop shadow beneath each, 20pt size, floating just inside the cloud base
- Glow: radial gradient from `#0EA5E9` at 15% center to transparent, 200pt diameter

**Text:**
> "Your files, everywhere."
> "Search your Mac and Google Drive in one place. Your clipboard learns what you paste."

**Primary CTA:** "Connect Google Drive" — `#6366F1` fill (Drive indigo), white text, 40pt height, 8pt corner radius.
**Secondary CTA:** "Search Mac Only" — `#0EA5E9` outline button, `#0EA5E9` text, 40pt height, 8pt corner radius.

---

## Screen 2 — Instant Search

**Trigger:** After first search (or shown in the first launch flow before Screen 1 if Drive skipped)

**Layout:** Split — search bar mockup at top, three result rows below.

**Illustration concept:**
A macOS-style search field (rounded rectangle, `#F1F5F9` fill, `#E2E8F0` border) with a magnifying glass icon on the left and a small `⌘N` badge on the right edge (indicating the shortcut to open Nimbus). Below the search field, three result rows are shown:

1. A Google Drive file row: file icon (spreadsheet), filename "Q4 Budget 2025", path "/Drive/Marketing", timestamp "2h ago", with a small indigo cloud badge in the corner
2. A local file row: file icon (document), filename "Meeting Notes.pdf", path "~/Documents", timestamp "Yesterday", with no badge
3. A clipboard entry row: clipboard icon, text preview "Here's the link to the..."

A small keyboard shortcut hint floats below the results: `↑↓` to navigate, `↵` to open, `⌘⇧V` to paste.

**Visual style:**
- Search field: `#F8FAFC` fill, `#E2E8F0` border, 32pt height, 8pt corner radius
- Result rows: white fill, `#E2E8F0` bottom border, 48pt height
- File icon: `#64748B`, 16pt SF Symbol
- Drive cloud badge: `#6366F1`, 8pt, positioned top-right of file icon
- Timestamp: `#64748B`, 10pt, right-aligned
- Shortcut hint: `#64748B`, SF Mono, 10pt, subtle

**Text:**
> "Results as you type — local files and Drive, together."
> "Press ⌘N to search from anywhere."

---

## Screen 3 — Smart Paste

**Trigger:** First time using smart paste (or shown as a tooltip-style overlay on first paste action)

**Layout:** A floating panel mockup near a text cursor, showing 3 paste suggestions.

**Illustration concept:**
A small floating panel (320pt wide, auto height) that would appear near an active text cursor in a document. The panel shows 3 suggested paste items as horizontal rows:

1. A URL with a small link icon: "https://drive.google.com/..." — labeled "From your last email"
2. A file path with a file icon: "~/Downloads/Invoice_Q4.pdf" — labeled "Recent download"
3. An image thumbnail: 40×40pt rounded thumbnail — labeled "Screenshot from 10:34 AM"

Each row has a small confidence bar (thin, `#0EA5E9` fill) at the right edge. A small "Smart Paste" label at the top left of the panel in `#64748B` uppercase text.

A text cursor and blinking insertion point are shown below the panel, indicating where the pasted content would go.

**Visual style:**
- Panel: white fill, `#E2E8F0` border, 8pt corner radius, soft shadow (0, 4, 12, `#0F172A` at 8%)
- Panel header: `#64748B` uppercase label, 10pt, letter-spacing 0.08em
- Confidence bars: 3pt height, `#0EA5E9` fill, varying widths (100%, 75%, 40%)
- Image thumbnail: `#F1F5F9` fill, 4pt corner radius
- Cursor: standard macOS blinking I-beam in `#0EA5E9`

**Text:**
> "Nimbus suggests what to paste based on what you're doing."
> "Hit ⌘⇧V to open Smart Paste anywhere."

---

## Screen 4 — Clipboard History & Settings

**Trigger:** First time opening the clipboard history view or Settings

**Layout:** Two-panel — clipboard history stack on the left, settings shortcuts on the right.

**Illustration concept:**
Left panel: A vertical stack of 4 clipboard history cards, each slightly offset downward to create a "deck" effect (the top card is fully visible, the ones below peek out slightly). Each card shows:

- Card 1 (top, full): A text preview — two lines of text in `#0F172A` on a white card with a small clipboard icon top-left and a "Now" timestamp top-right
- Card 2: Image thumbnail card — 40pt rounded square of a screenshot, muted
- Card 3: URL card — link icon + truncated URL, muted
- Card 4: File card — file icon + filename + path, muted

Right panel: A vertical list of 3 setting shortcut tiles:
1. "Index Google Drive" with a Drive cloud icon and toggle (ON)
2. "Clipboard History" with a clipboard icon and "30 days" label
3. "Global Hotkey" with a keyboard icon and `⌘⇧V` badge

**Visual style:**
- Clipboard cards: white fill, `#E2E8F0` border, 6pt corner radius, soft shadow
- Offset stacking: each card 4pt lower and 2pt darker border than the one above
- Muted cards: 50% opacity
- Setting tiles: white fill, `#E2E8F0` border, 6pt radius, 48pt height
- Toggles: macOS native style — `#0EA5E9` when ON

**Text:**
> "Everything you've copied in the last 30 days."
> "Search it, paste it, or pin your favorites."

**CTA:** "Open Nimbus ⌘N" — `#0EA5E9` fill, full-width of the right panel, 36pt height.
