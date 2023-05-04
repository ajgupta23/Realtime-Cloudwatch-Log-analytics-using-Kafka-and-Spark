# Realtime-Cloudwatch-Log-analytics-using-Kafka-and-Spark
Cloudwatch Log analytics using Kafka (via Confluent) and Spark (via Databricks)

https://app.diagrams.net/#G1yjTUHxNf16MXb53skABiWsAe6v33GpZg

## Source Configuration
1. Create an EC2 Role with access to Cloudwatch. We will use this as instance profile for our EC2 instance.


        Role Name - CloudwatchRoleForEC2
        Policy -
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "cloudwatch:PutMetricData",
                        "ec2:DescribeTags",
                        "logs:PutLogEvents",
                        "logs:DescribeLogStreams",
                        "logs:DescribeLogGroups",
                        "logs:CreateLogStream",
                        "logs:CreateLogGroup"
                    ],
                    "Resource": "*"
                },
                {
                    "Effect": "Allow",
                    "Action": [
                        "ssm:GetParameter",
                        "ssm:PutParameter"
                    ],
                    "Resource": "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
                }
            ]
        }

2. Create a Security Group with:
    Security Group Name - CloudwatchSGForEC2

    a. Inbound rule to allow traffic from HTTPS and HTTP.

    b. Outbound rule to allow traffic from HTTPS and HTTP.

3. Create an EC2 instance with:

        AMI - amzn2-ami-kernel-5.10-hvm-2.0.20230404.1-x86_64-gp2
        Instance Name - CloudwatchLogsEC2
        Security Group - CloudwatchSGForEC2

4. Attach the role CloudwatchRoleForEC2 to this EC2 instance.

5. Now connect to the instance and then run the following commands:
    a. Install Apache server

        sudo yum install httpd -y

    b. Start apache service
        sudo service httpd start

    c. It's logs will get created in /var/log/httpd/access_log and error_log. We will stream this access log into kafka.

    d. access_log will get updated whenever we access public IP of the EC2 instance.

    e. Install the awslogs package. This is needed to send logs to cloudwatch.
        sudo yum install -y awslogs

    f. Configure your region in the file /etc/awslogs/awscli.conf
       Use the following command
        sudo nano /etc/awslogs/awscli.conf

       Change the content as follows to set the region to mumbai:
        [plugins]
        cwlogs = cwlogs
        [default]
        region = ap-south-1

    g. Configure what data you want to send to cloudwatch using the file /etc/awslogs/awslogs.conf

       Use the following command
        sudo nano /etc/awslogs/awslogs.conf

       Change the content as follows:
        [general]
        state_file = /var/lib/awslogs/agent-state
        [application_logs]
        region = ap-south-1
        datetime_format = %b %d %H:%M:%S
        file = /var/log/httpd/access_log
        buffer_duration = 5000
        log_stream_name = {instance_id}
        initial_position = start_of_file
        log_group_name = cloudwatchLogsEC2 
    h. Now we can start the logging using the following command:
        sudo systemctl start awslogsd
       This command will create a log group named cloudwatchLogsEC2 in Cloudwatch where the access_log will be available.

    NOTE - After instance restart run the following commands:
    sudo service httpd start
    sudo systemctl start awslogsd
Public IP of the server: http://13.126.116.49/

## Amazon CloudWatch Logs Source connector
1. Provide Kafka and AWS Keys.
2. Kafka Topic Format - ${log-group}.${log-stream}
3. Output Kafka record value format	- JSON
4. Amazon CloudWatch Logs Endpoint URL- https://logs.ap-south-1.amazonaws.com/
5. Amazon CloudWatch Logs Group Name - cloudwatchLogsEC2
6. AWS Poll Interval in Milliseconds - 1000      (Time in milliseconds (ms) the connector waits between polling the endpoint for updates. The default value is 1000 ms (1 second).)

        {
        "name": "CWSourceConnector",
        "config": {
            "connector.class": "CloudWatchLogsSource",
            "name": "CWSourceConnector",
            "kafka.auth.mode": "KAFKA_API_KEY",
            "kafka.api.key": "ZWZKDW7LOM5DMXI2",
            "kafka.api.secret": "****************************************************************",
            "kafka.topic.format": "${log-group}.${log-stream}",
            "output.data.format": "JSON",
            "aws.access.key.id": "********************",
            "aws.secret.access.key": "****************************************",
            "aws.cloudwatch.logs.url": "https://logs.ap-south-1.amazonaws.com/",
            "aws.cloudwatch.log.group": "cloudwatchLogsEC2",
            "aws.poll.interval.ms": "1000",
            "tasks.max": "1"
        }
        }

## Create S3 Sink Kafka Connector
1. Use the CW Topic that we created to read from.
2. Provide the Kafka and AWS Keys and then select the bucket.


        {
        "name": "S3_SINKConnector_2",
        "config": {
            "topics": "cloudwatchLogsEC2.i-02e3ca004943e0f26",
            "input.data.format": "JSON",
            "connector.class": "S3_SINK",
            "name": "S3_SINKConnector_2",
            "kafka.auth.mode": "KAFKA_API_KEY",
            "kafka.api.key": "LVNGF4ENNYKFDBMB",
            "kafka.api.secret": "****************************************************************",
            "aws.access.key.id": "********************",
            "aws.secret.access.key": "****************************************",
            "s3.bucket.name": "s3sink-3",
            "s3.part.size": "5242880",
            "s3.wan.mode": "false",
            "output.data.format": "JSON",
            "output.keys.format": "BYTES",
            "output.headers.format": "AVRO",
            "topics.dir": "topics",
            "path.format": "'year'=YYYY",
            "time.interval": "HOURLY",
            "rotate.schedule.interval.ms": "-1",
            "rotate.interval.ms": "10000",
            "flush.size": "1000",
            "behavior.on.null.values": "ignore",
            "timezone": "UTC",
            "subject.name.strategy": "TopicNameStrategy",
            "tombstone.encoded.partition": "tombstone",
            "enhanced.avro.schema.support": "true",
            "locale": "en",
            "s3.schema.partition.affix.type": "NONE",
            "schema.compatibility": "NONE",
            "store.kafka.keys": "true",
            "value.converter.connect.meta.data": "true",
            "store.kafka.headers": "false",
            "s3.object.tagging": "false",
            "tasks.max": "1"
        }
        }

## Databricks - Mount the S3 bucket

        import urllib
        --AWS S3 bucket name
        AWS_S3_BUCKET = "s3sink-3"
        --Mount name for the bucket
        MOUNT_NAME = "/mnt/s3sink-3"
        ACCESS_KEY = <Provide AWS Access Key>
        SECRET_KEY = <Provide AWS Secret Key>
        ENCODED_SECRET_KEY = urllib.parse.quote(string=SECRET_KEY, safe="")
        --Source url
        SOURCE_URL = "s3n://{0}:{1}@{2}".format(ACCESS_KEY, ENCODED_SECRET_KEY, AWS_S3_BUCKET)
        --Mount the drive
        dbutils.fs.mount(SOURCE_URL, MOUNT_NAME)

## Maxmind GeoLite2 City Database
Using Maxmind GeoLite2 City Database to get City and Country data for each IP.
Generated Maxmind License key and then using the below URL we can get the latest GeoLite2 City Binary (.mmdb) database:

        https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=YOUR_LICENSE_KEY&suffix=tar.gz

## Web server Log entry
A web server log entry is a record of a single request made to a web server. Each time a user visits a website or makes a request to a web server, the server generates a log entry that records information about the request. Web server log entries are useful for analyzing website traffic and identifying trends or issues with website performance. They can also be used to track user behavior and detect potential security threats.

Web server log entries typically include the following information:

        1. Client IP address: The IP address of the device that made the request.
        2. Identity: The identity of the user who made the request.
        3. Timestamp: The date and time at which the request was made.
        4. Request method: The HTTP method used to make the request (e.g. GET, POST).
        5. HTTP status code: The HTTP status code returned by the server in response to the request (e.g. 200, 404).
        6. Size of the response
        7. Referrer: The URL of the page that referred the user to the requested resource.
        8. User agent: Information about the client software used to make the request, including the browser and operating system.


Example of a web server log entry:

    "198.235.24.146 - - [21/Apr/2023:00:19:45 +0000] \"GET / HTTP/1.0\" 403 3630 \"-\" \"Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com\""

    Here's a breakdown of what each part of the log entry means:

    1. 198.235.24.146 - This is the IP address of the client that made the request to the server.
    2. - - This is the identity of the user who made the request. In this case, the identity is unknown.
    3. [21/Apr/2023:00:19:45 +0000] - This is the date and time when the request was made. The format is day/month/year:hour:minute:second timezone.
    4. "GET / HTTP/1.0" - This is the HTTP request method (GET), the requested URL (/), and the HTTP protocol version (HTTP/1.0).
    5. 403 - This is the HTTP status code returned by the server in response to the request. In this case, the code is 403, which means "Forbidden". This indicates that the server refused to fulfill the request due to a lack of proper authorization or authentication.
    6. 3630 - This is the size of the response sent back to the client, in bytes.
    7. "-" - This is the referrer URL, which is the URL of the previous web page that linked to the requested page. In this case, the referrer URL is unknown or not applicable.
    8. "Expanse, a Palo Alto Networks company..." - This is the user agent string sent by the client, which identifies the software or device used to make the request. In this case, the user agent string indicates that the request was made by a tool called "Expanse", which is a product of Palo Alto Networks that scans the internet to identify customers' online presences. The message also includes an email address to contact if the IP address/domain would like to be excluded from the scan.







## References

Install and configure the CloudWatch Logs agent on a running EC2 Linux instance - https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html

Confluent Cloud Amazon CloudWatch Logs Source connector - https://docs.confluent.io/cloud/current/connectors/cc-amazon-cloudwatch-logs-source.html#quick-start

Amazon S3 Sink Connector for Confluent - https://docs.confluent.io/cloud/current/connectors/cc-s3-sink.html

Maxmind API Docs - https://maxminddb.readthedocs.io/en/latest/

For Spark Functions - https://spark.apache.org/docs/latest/api/sql/index.html

For Databricks Joins - https://docs.databricks.com/sql/language-manual/sql-ref-syntax-qry-select-join.html

substring_index function - https://thegithubexperiment.blogspot.com/2023/04/substringindex-function-in-databricks.html

Word Cloud - https://monkeylearn.com/word-cloud/




