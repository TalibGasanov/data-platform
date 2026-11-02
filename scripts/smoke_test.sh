#!/usr/bin/env bash
# Smoke test for a running platform: Kafka, Spark Master, Kafka UI and Spark Connect.
# Usage: ./scripts/smoke_test.sh
set -u

cd "$(dirname "$0")/.."

fail=0
check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    fail=1
  fi
}

check "kafka broker responds" \
  docker compose exec -T kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092
check "spark master UI (8080)" curl -fsS http://localhost:8080
check "kafka UI (8085)" curl -fsS http://localhost:8085
check "spark worker registered with master" \
  bash -c "curl -fsS http://localhost:8080/json/ | grep -q '\"state\" *: *\"ALIVE\"'"

# Run a real query through Spark Connect from inside the spark-connect container,
# which already ships pyspark, so no local client install is needed.
check "spark connect query + delta write/read" \
  docker compose exec -T spark-connect python3 -c '
import shutil, tempfile
from pyspark.sql import SparkSession
spark = SparkSession.builder.remote("sc://localhost:15002").getOrCreate()
assert spark.range(5).count() == 5
path = tempfile.mkdtemp(prefix="smoke_delta_", dir="/opt/spark/data")
try:
    spark.range(3).write.format("delta").save(path + "/t")
    assert spark.read.format("delta").load(path + "/t").count() == 3
    spark.range(2).write.format("delta").mode("overwrite").saveAsTable("smoke_tbl")
    assert spark.table("smoke_tbl").count() == 2
finally:
    spark.sql("DROP TABLE IF EXISTS smoke_tbl")
    shutil.rmtree(path, ignore_errors=True)
'

if [ "$fail" -eq 0 ]; then
  echo "All checks passed"
else
  echo "Some checks failed"
fi
exit "$fail"
