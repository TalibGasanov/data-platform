FROM apache/spark:4.1.2-python3

USER root

ARG DELTA_VERSION=4.1.0
ARG HADOOP_AWS_VERSION=3.4.2
ARG AWS_SDK_BUNDLE_VERSION=2.29.52
ARG SPARK_VERSION=4.1.2
ARG KAFKA_CLIENTS_VERSION=3.9.1
ARG COMMONS_POOL2_VERSION=2.12.0
ARG MSSQL_JDBC_VERSION=12.8.1.jre11

RUN apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/*

# Download each jar from Maven Central and verify it against the published .sha1
RUN set -eux; \
    base=https://repo1.maven.org/maven2; \
    fetch() { \
      path="$1"; file="/opt/spark/jars/$(basename "$path")"; \
      wget -q -O "$file" "$base/$path"; \
      echo "$(wget -q -O - "$base/$path.sha1" | cut -d' ' -f1)  $file" | sha1sum -c -; \
    }; \
    fetch io/delta/delta-spark_2.13/${DELTA_VERSION}/delta-spark_2.13-${DELTA_VERSION}.jar; \
    fetch io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar; \
    fetch org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar; \
    fetch software/amazon/awssdk/bundle/${AWS_SDK_BUNDLE_VERSION}/bundle-${AWS_SDK_BUNDLE_VERSION}.jar; \
    fetch org/apache/spark/spark-sql-kafka-0-10_2.13/${SPARK_VERSION}/spark-sql-kafka-0-10_2.13-${SPARK_VERSION}.jar; \
    fetch org/apache/spark/spark-token-provider-kafka-0-10_2.13/${SPARK_VERSION}/spark-token-provider-kafka-0-10_2.13-${SPARK_VERSION}.jar; \
    fetch org/apache/kafka/kafka-clients/${KAFKA_CLIENTS_VERSION}/kafka-clients-${KAFKA_CLIENTS_VERSION}.jar; \
    fetch org/apache/commons/commons-pool2/${COMMONS_POOL2_VERSION}/commons-pool2-${COMMONS_POOL2_VERSION}.jar; \
    fetch com/microsoft/sqlserver/mssql-jdbc/${MSSQL_JDBC_VERSION}/mssql-jdbc-${MSSQL_JDBC_VERSION}.jar

COPY spark-defaults.conf /opt/spark/conf/spark-defaults.conf
COPY requirements-spark.txt /opt/spark/requirements-spark.txt

RUN pip3 install --no-cache-dir --upgrade pip \
 && pip3 install --no-cache-dir -r /opt/spark/requirements-spark.txt

# Writable location for the embedded Derby metastore (mounted as a named volume)
RUN mkdir -p /opt/spark/metastore && chown spark:spark /opt/spark/metastore


USER spark
