  %sql
-- Analysis 1, browser type
create or replace table cloudwatch_logs_analytics.browsers as
select
  case
    when user_agent like '%Firefox%' then 'Mozilla Firefox'
    when user_agent like '%Chrome%' then 'Google Chrome'
    when user_agent like '%Safari%' then 'Apple Safari'
    else 'Others'
  end as browser,
  COUNT(user_agent) as number_of_requests
from
  cloudwatch_logs_analytics.server_logs_transformed
group by
  1;

%sql
-- Analysis 2, requests by country
create
or replace table cloudwatch_logs_analytics.requests_by_country as
select
  ip_to_location(ip_address) as request_location,
  count(ip_address) as number_of_requests
from
  cloudwatch_logs_analytics.server_logs_transformed
GROUP BY
  1
order by
  2 desc
limit
  10;

%sql
-- Analysis 3, most requests from IP and total response size
create or replace table cloudwatch_logs_analytics.requests_by_response_size as
SELECT
  COUNT(*) as request_count,
  ip_address,
  ip_to_location(ip_address) as request_location,
  ROUND(sum(
    decode(
      response_size,
      '-',
      0,
      (NVL(response_size, 0))
    )
  ) / 1024,0) as response_size_in_kb
FROM
  cloudwatch_logs_analytics.server_logs_transformed
GROUP BY
  ip_address
order by
  response_size_in_kb desc;

%sql
-- Analysis 4, Number of failed requests
create or replace table cloudwatch_logs_analytics.failed_requests_type as
select
  status_code,
  COUNT(ip_address) as request_count
from
  cloudwatch_logs_analytics.server_logs_transformed
where
  status_code <> 200
GROUP BY
  status_code

%sql
-- Analysis 5, number of requests made per day
create
or replace table cloudwatch_logs_analytics.requests_per_day as
SELECT
  COUNT(*) as request_count,
  DATE_TRUNC('day', date_time) as request_date
FROM
  cloudwatch_logs_analytics.server_logs_transformed
GROUP BY
  request_date
ORDER BY
  request_date;

%sql
-- Analysis 6, which time of day receives most traffic
create
or replace table cloudwatch_logs_analytics.requests_each_day as
SELECT
  CASE
    WHEN HOUR(date_time) BETWEEN 0
    AND 5 THEN 'Q1: Early morning 0 to 5'
    WHEN HOUR(date_time) BETWEEN 6
    AND 11 THEN 'Q2: Morning 6 to 11'
    WHEN HOUR(date_time) BETWEEN 12
    AND 17 THEN 'Q3: Afternoon 12 to 17'
    WHEN HOUR(date_time) BETWEEN 18
    AND 23 THEN 'Q4: Evening 18 to 23'
  END AS quarter_of_day,
  COUNT(*) AS requests
FROM
  cloudwatch_logs_analytics.server_logs_transformed
GROUP BY
  quarter_of_day
ORDER BY
  requests DESC;

%sql
-- Analysis 7, total_requests
create
or replace table cloudwatch_logs_analytics.total_requests_count as
select
  COUNT(*) total_requests
from
  cloudwatch_logs_analytics.server_logs_transformed;

%sql
-- Analysis 8, failed_requests
create
or replace table cloudwatch_logs_analytics.failed_requests_count as
select
  COUNT(*) failed_requests
from
  cloudwatch_logs_analytics.server_logs_transformed
where
  status_code <> 200;

%sql
-- Analysis 9, data_served
create
or replace table cloudwatch_logs_analytics.data_served as
select
  ROUND(
    sum(
      decode(
        response_size,
        '-',
        0,
        (NVL(response_size, 0))
      )
    ) / 1024,
    0
  ) as response_size_in_kb
from
  cloudwatch_logs_analytics.server_logs_transformed;



