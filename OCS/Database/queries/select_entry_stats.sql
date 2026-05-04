SELECT
  COALESCE(SUM(CASE WHEN bin != 'trash' AND created_at >= :todayStart THEN 1 ELSE 0 END), 0)                                  AS today_count,
  COALESCE(SUM(CASE WHEN bin != 'trash' AND created_at >= :yesterdayStart AND created_at < :todayStart THEN 1 ELSE 0 END), 0) AS yesterday_count,
  COALESCE(SUM(CASE WHEN bin NOT IN ('done', 'trash') THEN 1 ELSE 0 END), 0)                                                  AS active_count,
  COALESCE(SUM(CASE WHEN bin NOT IN ('done', 'trash') AND created_at < :staleCutoff THEN 1 ELSE 0 END), 0)                    AS stale_active_count
  FROM entries;
