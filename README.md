# Nimbus

A clipboard manager for macOS with cloud sync.

## What it does

- Clipboard history
- favourites
- batch operations
- Drive sync

## Targets

- macOS menu bar

## Structure

Key types:

- ``BatchOperationsService``
- ``ClipboardSync``
- ``CloudIntelligenceEngine``
- ``GoogleDriveService``
- ``FavoritesManager``
- ``StatusPopoverView``

Also has an `AccessibilityExtensions` module, which recurs across this batch of macOS apps.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.
