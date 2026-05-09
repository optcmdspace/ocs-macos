SELECT e.id, e.text, e.bin, e.created_at,
       (SELECT GROUP_CONCAT(name, ',') FROM (
          SELECT t2.name
            FROM entry_tags et2
            JOIN tags t2 ON t2.id = et2.tag_id
           WHERE et2.entry_id = e.id
             AND t2.id = t2.canonical_id
           ORDER BY t2.name
       )) AS tags
  FROM entries e
  JOIN entry_tags et ON et.entry_id = e.id
  JOIN tags t ON t.id = et.tag_id
 WHERE t.name = ?
   AND t.id = t.canonical_id
   AND e.bin != 'trash'
   AND (? = 1 OR e.bin != 'done')
   AND (e.created_at < ?
        OR (e.created_at = ? AND e.id < ?))
 ORDER BY e.created_at DESC, e.id DESC
 LIMIT ?;
