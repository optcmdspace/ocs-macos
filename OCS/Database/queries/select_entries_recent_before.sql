SELECT id, text, created_at
  FROM entries
 WHERE created_at < ?
    OR (created_at = ? AND id < ?)
 ORDER BY created_at DESC, id DESC
 LIMIT ?;
