-- entry_events is rebuilt via a temp table because SQLite can't ALTER a CHECK, and the kind + payload
-- CHECKs widen for the new 'scheduled' kind. Safe to drop: nothing foreign-keys into entry_events.
-- The bin CHECKs deliberately keep retired 'next'/'someday' so a replayed or peer event is never rejected.

CREATE TABLE entry_events_new (
  id          TEXT    PRIMARY KEY,
  entry_id    TEXT    NOT NULL,
  kind        TEXT    NOT NULL CHECK (kind IN (
                'captured', 'edited', 'moved', 'tagged', 'untagged', 'scheduled')),
  text        TEXT    NULL,
  to_bin      TEXT    NULL CHECK (to_bin IS NULL OR to_bin IN (
                'inbox', 'next', 'waiting', 'someday',
                'reference', 'done', 'trash')),
  tag_id      TEXT    NULL,
  due_at      INTEGER NULL,
  device_id   TEXT    NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
  created_at  INTEGER NOT NULL,

  CHECK (
    (kind IN ('captured', 'edited')
       AND text IS NOT NULL AND to_bin IS NULL AND tag_id IS NULL AND due_at IS NULL)
    OR (kind = 'moved'
       AND to_bin IS NOT NULL AND text IS NULL AND tag_id IS NULL AND due_at IS NULL)
    OR (kind IN ('tagged', 'untagged')
       AND tag_id IS NOT NULL AND text IS NULL AND to_bin IS NULL AND due_at IS NULL)
    OR (kind = 'scheduled'
       AND text IS NULL AND to_bin IS NULL AND tag_id IS NULL)
  )
);

INSERT INTO entry_events_new (id, entry_id, kind, text, to_bin, tag_id, device_id, created_at)
  SELECT id, entry_id, kind, text, to_bin, tag_id, device_id, created_at FROM entry_events;

DROP TABLE entry_events;
ALTER TABLE entry_events_new RENAME TO entry_events;

CREATE INDEX idx_entry_events_order
  ON entry_events(created_at, device_id, id);
CREATE INDEX idx_entry_events_entry_order
  ON entry_events(entry_id, created_at, device_id, id);
CREATE INDEX idx_entry_events_device
  ON entry_events(device_id);

ALTER TABLE entries ADD COLUMN due_at INTEGER NULL;

-- Coerce any retired-bin row to inbox so it stays decodable (a no-op on real data; guards seeded rows).
UPDATE entries SET bin = 'inbox' WHERE bin IN ('next', 'someday');

CREATE INDEX idx_entries_due
  ON entries(due_at) WHERE due_at IS NOT NULL;
