CREATE TABLE devices (
  id            TEXT    PRIMARY KEY,
  name          TEXT    NOT NULL,
  platform      TEXT    NOT NULL CHECK (platform IN ('macos', 'ios', 'cli')),
  created_at    INTEGER NOT NULL,
  last_seen_at  INTEGER NOT NULL
);

CREATE TABLE entries (
  id          TEXT    PRIMARY KEY,
  text        TEXT    NOT NULL,
  bin         TEXT    NOT NULL CHECK (bin IN (
                'inbox', 'next', 'waiting', 'someday',
                'reference', 'done', 'trash')),
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL
);

CREATE TABLE tags (
  id            TEXT    PRIMARY KEY,
  name          TEXT    NOT NULL,
  canonical_id  TEXT    NOT NULL REFERENCES tags(id) ON DELETE RESTRICT,
  created_at    INTEGER NOT NULL,
  archived_at   INTEGER NULL
);

CREATE TABLE entry_tags (
  entry_id  TEXT NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
  tag_id    TEXT NOT NULL REFERENCES tags(id)    ON DELETE RESTRICT,
  PRIMARY KEY (entry_id, tag_id)
);

CREATE TABLE entry_events (
  id          TEXT    PRIMARY KEY,
  entry_id    TEXT    NOT NULL,
  kind        TEXT    NOT NULL CHECK (kind IN (
                'captured', 'edited', 'moved', 'tagged', 'untagged')),
  text        TEXT    NULL,
  to_bin      TEXT    NULL CHECK (to_bin IS NULL OR to_bin IN (
                'inbox', 'next', 'waiting', 'someday',
                'reference', 'done', 'trash')),
  tag_id      TEXT    NULL,
  device_id   TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  created_at  INTEGER NOT NULL,

  CHECK (
    (kind IN ('captured', 'edited')
       AND text   IS NOT NULL AND to_bin IS NULL AND tag_id IS NULL)
    OR (kind = 'moved'
       AND to_bin IS NOT NULL AND text IS NULL AND tag_id IS NULL)
    OR (kind IN ('tagged', 'untagged')
       AND tag_id IS NOT NULL AND text IS NULL AND to_bin IS NULL)
  )
);

CREATE TABLE tag_events (
  id          TEXT    PRIMARY KEY,
  tag_id      TEXT    NOT NULL,
  kind        TEXT    NOT NULL CHECK (kind IN (
                'created', 'renamed', 'archived', 'unarchived')),
  name        TEXT    NULL,
  device_id   TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  created_at  INTEGER NOT NULL,

  CHECK (
    (kind IN ('created', 'renamed') AND name IS NOT NULL)
    OR (kind IN ('archived', 'unarchived') AND name IS NULL)
  )
);

CREATE INDEX idx_entries_bin_created
  ON entries(bin, created_at DESC);

CREATE INDEX idx_entry_events_order
  ON entry_events(created_at, device_id, id);

CREATE INDEX idx_entry_events_entry_order
  ON entry_events(entry_id, created_at, device_id, id);

CREATE INDEX idx_entry_events_device
  ON entry_events(device_id);

CREATE INDEX idx_entry_tags_tag_id
  ON entry_tags(tag_id);

CREATE UNIQUE INDEX idx_tags_active_name
  ON tags(name)
  WHERE id = canonical_id;

CREATE INDEX idx_tags_canonical
  ON tags(canonical_id);

CREATE INDEX idx_tag_events_order
  ON tag_events(created_at, device_id, id);

CREATE INDEX idx_tag_events_tag_order
  ON tag_events(tag_id, created_at, device_id, id);

CREATE INDEX idx_tag_events_device
  ON tag_events(device_id);

CREATE INDEX idx_devices_last_seen
  ON devices(last_seen_at DESC);

CREATE VIEW active_tags AS
  SELECT id, name, created_at, archived_at
  FROM tags
  WHERE id = canonical_id;
