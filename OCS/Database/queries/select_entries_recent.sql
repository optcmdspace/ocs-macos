SELECT id, text, created_at
  FROM entries
 ORDER BY created_at DESC
 LIMIT ?;
