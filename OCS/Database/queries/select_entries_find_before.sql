SELECT e.id, e.text, e.bin, e.created_at,
       (SELECT GROUP_CONCAT(name, ',') FROM (
          SELECT t.name
            FROM entry_tags et
            JOIN tags t ON t.id = et.tag_id
           WHERE et.entry_id = e.id
             AND t.id = t.canonical_id
           ORDER BY t.name
       )) AS tags
  FROM entries e
 WHERE e.bin != 'trash'
   AND (? = 1 OR e.bin != 'done')
   AND (? = 0 OR e.text LIKE ?)
   AND (
     ? = 0
     OR e.id IN (
       SELECT et.entry_id
         FROM entry_tags et
         JOIN tags t ON t.id = et.tag_id
        WHERE t.id = t.canonical_id
          AND t.name IN (SELECT value FROM json_each(?))
        GROUP BY et.entry_id
       HAVING COUNT(DISTINCT t.name) = ?
     )
   )
   AND (e.created_at < ?
        OR (e.created_at = ? AND e.id < ?))
 ORDER BY e.created_at DESC, e.id DESC
 LIMIT ?;
