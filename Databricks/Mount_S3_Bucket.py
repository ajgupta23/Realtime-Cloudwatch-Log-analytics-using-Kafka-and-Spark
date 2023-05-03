import urllib
#AWS S3 bucket name
AWS_S3_BUCKET = "s3sink-3"
#Mount name for the bucket
MOUNT_NAME = "/mnt/s3sink-3"
ACCESS_KEY = "Provide AWS Access Key"
SECRET_KEY = "Provide AWS Secret Key"
ENCODED_SECRET_KEY = urllib.parse.quote(string=SECRET_KEY, safe="")
#Source url
SOURCE_URL = "s3n://{0}:{1}@{2}".format(ACCESS_KEY, ENCODED_SECRET_KEY, AWS_S3_BUCKET)
#Mount the drive
dbutils.fs.mount(SOURCE_URL, MOUNT_NAME)