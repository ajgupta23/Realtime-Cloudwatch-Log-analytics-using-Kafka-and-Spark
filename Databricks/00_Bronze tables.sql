%sql
--Create a Database
--Onetime activity
create DATABASE `cloudwatch_logs_analytics`;

%sql
--Create table based on S3 bucket
drop table cloudwatch_logs_analytics.cw_logs_staging_table;

CREATE TABLE cloudwatch_logs_analytics.cw_logs_staging_table
USING text
OPTIONS (
  header "false"
)
LOCATION "/mnt/airbyte-shared-bucket-2/topics/cloudwatchLogsEC2.i-02e3ca004943e0f26/year=2023/";

select COUNT(*) from cloudwatch_logs_analytics.cw_logs_staging_table

  %sql
-- Drop delta table if exists
-- #Onetime activity
 CREATE OR REPLACE TABLE cloudwatch_logs_analytics.cw_logs_delta_stg_table
 USING delta
 AS SELECT input_file_name() as filename, value
 FROM cloudwatch_logs_analytics.cw_logs_staging_table;

  %sql
-- Delete duplicate records
-- #Onetime activity
 delete from cloudwatch_logs_analytics.cw_logs_delta_stg_table a 
 where 
 (a.value IN (select b.value from cloudwatch_logs_analytics.cw_logs_delta_stg_table b where b.filename = a.filename) 
 and a.filename in (select min(c.filename) from cloudwatch_logs_analytics.cw_logs_delta_stg_table c where c.value = a.value))
 OR (a.value like 'Struct%');

%sql
-- Update delta table
insert into cloudwatch_logs_analytics.cw_logs_delta_stg_table 
select
  input_file_name() as filename,
  staging.value
from
  cloudwatch_logs_analytics.cw_logs_staging_table staging
where
  not exists(
    select
      *
    from
      cloudwatch_logs_analytics.cw_logs_delta_stg_table dlta
    where
      dlta.value = staging.value
  );