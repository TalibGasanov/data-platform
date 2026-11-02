# data-platform

Modern Data Platform template featuring containerized Apache Spark, Apache Kafka, and Spark Connect with native Delta Lake support.

## 🚀 Architecture Stack

- **Orchestration & Compute:** Apache Spark (Master + Worker)
- **Remote Execution:** Spark Connect Server (Port `15002`)
- **Storage Layer:** Delta Lake & Storage (S3/HADOOP-AWS ready)
- **Streaming:** Apache Kafka (KRaft mode) + Kafka UI
- **Database Connectivity:** MSSQL JDBC Driver included

## 📁 Repository Structure

```text
data-platform/
├── data/                  # Delta files and tables (gitignored), mounted at /opt/spark/data
│   └── warehouse/         # Default location for tables saved by name (spark.sql.warehouse.dir)
├── scripts/               # Helper scripts (smoke_test.sh)
├── compose.yml            # Kafka, Kafka UI, Spark Master, Spark Connect, Spark Worker
├── Dockerfile             # Custom Spark image (Delta, S3, Kafka, MSSQL JDBC jars)
├── spark-defaults.conf    # Spark defaults: Delta extensions, warehouse dir
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

### Smoke Test
Verifies Kafka, Spark Master/worker, Kafka UI, and a Spark Connect query with a Delta write/read:
```bash
./scripts/smoke_test.sh
```
