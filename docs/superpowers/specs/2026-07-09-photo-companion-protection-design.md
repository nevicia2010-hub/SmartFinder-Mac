# Photo Companion Protection Design

## Goal

Protect common photography file groups so SmartFinder does not accidentally separate RAW, rendered JPEG/HEIC/TIFF files, and editing sidecars during normal file organization.

## Scope

- Detect same-folder files with the same base name and known photo or sidecar extensions.
- Apply the group to common operations: copy, move, drag/drop, paste, move to Trash, and rename.
- Keep this lightweight by checking sibling file names only during an explicit operation.
- Do not scan whole disks, parse metadata, build catalogs, or decode image contents.

## Supported Companion Types

- Photo counterparts: `jpg`, `jpeg`, `heic`, `tif`, `tiff`
- Mainstream RAW files already recognized by SmartFinder, including `dng`, `cr2`, `cr3`, `nef`, `arw`, `raf`, `rw2`, `orf`, `pef`, `srw`, and related camera formats
- Sidecars: `xmp`, `aae`, `dop`, `pp3`, `on1`, `cos`

## Behavior

- Selecting `IMG_0001.CR3` also includes `IMG_0001.JPG`, `IMG_0001.XMP`, and other known same-stem companions if they exist.
- Selecting multiple files deduplicates the expanded group.
- Copying a group into the same folder uses the existing `copy` suffix behavior per file.
- Moving a group into another folder preserves names unless conflicts require the existing move collision policy.
- Renaming a selected photo file updates same-stem companions to the new base name while keeping each companion's extension.
- Folder operations are not expanded.
