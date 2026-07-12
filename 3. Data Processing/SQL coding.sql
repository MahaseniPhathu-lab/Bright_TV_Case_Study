-- I wanted to see the whole table before I beging with my analysis
SELECT * 
FROM retail.default.bright_tv_user_profiles
limit 10;

--Checking for duplicates in my data
SELECT UserID,
       COUNT(*) AS duplicate_count
FROM retail.default.bright_tv_user_profiles
GROUP BY UserID
HAVING COUNT(*) > 1;

-- I am checking the size of the data
select COUNT(*) AS number_of_rows,
 COUNT(DISTINCT UserID ) AS number_subs
from retail.default.bright_tv_user_profiles;

--Are there any rows where UserID is NULL
SELECT COUNT(*) AS cnt
from retail.default.bright_tv_user_profiles
WHERE UserID IS NULL;

----
SELECT DISTINCT UserID
from retail.default.bright_tv_user_profiles;

--------------------------------------------------------
-- Gender checks
--------------------------------------------------------
SELECT DISTINCT gender
FROM retail.default.bright_tv_user_profiles
WHERE gender iS NULL;

--How many rows do we have where gender is NULL
SELECT COUNT(*)
FROM retail.default.bright_tv_user_profiles
WHERE gender = ' ';

--Count number of people using userID  per genger
SELECT COUNT(DISTINCT userid ) AS subs,
   CASE
     WHEN gender = ' ' THEN 'None'
     ELSE gender
END AS Gender
FROM retail.default.bright_tv_user_profiles
GROUP BY Gender;

---------------------------------------------------------------
--Race checks
---------------------------------------------------------------
SELECT DISTINCT Race
FROM retail.default.bright_tv_user_profiles;

--I am checking if there are rows where Race is NULL
SELECT COUNT(*) AS num_rows
FROM retail.default.bright_tv_user_profiles
WHERE Race IS NULL;

--Replace "empty" and "other" fields with None
SELECT DISTINCT
   CASE
     WHEN Race = 'other' THEN 'None'
     WHEN Race = ' ' THEN 'None'
  ELSE Race
  END AS Race
FROM retail.default.bright_tv_user_profiles;

-----------------------------------------------------------
--Province checks
-----------------------------------------------------------
SELECT DISTINCT Province
FROM retail.default.bright_tv_user_profiles;

SELECT DISTINCT
   CASE
     WHEN Province = ' ' THEN 'Uncategorized'
     WHEN Province = 'None' THEN 'Uncategorized'
     ELSE Province
END AS Region
FROM retail.default.bright_tv_user_profiles;

----------------------------------------------------------------
--Age checks
----------------------------------------------------------------
SELECT MIN(Age) AS min_age, -- = 0
       MAX(Age) AS max_age  -- = 114
FROM retail.default.bright_tv_user_profiles;

--Check if there is a row where age is NULL
SELECT COUNT(*) AS cnt
FROM retail.default.bright_tv_user_profiles
WHERE age is NULL;

--This is the first cte (user profile code)
WITH user_profiles AS (
SELECT UserID,
    CASE
     WHEN Province = ' ' THEN 'Uncategorized'
     WHEN Province = 'None' THEN 'Uncategorized'
     ELSE Province
END AS Region,

   CASE
     WHEN gender = ' ' THEN 'None'
     ELSE gender
END AS Gender,

    age,
    CASE
      WHEN age = 0 THEN 'Infants'
      WHEN age BETWEEN 1 AND 12 THEN 'Kids'
      WHEN age BETWEEN 13 AND 19 THEN 'Teenager'
      WHEN age BETWEEN 20 AND 35 THEN 'Youth'
      WHEN age BETWEEN 36 AND 50 THEN 'Adults'
      WHEN age BETWEEN 51 AND 65 THEN 'Elders'
      WHEN age>65 THEN 'Pensioners'
  END AS age_groups,

CASE
     WHEN Race iLike ('%other%') THEN 'None' --iLike filters the database on a specific pattern
     WHEN Race = ' ' THEN 'None'
  ELSE Race
  END AS Race,

Case
  WHEN  (Email IS NOT NULL) OR (Email<> ' ') OR (Email NOT IN ('None')) THEN 1
ELSE 0
END AS email_flag,

Case
  WHEN (`Social Media Handle` IS NOT NULL) OR (`Social Media Handle` != ' ') OR (`Social Media Handle` NOT IN ('None')) THEN 1
  ELSE 0
  END AS sm_flag

FROM retail.default.bright_tv_user_profiles
),
--This is the second cte (BrighTV viewership code)
viewership AS (

SELECT
   COALESCE(UserID0,userid4,0) AS userid, --Checks first column then go to the next one

   --DateS
   TO_CHAR(RecordDate2, 'yyyyMM') AS month_id, --TO_CHAR converts a date into a string &&& TO_DATE(): Converts a string into a date
    MONTHNAME(RecordDate2) AS month_name,
    DAYNAME(RecordDate2) AS day_name,
    DAYOFWEEK(RecordDate2) AS day_of_week,
    TO_DATE(RecordDate2) AS watch_date, --Extract the date from the timestamp in our table

       CASE
     WHEN DAYNAME(RecordDate2) IN ('Sat', 'Sun') THEN 'Weekend'
     ELSE 'Weekday'
     END AS day_classification,

    -- Time
    HOUR(RecordDate2) AS hour_of_day,
    date_format(RecordDate2, 'HH:mm:ss') AS watch_time,
    
    CASE
      WHEN watch_time BETWEEN '00:00:00' AND '05:59:59' THEN '01. Midnight'
      WHEN watch_time BETWEEN '06:00:00' AND '11:59:59' THEN '02. Morning'
      WHEN watch_time BETWEEN '12:00:00' AND '16:59:59' THEN '03. Afternoon'
      WHEN watch_time BETWEEN '17:00:00' AND '23:59:59' THEN '04. Evening'
    END AS time_of_day,

    date_format(`Duration 2`, 'HH:mm:ss') AS duration,
    CASE
      WHEN  duration BETWEEN '00:05:00' AND '00:10:00' THEN '01. Low usage: <30 mins'
      WHEN  duration BETWEEN '00:30:01' AND '00:59:59' THEN '02. Med usage <60 mins'
      WHEN  duration> '00:59:59' THEN '03. High usage >60 mins'
      ELSE '04. No Usage'
    END AS screen_time_bucket,

      CASE
    WHEN Channel2 IN ('SawSee', 'Sawsee') THEN 'SawSee'
    WHEN Channel2 IN ('SuperSport Live Events', 'Live on SuperSport', 'Supersport Live Events', 'DStv Events 1') THEN 'Live Events'
    ELSE Channel2
    END AS TV_Channel

FROM retail.default.bright_tv_viewership
)

SELECT COALESCE(A.UserID, B.UserID) AS sub_id,
       month_id,
       watch_date,
       day_of_week,
       day_name,
       day_classification,
       month_name,
       TV_channel,
       watch_time,
       hour_of_day,
       screen_time_bucket,
       --user_flag,
       duration,
       Region,
       age_groups,
       email_flag,
       sm_flag,
       Race,
       Gender
FROM viewership AS A
LEFT JOIN user_profiles AS B
ON A.UserID =B.UserID
GROUP BY ALL;





