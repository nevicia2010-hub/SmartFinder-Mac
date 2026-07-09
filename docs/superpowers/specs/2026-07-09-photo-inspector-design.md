# Photo Inspector Design

## Goal

Add a lightweight right-side photography inspector to SmartFinder for checking one or a few photo or RAW files without opening Bridge or Lightroom.

## Scope

- Reuse the existing right-side details pane and make it easier to close from inside the pane.
- Show normal file basics for every selected file.
- For a single selected image or RAW file, read metadata through macOS ImageIO and show common photography fields.
- Support mainstream photo and RAW formats through macOS system frameworks. SmartFinder does not bundle third-party RAW decoders.
- For unsupported or proprietary files, show available basic metadata and skip missing photo fields.

## Photography Fields

- Capture date
- Camera make and model
- Lens model
- Pixel dimensions
- ISO
- Focal length
- Aperture
- Shutter speed
- Exposure compensation
- White balance
- Color space
- GPS latitude and longitude, with an Open in Maps action when available

## Performance Rules

- Read metadata only for the current single selection.
- Do not scan the folder for EXIF.
- Do not decode full-size images for the inspector.
- Do not start background indexing or persistent metadata databases.

## UI

- Keep the pane on the right side of the browser area.
- Add a compact header with a close button.
- Use clear grouped text so the pane feels like a file inspector, not a heavy editing tool.
