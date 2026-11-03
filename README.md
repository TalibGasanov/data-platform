# data-platform

Modern Data Platform template featuring containerized Apache Spark, Apache Kafka, and Spark Connect with native Delta Lake support.

## 🚀 Architecture Stack

- **Orchestration & Compute:** Apache Spark (Master + Worker)
- **Remote Execution:** Spark Connect Server (Port `15002`)
- **Storage Layer:** Delta Lake on local disk or S3 (SeaweedFS, `hadoop-aws` configured)
- **Catalog:** Embedded Derby Hive metastore (table names persist across restarts)
- **Streaming:** Apache Kafka (KRaft mode) + Kafka UI
- **Database Connectivity:** MSSQL JDBC Driver included

## 📁 Repository Structure

```text
data-platform/
├── data/                  # Delta files on local disk (gitignored), mounted at /opt/spark/data
├── scripts/               # Helper scripts (smoke_test.sh)
├── compose.yml            # Kafka, Kafka UI, SeaweedFS (S3), Spark Master, Spark Connect, Spark Worker
├── Dockerfile             # Custom Spark image (Delta, S3, Kafka, MSSQL JDBC jars)
├── spark-defaults.conf    # Spark defaults: Delta extensions, Hive metastore, warehouse dir, S3 settings
└── requirements-spark.txt # Python dependencies installed in the Spark image
```

## 🛠️ Quick Start

### Prerequisites
- Docker & Docker Desktop
- Python 3.10.12 (for local development/testing)

### Spin up the Platform
```bash
### 1 worker
docker compose up -d --build
### 2 workers
docker compose -f compose.yml up -d --scale spark-worker=2
```

### Access Web UIs
- **Spark Master UI:** [http://localhost:8080](http://localhost:8080)
- **Kafka UI:** [http://localhost:8085](http://localhost:8085)
- **Spark Connect Endpoint:** `sc://localhost:15002`
- **SeaweedFS Master UI:** [http://localhost:9333](http://localhost:9333)
- **SeaweedFS Filer UI (browse buckets):** [http://localhost:8888/buckets/](http://localhost:8888/buckets/)
- **S3 API:** `http://localhost:8333` (from the containers: `http://seaweedfs:8333`)

### S3 Storage (SeaweedFS)
SeaweedFS provides a local S3-compatible store, and a `lakehouse` bucket is created on startup. Spark reaches it through `s3a://`:
```python
df.write.format("delta").mode("overwrite").save("s3a://lakehouse/delta_test")
spark.read.format("delta").load("s3a://lakehouse/delta_test").show()
```
To query a CSV file stored in the bucket (browse it at [http://localhost:8888/buckets/lakehouse/](http://localhost:8888/buckets/lakehouse/)), use its exact `s3a://` path:
```python
df = spark.read.option("header", "true").csv("s3a://lakehouse/external-locations/files/northwind/Customers.csv")
df.show()
```
Credentials and the bucket name can be overridden with the `S3_ACCESS_KEY`, `S3_SECRET_KEY` and `S3_BUCKET` environment variables (defaults are for local development only). The S3 settings live in `spark-defaults.conf`.

### Bucket Folder Structure
The `lakehouse` bucket uses these top-level folders:
- `schemas/` — managed storage. Spark creates the files here itself when you create databases and tables (e.g. `schemas/northwind_db.db/`). Don't upload files here manually.
- `external-locations/` — for files you upload manually, such as CSV or JSON (e.g. `external-locations/files/northwind/Customers.csv`).

### Local Disk Storage (optional fallback)
The host `./data` folder is also mounted at `/opt/spark/data` in `spark-connect` and `spark-worker`, so you can store Delta files on local disk without S3. Use the `/opt/spark/data/...` path inside the containers; the files appear in `./data` on the host:
```python
df.write.format("delta").mode("overwrite").save("/opt/spark/data/delta_test")
spark.read.format("delta").load("/opt/spark/data/delta_test").show()
```
Tables saved by name (`saveAsTable`) go to S3 (`s3a://lakehouse/schemas`), not to this folder. The host folder can be changed with the `SPARK_DATA_DIR` environment variable.

### Tables and Metastore
Tables saved by name are stored under `s3a://lakehouse/schemas` and registered in an embedded Derby Hive metastore, so their names persist across restarts:
```python
df.write.format("delta").mode("overwrite").saveAsTable("test")
spark.sql("SHOW TABLES").show()
spark.sql("DESCRIBE EXTENDED test").show(truncate=False)
```
The metastore database lives in the `metastore-data` Docker volume. Derby allows only one connection, so run a single Spark driver (`spark-connect`) against it. Removing only the `metastore-data` volume drops the table names, but the table files stay in the bucket. Re-register one with `CREATE TABLE test USING delta LOCATION 's3a://lakehouse/schemas/test'`. Note that `docker compose down -v` removes all volumes, including the bucket data.

### Smoke Test
Verifies Kafka, Spark Master/worker, Kafka UI, and a Spark Connect query with a Delta write/read:
```bash
./scripts/smoke_test.sh
```
