INSERT INTO entry_tags (entry_id, tag_id)
VALUES (?, ?)
ON CONFLICT DO NOTHING;
