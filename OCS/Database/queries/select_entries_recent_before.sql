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
   AND (:includeDone = 1 OR e.bin != 'done')
   AND (:includeOverdue = 1 OR NOT (e.due_at IS NOT NULL AND e.due_at < :overdueBefore AND e.bin != 'done'))
   AND (
     (CASE WHEN e.bin = 'done' THEN 1 ELSE 0 END) > :doneRank
     OR ((CASE WHEN e.bin = 'done' THEN 1 ELSE 0 END) = :doneRank
         AND COALESCE(e.due_at, 9223372036854775807) > :effectiveDue)
     OR ((CASE WHEN e.bin = 'done' THEN 1 ELSE 0 END) = :doneRank
         AND COALESCE(e.due_at, 9223372036854775807) = :effectiveDue
         AND e.created_at < :createdAt)
     OR ((CASE WHEN e.bin = 'done' THEN 1 ELSE 0 END) = :doneRank
         AND COALESCE(e.due_at, 9223372036854775807) = :effectiveDue
         AND e.created_at = :createdAt
         AND e.id < :id)
   )
 ORDER BY (CASE WHEN e.bin = 'done' THEN 1 ELSE 0 END) ASC,
          COALESCE(e.due_at, 9223372036854775807) ASC,
          e.created_at DESC,
          e.id DESC
 LIMIT :limit;
