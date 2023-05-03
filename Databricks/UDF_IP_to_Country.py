pip install geoip2
%python
#Create UDF to convert IP to City, Country
import geoip2.database
from socket import inet_aton
from pyspark.sql.functions import udf
from pyspark.sql.types import StringType

# Define the UDF
def ip_to_location(ip):
    try:
        # Load the GeoLite2 database on each worker node
        with geoip2.database.Reader('/dbfs/mnt/s3sink-3/maxmindDB/GeoLite2-City.mmdb') as reader:
            response = reader.city(ip)
            city = response.city.name
            country = response.country.name
            #return f"{city}, {country}"
            return f"{country}"
    except Exception as e:
        return str(e)

# Register the UDF with Spark
ip_to_location_udf = udf(ip_to_location, StringType())
spark.udf.register("ip_to_location", ip_to_location_udf)
