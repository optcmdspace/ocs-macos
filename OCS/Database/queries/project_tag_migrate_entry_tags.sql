INSERT INTO entry_tags (entry_id, tag_id)
  SELECT entry_id, ?
    FROM entry_tags
   WHERE tag_id = ?
ON CONFLICT DO NOTHING;
