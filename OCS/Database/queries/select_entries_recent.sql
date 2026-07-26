SELECT e.id, e.text, e.bin, e.created_at, e.due_at,
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
   AND (? = 1 OR NOT (e.due_at IS NOT NULL AND e.due_at < ? AND e.bin != 'done'))
 ORDER BY (CASE WHEN e.bin = 'done' THEN 1 ELSE 0 END) ASC,
          COALESCE(e.due_at, 9223372036854775807) ASC,
          e.created_at DESC,
          e.id DESC
 LIMIT ?;
