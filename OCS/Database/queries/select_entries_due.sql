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
 WHERE e.due_at IS NOT NULL
   AND e.bin NOT IN ('done', 'trash')
 ORDER BY e.due_at ASC, e.id ASC
 LIMIT ?;
