# ZIP Rewrite Fix

The monolithic offline APK is larger than 2 GiB but remains below the classic
ZIP 4 GiB limit. The assembler rewrites selected entries to add the VR loader,
native library, settings, and audio data.

## Failure

The first rewrite forced ZIP64 metadata on every copied entry. That changed the
local ZIP header's `version needed` field to 45 while the central directory kept
20 for 732 entries. Legacy Android Build Tools then reported repeated
`header mismatch` warnings.

Removing the forced ZIP64 flag fixed the per-entry mismatch, but Python's normal
size threshold still emitted a ZIP64 end-of-central-directory record for the
large output. The legacy `zipalign` implementation could not open that output.

## Fix

`tools/assemble.py` now:

- preserves the original entry metadata without forcing ZIP64 per entry;
- temporarily raises Python's `zipfile.ZIP64_LIMIT` to the classic ZIP limit
  while writing this under-4-GiB APK;
- restores the process-global limit in `finally`, including failure paths;
- lets the pinned Android Build Tools perform the final alignment.

## Verification

The build must pass all of these checks:

```text
python -m py_compile tools/assemble.py
zipalign -c -P 16 4 base.apk
apksigner verify --verbose base.apk
python -m zipfile -t base.apk
```

`verify_apk.bat` runs the alignment and signature checks for a specified APK.
The complete build also records output hashes in `build-manifest.json` and
validates the staged Quest payload before reporting success.