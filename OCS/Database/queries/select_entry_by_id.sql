SELECT id, text, bin, created_at
  FROM entries
 WHERE id = :id
 LIMIT 1;
