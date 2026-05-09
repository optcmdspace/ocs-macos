SELECT t.name, COUNT(et.entry_id) AS uses
  FROM tags t
  LEFT JOIN entry_tags et ON et.tag_id = t.id
 WHERE t.id = t.canonical_id
   AND t.archived_at IS NULL
   AND t.name LIKE ? || '%'
 GROUP BY t.id
 ORDER BY uses DESC, t.name ASC
 LIMIT ?;
