# Integrations Index Spec

File: `integrations/index.json`

## Schema

```json
{
  "version": "1.0.0",
  "scripts": [
    {
      "id": "string-unique-id",
      "name": "display name",
      "source": "https://example/script.sh",
      "pinned_version": "v1.2.3",
      "sha256": "64-char-hex",
      "manual_confirm": true,
      "enabled": true,
      "tags": ["network", "docker"]
    }
  ]
}
```

## Required Fields

- `id`: unique key for cache filename and logs
- `name`: menu display name
- `source`: direct download URL
- `pinned_version`: stable marker recorded in cache path
- `sha256`: integrity check value
- `manual_confirm`: whether execution requires confirmation
- `enabled`: controls visibility in menu

## Execution Flow

1. Load enabled entries from `index.json`
2. User selects one script
3. Download script to `data/cache/`
4. Verify SHA256 (required)
5. Ask for manual confirmation (if enabled)
6. Execute using `bash`

## Current Seeded Entries

The initial list includes 4 Sing-box scripts referenced from:
- `https://blog.luopojunzi.com/p/OneClickScript/`

They are visible in menu now, but execution is blocked until each entry has a valid `sha256`.
