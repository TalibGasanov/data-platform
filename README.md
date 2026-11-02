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
├── data/                  # Shared data directory
├── fixtures/              # Test fixtures and mock data
├── logs/                  # Services log output
├── shared/                # Shared utilities and libraries
├── transforms/            # PySpark transformation jobs
├── compose.yml
├── Dockerfile
├── spark-defaults.conf
└── requirements-spark.txt
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
