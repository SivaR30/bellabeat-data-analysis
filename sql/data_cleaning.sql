-- ============================================================
-- Bellabeat Data Cleaning and Validation
-- Google Data Analytics Capstone
-- Tool: Google BigQuery
--
-- This script documents the quality checks, cleaning,
-- date/time transformations, and validation steps used
-- to prepare the Fitbit datasets for analysis.
-- ============================================================


-- ============================================================
-- 1. CHECK ROW COUNTS AND UNIQUE USERS
-- ============================================================

SELECT
  'daily_activity' AS table_name,
  COUNT(*) AS row_count,
  COUNT(DISTINCT CAST(Id AS STRING)) AS unique_users
FROM `arctic-odyssey-512009-e3.bellabeat.daily_activity`

UNION ALL

SELECT
  'sleep_day',
  COUNT(*),
  COUNT(DISTINCT CAST(Id AS STRING))
FROM `arctic-odyssey-512009-e3.bellabeat.sleep_day`

UNION ALL

SELECT
  'hourly_steps',
  COUNT(*),
  COUNT(DISTINCT CAST(Id AS STRING))
FROM `arctic-odyssey-512009-e3.bellabeat.hourly_steps`

UNION ALL

SELECT
  'hourly_intensity',
  COUNT(*),
  COUNT(DISTINCT CAST(Id AS STRING))
FROM `arctic-odyssey-512009-e3.bellabeat.hourly_intensity`;


-- ============================================================
-- 2. CHECK FOR DUPLICATE USER-DATE / USER-HOUR RECORDS
-- ============================================================

WITH daily_duplicates AS (
  SELECT
    Id,
    ActivityDate,
    COUNT(*) AS row_count
  FROM `arctic-odyssey-512009-e3.bellabeat.daily_activity`
  GROUP BY Id, ActivityDate
  HAVING COUNT(*) > 1
),

sleep_duplicates AS (
  SELECT
    Id,
    SleepDay,
    COUNT(*) AS row_count
  FROM `arctic-odyssey-512009-e3.bellabeat.sleep_day`
  GROUP BY Id, SleepDay
  HAVING COUNT(*) > 1
),

hourly_steps_duplicates AS (
  SELECT
    Id,
    ActivityHour,
    COUNT(*) AS row_count
  FROM `arctic-odyssey-512009-e3.bellabeat.hourly_steps`
  GROUP BY Id, ActivityHour
  HAVING COUNT(*) > 1
),

hourly_intensity_duplicates AS (
  SELECT
    Id,
    ActivityHour,
    COUNT(*) AS row_count
  FROM `arctic-odyssey-512009-e3.bellabeat.hourly_intensity`
  GROUP BY Id, ActivityHour
  HAVING COUNT(*) > 1
)

SELECT
  'daily_activity' AS table_name,
  COUNT(*) AS duplicate_groups,
  COALESCE(SUM(row_count - 1), 0) AS extra_duplicate_rows
FROM daily_duplicates

UNION ALL

SELECT
  'sleep_day',
  COUNT(*),
  COALESCE(SUM(row_count - 1), 0)
FROM sleep_duplicates

UNION ALL

SELECT
  'hourly_steps',
  COUNT(*),
  COALESCE(SUM(row_count - 1), 0)
FROM hourly_steps_duplicates

UNION ALL

SELECT
  'hourly_intensity',
  COUNT(*),
  COALESCE(SUM(row_count - 1), 0)
FROM hourly_intensity_duplicates;


-- Result:
-- daily_activity: 0 duplicate groups
-- sleep_day: 3 duplicate groups / 3 extra duplicate rows
-- hourly_steps: 0 duplicate groups
-- hourly_intensity: 0 duplicate groups


-- ============================================================
-- 3. CHECK FOR NULL VALUES
-- ============================================================

SELECT
  'daily_activity' AS table_name,
  COUNTIF(Id IS NULL) AS missing_id,
  COUNTIF(ActivityDate IS NULL) AS missing_datetime,
  COUNTIF(TotalSteps IS NULL) AS missing_measure_1,
  COUNTIF(Calories IS NULL) AS missing_measure_2
FROM `arctic-odyssey-512009-e3.bellabeat.daily_activity`

UNION ALL

SELECT
  'sleep_day',
  COUNTIF(Id IS NULL),
  COUNTIF(SleepDay IS NULL),
  COUNTIF(TotalMinutesAsleep IS NULL),
  COUNTIF(TotalTimeInBed IS NULL)
FROM `arctic-odyssey-512009-e3.bellabeat.sleep_day`

UNION ALL

SELECT
  'hourly_steps',
  COUNTIF(Id IS NULL),
  COUNTIF(ActivityHour IS NULL),
  COUNTIF(StepTotal IS NULL),
  NULL
FROM `arctic-odyssey-512009-e3.bellabeat.hourly_steps`

UNION ALL

SELECT
  'hourly_intensity',
  COUNTIF(Id IS NULL),
  COUNTIF(ActivityHour IS NULL),
  COUNTIF(TotalIntensity IS NULL),
  COUNTIF(AverageIntensity IS NULL)
FROM `arctic-odyssey-512009-e3.bellabeat.hourly_intensity`;


-- Result:
-- No null values were found in the fields checked.


-- ============================================================
-- 4. CREATE CLEAN DAILY ACTIVITY TABLE
-- ============================================================

CREATE OR REPLACE TABLE
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean` AS

SELECT
  CAST(Id AS INT64) AS Id,

  COALESCE(
    SAFE_CAST(ActivityDate AS DATE),
    SAFE.PARSE_DATE('%m/%d/%Y', CAST(ActivityDate AS STRING))
  ) AS ActivityDate,

  CAST(TotalSteps AS INT64) AS TotalSteps,
  CAST(TotalDistance AS FLOAT64) AS TotalDistance,
  CAST(TrackerDistance AS FLOAT64) AS TrackerDistance,
  CAST(LoggedActivitiesDistance AS FLOAT64) AS LoggedActivitiesDistance,
  CAST(VeryActiveDistance AS FLOAT64) AS VeryActiveDistance,
  CAST(ModeratelyActiveDistance AS FLOAT64) AS ModeratelyActiveDistance,
  CAST(LightActiveDistance AS FLOAT64) AS LightActiveDistance,
  CAST(SedentaryActiveDistance AS FLOAT64) AS SedentaryActiveDistance,
  CAST(VeryActiveMinutes AS INT64) AS VeryActiveMinutes,
  CAST(FairlyActiveMinutes AS INT64) AS FairlyActiveMinutes,
  CAST(LightlyActiveMinutes AS INT64) AS LightlyActiveMinutes,
  CAST(SedentaryMinutes AS INT64) AS SedentaryMinutes,
  CAST(Calories AS INT64) AS Calories

FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity`;


-- Verify cleaned daily activity table

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT Id) AS unique_users,
  MIN(ActivityDate) AS first_date,
  MAX(ActivityDate) AS last_date,
  COUNTIF(ActivityDate IS NULL) AS invalid_dates
FROM
  `arctic-odyssey-512009-e3.bellabeat.daily_activity_clean`;


-- Expected:
-- 940 rows
-- 33 users
-- 2016-04-12 to 2016-05-12
-- 0 invalid dates


-- ============================================================
-- 5. CREATE CLEAN SLEEP TABLE
-- Remove duplicate rows and convert SleepDay to DATE.
-- ============================================================

CREATE OR REPLACE TABLE
  `arctic-odyssey-512009-e3.bellabeat.sleep_day_clean` AS

SELECT DISTINCT
  CAST(Id AS INT64) AS Id,

  DATE(
    PARSE_DATETIME(
      '%m/%d/%Y %I:%M:%S %p',
      SleepDay
    )
  ) AS SleepDate,

  CAST(TotalSleepRecords AS INT64) AS TotalSleepRecords,
  CAST(TotalMinutesAsleep AS INT64) AS TotalMinutesAsleep,
  CAST(TotalTimeInBed AS INT64) AS TotalTimeInBed

FROM
  `arctic-odyssey-512009-e3.bellabeat.sleep_day`;


-- Verify cleaned sleep table

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT Id) AS unique_users,
  MIN(SleepDate) AS first_date,
  MAX(SleepDate) AS last_date,
  COUNTIF(SleepDate IS NULL) AS invalid_dates
FROM
  `arctic-odyssey-512009-e3.bellabeat.sleep_day_clean`;


-- Expected:
-- 410 rows after removing 3 duplicates
-- 24 users
-- 2016-04-12 to 2016-05-12
-- 0 invalid dates


-- ============================================================
-- 6. CREATE CLEAN HOURLY STEPS TABLE
-- ============================================================

CREATE OR REPLACE TABLE
  `arctic-odyssey-512009-e3.bellabeat.hourly_steps_clean` AS

SELECT
  CAST(Id AS INT64) AS Id,

  PARSE_DATETIME(
    '%m/%d/%Y %I:%M:%S %p',
    ActivityHour
  ) AS ActivityHour,

  CAST(StepTotal AS INT64) AS StepTotal

FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_steps`;


-- Verify cleaned hourly steps table

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT Id) AS unique_users,
  MIN(ActivityHour) AS first_hour,
  MAX(ActivityHour) AS last_hour,
  COUNTIF(ActivityHour IS NULL) AS invalid_datetimes
FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_steps_clean`;


-- Expected:
-- 22,099 rows
-- 33 users
-- 0 invalid datetimes


-- ============================================================
-- 7. CREATE CLEAN HOURLY INTENSITY TABLE
-- ============================================================

CREATE OR REPLACE TABLE
  `arctic-odyssey-512009-e3.bellabeat.hourly_intensity_clean` AS

SELECT
  CAST(Id AS INT64) AS Id,

  PARSE_DATETIME(
    '%m/%d/%Y %I:%M:%S %p',
    ActivityHour
  ) AS ActivityHour,

  CAST(TotalIntensity AS INT64) AS TotalIntensity,
  CAST(AverageIntensity AS FLOAT64) AS AverageIntensity

FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_intensity`;


-- Verify cleaned hourly intensity table

SELECT
  COUNT(*) AS row_count,
  COUNT(DISTINCT Id) AS unique_users,
  MIN(ActivityHour) AS first_hour,
  MAX(ActivityHour) AS last_hour,
  COUNTIF(ActivityHour IS NULL) AS invalid_datetimes
FROM
  `arctic-odyssey-512009-e3.bellabeat.hourly_intensity_clean`;


-- Expected:
-- 22,099 rows
-- 33 users
-- 0 invalid datetimes
