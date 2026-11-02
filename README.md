# data-platform

Modern Data Platform template featuring containerized Apache Spark, Apache Kafka, and Spark Connect with native Delta Lake support.

## 🚀 Architecture Stack

- **Orchestration & Compute:** Apache Spark (Master + Worker)
- **Remote Execution:** Spark Connect Server (Port `15002`)
- **Storage Layer:** Delta Lake on local disk or S3 (SeaweedFS, `hadoop-aws` configured)
- **Streaming:** Apache Kafka (KRaft mode) + Kafka UI
- **Database Connectivity:** MSSQL JDBC Driver included

## 📁 Repository Structure

```text
data-platform/
├── data/                  # Delta files and tables (gitignored), mounted at /opt/spark/data
│   └── warehouse/         # Default location for tables saved by name (spark.sql.warehouse.dir)
├── scripts/               # Helper scripts (smoke_test.sh)
├── compose.yml            # Kafka, Kafka UI, SeaweedFS (S3), Spark Master, Spark Connect, Spark Worker
├── Dockerfile             # Custom Spark image (Delta, S3, Kafka, MSSQL JDBC jars)
├── spark-defaults.conf    # Spark defaults: Delta extensions, warehouse dir, S3 settings
└── requirements-spark.txt # Python dependencies installed in the Spark image
```

Use `/opt/spark/data/...` as the path inside the containers, for example `df.write.format("delta").save("/opt/spark/data/delta_test")`.

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
Credentials and the bucket name can be overridden with the `S3_ACCESS_KEY`, `S3_SECRET_KEY` and `S3_BUCKET` environment variables (defaults are for local development only). The S3 settings live in `spark-defaults.conf`.

### Smoke Test
Verifies Kafka, Spark Master/worker, Kafka UI, and a Spark Connect query with a Delta write/read:
```bash
./scripts/smoke_test.sh
```
