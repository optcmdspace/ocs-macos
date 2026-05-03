SELECT id, text, bin, created_at
  FROM entries
 WHERE bin != 'trash'
   AND (? = 1 OR bin != 'done')
 ORDER BY created_at DESC, id DESC
 LIMIT ?;
