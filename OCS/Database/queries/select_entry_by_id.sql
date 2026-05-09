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
 WHERE e.id = :id
 LIMIT 1;
