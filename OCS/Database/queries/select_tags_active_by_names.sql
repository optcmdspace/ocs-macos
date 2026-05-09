SELECT name, id
  FROM tags
 WHERE id = canonical_id
   AND archived_at IS NULL
   AND name IN (SELECT value FROM json_each(?));
