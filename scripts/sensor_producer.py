import json
import time
import random
import boto3
from datetime import datetime, timezone


# ============================================================
# CONFIGURACIÓN
# ============================================================

STREAM_NAME = "pre-entrega1-dev-stream"
REGION = "us-east-1"

kinesis = boto3.client(
  "kinesis",
  region_name=REGION
)


# ============================================================
# SENSORES
# ============================================================

sensores = [
  f"sensor_zona_{i}"
  for i in range(1, 6)
]

def build_event(sensor_id: str) -> dict:
  return {
    "sensor_id": sensor_id,

    "temperature": round(
      random.uniform(15.0, 38.0),
      2
    ),

    "humidity": round(
      random.uniform(30.0, 90.0),
      2
    ),

    "air_quality_index": random.randint(
      0,
      200
    ),

    "timestamp": datetime.now(
      timezone.utc
    ).strftime("%Y-%m-%d %H:%M:%S")
  }

def send_to_kinesis(event: dict) -> None:
  data = json.dumps(event).encode("utf-8")

  response = kinesis.put_record(
    StreamName=STREAM_NAME,
    PartitionKey=event["sensor_id"],
    Data=data
  )

  print(
    f"📡 Evento enviado a Kinesis: {event} | "
    f"Shard: {response['ShardId']}"
  )


if __name__ == "__main__":
  try:
    while True:
      sensor_id = random.choice(sensores)
      event = build_event(sensor_id)

      send_to_kinesis(event)

      time.sleep(0.5)

  except KeyboardInterrupt:
    print("\nDeteniendo productor...")