SELECT id
  FROM tags
 WHERE name = ?
   AND id = canonical_id
   AND archived_at IS NULL
 LIMIT 1;
