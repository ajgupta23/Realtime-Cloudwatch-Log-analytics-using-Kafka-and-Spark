create view cloudwatch_logs_analytics.server_logs_transformed as
SELECT
  SUBSTRING_INDEX(SUBSTRING_INDEX(value, ' ', 1), '"', -1) AS ip_address,
  to_timestamp(
    SUBSTRING_INDEX(SUBSTRING_INDEX(value, ']', 1), '[', -1),
    'dd/MMM/yyyy:HH:mm:ss Z'
  ) AS date_time,
  REPLACE(
    SUBSTRING_INDEX(SUBSTRING_INDEX(value, '\"', 3), '\"', -1),
    "\\",
    ""
  ) AS request_method,
  SUBSTRING_INDEX(
    SUBSTRING_INDEX(SUBSTRING_INDEX(value, '\"', 4), '\"', -1),
    " ",
    2
  ) AS status_code,
  SUBSTRING_INDEX(
    SUBSTRING_INDEX(
      SUBSTRING_INDEX(SUBSTRING_INDEX(value, '\"', 4), '\"', -1),
      " ",
      -2
    ),
    " ",
    1
  ) AS response_size,
  SUBSTRING_INDEX(
    SUBSTRING_INDEX(SUBSTRING_INDEX(value, '"', 5), '\"', -1),
    "\\",
    1
  ) AS referrer,
  REPLACE(
    SUBSTRING_INDEX(SUBSTRING_INDEX(value, '\"', 7), '\"', -1),
    "\\",
    ""
  ) AS user_agent -- extract user agent
,
  value
FROM
  cloudwatch_logs_analytics.cw_logs_delta_stg_table;