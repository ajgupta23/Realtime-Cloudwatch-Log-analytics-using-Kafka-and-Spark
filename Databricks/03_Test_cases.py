%python
beforeStgCount = spark.sql("select COUNT(*) from cloudwatch_logs_analytics.cw_logs_staging_table").collect()[0][0]
print(beforeStgCount)


%sql
--Create table based on S3 bucket
drop table cloudwatch_logs_analytics.cw_logs_staging_table;

CREATE TABLE cloudwatch_logs_analytics.cw_logs_staging_table
USING text
OPTIONS (
  header "false"
)
LOCATION "/mnt/airbyte-shared-bucket-2/topics/cloudwatchLogsEC2.i-02e3ca004943e0f26/year=2023/";



%python
afterStgCount = spark.sql("select COUNT(*) from cloudwatch_logs_analytics.cw_logs_staging_table").collect()[0][0]
print(afterStgCount)

%python
# from pyspark.sql import Row
assert(afterStgCount >= beforeStgCount)
print("Test Case 1 Passed, Stage table successfully updated")

%python
# from pyspark.sql import Row
assert(afterStgCount > 0)
print("Test Case 2 Passed, Stage table records are non-zero")


%python
beforeDeltaCount = spark.sql("select COUNT(*) from cloudwatch_logs_analytics.cw_logs_delta_stg_table").collect()[0][0]
print(beforeDeltaCount)


%sql
-- update delta table
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


%python
afterDeltaCount = spark.sql("select COUNT(*) from cloudwatch_logs_analytics.cw_logs_delta_stg_table").collect()[0][0]
print(afterDeltaCount)


%python
# from pyspark.sql import Row
assert(afterDeltaCount >= beforeDeltaCount)
print("Test Case 3 Passed successfully, delta table updated successfully")

%python
# from pyspark.sql import Row
assert(afterDeltaCount > 0)
print("Test Case 4 Passed, Delta table records are non-zero")