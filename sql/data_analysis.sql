-- ============================================================
-- Bellabeat Data Analysis
-- Google Data Analytics Capstone
-- Tool: Google BigQuery
--
-- This script contains the SQL queries used to analyze
-- Fitbit activity, sleep, and hourly usage patterns.
-- ============================================================


-- ============================================================
-- 1. DAILY ACTIVITY SUMMARY
-- ============================================================

SELECT
  ROUND(AVG(TotalSteps), 0) AS avg_daily_steps,
  ROUND(AVG(Calories), 0) AS avg_daily_calories,
  ROUND(AVG(VeryActiveMinutes), 1) AS avg_very_active_minutes,
  ROUND(AVG(FairlyActiveMinutes), 1) AS avg_fairly_active_minutes,
  ROUND(AVG(LightlyActiveMinutes), 1) AS avg_lightly_active_minutes,
  ROUND(AVG(SedentaryMinutes), 1) AS avg_sedentary_minutes,
  ROUND(
    AVG(
      VeryActiveMinutes
      + FairlyActiveMinutes
      + LightlyActiveMinutes
    ),
    1
  ) AS avg_total_active_minutes
FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`;


-- ============================================================
-- 2. ACTIVITY BY DAY OF WEEK
-- ============================================================

SELECT
  FORMAT_DATE('%A', ActivityDate) AS day_of_week,
  ROUND(AVG(TotalSteps), 0) AS avg_steps,
  ROUND(
    AVG(
      VeryActiveMinutes
      + FairlyActiveMinutes
      + LightlyActiveMinutes
    ),
    1
  ) AS avg_active_minutes,
  ROUND(AVG(SedentaryMinutes), 1) AS avg_sedentary_minutes,
  ROUND(AVG(Calories), 0) AS avg_calories
FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`
GROUP BY
  day_of_week,
  EXTRACT(DAYOFWEEK FROM ActivityDate)
ORDER BY
  EXTRACT(DAYOFWEEK FROM ActivityDate);


-- ============================================================
-- 3. CORRELATION BETWEEN STEPS AND CALORIES
-- ============================================================

SELECT
  ROUND(CORR(TotalSteps, Calories), 3) AS steps_calories_correlation
FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`;


-- ============================================================
-- 4. SLEEP SUMMARY
-- ============================================================

SELECT
  ROUND(AVG(TotalMinutesAsleep) / 60, 2) AS avg_sleep_hours,
  ROUND(AVG(TotalTimeInBed) / 60, 2) AS avg_hours_in_bed,
  ROUND(
    AVG(
      SAFE_DIVIDE(TotalMinutesAsleep, TotalTimeInBed) * 100
    ),
    1
  ) AS avg_sleep_efficiency,
  ROUND(MIN(TotalMinutesAsleep) / 60, 2) AS min_sleep_hours,
  ROUND(MAX(TotalMinutesAsleep) / 60, 2) AS max_sleep_hours
FROM
  `arctic-odyssey-512009-e3.bellabeat.sleep_day_clean`;


-- ============================================================
-- 5. RELATIONSHIP BETWEEN ACTIVITY AND SLEEP
-- ============================================================

SELECT
  ROUND(
    CORR(a.TotalSteps, s.TotalMinutesAsleep),
    3
  ) AS steps_sleep_correlation,

  ROUND(
    CORR(
      a.VeryActiveMinutes
      + a.FairlyActiveMinutes
      + a.LightlyActiveMinutes,
      s.TotalMinutesAsleep
    ),
    3
  ) AS active_minutes_sleep_correlation,

  ROUND(
    CORR(a.SedentaryMinutes, s.TotalMinutesAsleep),
    3
  ) AS sedentary_sleep_correlation

FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean` a

INNER JOIN
  `arctic-odyssey-512009-e3.bellabeat.sleep_day_clean` s

ON
  a.Id = s.Id
  AND a.ActivityDate = s.SleepDate;


-- ============================================================
-- 6. HOURLY ACTIVITY PATTERNS
-- ============================================================

SELECT
  EXTRACT(HOUR FROM s.ActivityHour) AS hour_of_day,
  ROUND(AVG(s.StepTotal), 1) AS avg_steps,
  ROUND(AVG(i.TotalIntensity), 1) AS avg_total_intensity,
  ROUND(AVG(i.AverageIntensity), 3) AS avg_intensity
FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_steps_clean` s

INNER JOIN
  `arctic-odyssey-512009-e3.bellabeat.hourly_intensity_clean` i

ON
  s.Id = i.Id
  AND s.ActivityHour = i.ActivityHour

GROUP BY
  hour_of_day

ORDER BY
  hour_of_day;


-- ============================================================
-- 7. TOP 5 MOST ACTIVE HOURS
-- ============================================================

SELECT
  EXTRACT(HOUR FROM s.ActivityHour) AS hour_of_day,
  ROUND(AVG(s.StepTotal), 1) AS avg_steps,
  ROUND(AVG(i.TotalIntensity), 1) AS avg_total_intensity,
  ROUND(AVG(i.AverageIntensity), 3) AS avg_intensity
FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_steps_clean` s

INNER JOIN
  `arctic-odyssey-512009-e3.bellabeat.hourly_intensity_clean` i

ON
  s.Id = i.Id
  AND s.ActivityHour = i.ActivityHour

GROUP BY
  hour_of_day

ORDER BY
  avg_steps DESC

LIMIT 5;


-- ============================================================
-- 8. USER ACTIVITY SEGMENTATION
-- Categories were created for exploratory analysis.
-- ============================================================

WITH user_activity AS (
  SELECT
    Id,
    ROUND(AVG(TotalSteps), 0) AS avg_daily_steps
  FROM
    `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`
  GROUP BY
    Id
)

SELECT
  CASE
    WHEN avg_daily_steps < 5000 THEN 'Low Activity'
    WHEN avg_daily_steps < 7500 THEN 'Somewhat Active'
    WHEN avg_daily_steps < 10000 THEN 'Active'
    ELSE 'Highly Active'
  END AS activity_segment,

  COUNT(*) AS users,

  ROUND(AVG(avg_daily_steps), 0) AS avg_steps_in_segment

FROM
  user_activity

GROUP BY
  activity_segment

ORDER BY
  avg_steps_in_segment;


-- ============================================================
-- 9. ACTIVITY TRACKING CONSISTENCY
-- ============================================================

WITH user_usage AS (
  SELECT
    Id,
    COUNT(DISTINCT ActivityDate) AS days_tracked
  FROM
    `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`
  GROUP BY
    Id
)

SELECT
  ROUND(AVG(days_tracked), 1) AS avg_days_tracked,
  MIN(days_tracked) AS min_days_tracked,
  MAX(days_tracked) AS max_days_tracked,
  COUNTIF(days_tracked = 31) AS users_with_full_31_days,
  COUNTIF(days_tracked >= 21) AS users_with_21_plus_days,
  COUNTIF(days_tracked < 21) AS users_with_under_21_days
FROM
  user_usage;


-- ============================================================
-- 10. SLEEP TRACKING CONSISTENCY
-- ============================================================

WITH sleep_usage AS (
  SELECT
    Id,
    COUNT(DISTINCT SleepDate) AS days_sleep_tracked
  FROM
    `arctic-odyssey-512009-e3.bellabeat.sleep_day_clean`
  GROUP BY
    Id
)

SELECT
  COUNT(*) AS users_with_sleep_data,
  ROUND(AVG(days_sleep_tracked), 1) AS avg_sleep_days_tracked,
  MIN(days_sleep_tracked) AS min_sleep_days_tracked,
  MAX(days_sleep_tracked) AS max_sleep_days_tracked,
  COUNTIF(days_sleep_tracked = 31) AS users_with_full_31_days,
  COUNTIF(days_sleep_tracked >= 21) AS users_with_21_plus_days,
  COUNTIF(days_sleep_tracked < 21) AS users_with_under_21_days
FROM
  sleep_usage;


-- ============================================================
-- 11. SLEEP DURATION DISTRIBUTION
-- ============================================================

SELECT
  CASE
    WHEN TotalMinutesAsleep < 360 THEN 'Under 6 hours'
    WHEN TotalMinutesAsleep < 420 THEN '6 to under 7 hours'
    WHEN TotalMinutesAsleep < 480 THEN '7 to under 8 hours'
    ELSE '8+ hours'
  END AS sleep_duration_group,

  COUNT(*) AS sleep_records,

  ROUND(
    COUNT(*) * 100.0 /
    SUM(COUNT(*)) OVER (),
    1
  ) AS percent_of_records

FROM
  `arctic-odyssey-512009-e3.bellabeat.sleep_day_clean`

GROUP BY
  sleep_duration_group

ORDER BY
  MIN(TotalMinutesAsleep);


-- ============================================================
-- 12. TABLEAU EXPORT: DAILY STEPS VS. CALORIES
-- ============================================================

SELECT
  Id,
  ActivityDate,
  TotalSteps,
  Calories
FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`;


-- ============================================================
-- 13. TABLEAU EXPORT: HOURLY ACTIVITY
-- ============================================================

SELECT
  EXTRACT(HOUR FROM s.ActivityHour) AS hour_of_day,
  ROUND(AVG(s.StepTotal), 1) AS avg_steps,
  ROUND(AVG(i.TotalIntensity), 1) AS avg_total_intensity
FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_steps_clean` s

INNER JOIN
  `arctic-odyssey-512009-e3.bellabeat.hourly_intensity_clean` i

ON
  s.Id = i.Id
  AND s.ActivityHour = i.ActivityHour

GROUP BY
  hour_of_day

ORDER BY
  hour_of_day;


-- ============================================================
-- 14. TABLEAU EXPORT: TRACKING CONSISTENCY
-- ============================================================

SELECT
  'Activity Tracking' AS tracking_type,
  28.5 AS avg_days_tracked

UNION ALL

SELECT
  'Sleep Tracking' AS tracking_type,
  17.1 AS avg_days_tracked;
