import json
import random
import time

import boto3

STREAM_NAME = "pre-entrega1-dev-stream"
REGION = "us-east-1"
PRODUCTOS = ["A1", "B2", "C3", "D4", "E5"]

client = boto3.client("kinesis", region_name=REGION)


def build_event(user_id: int) -> dict:
    return {
        "evento": "click",
        "producto": random.choice(PRODUCTOS),
        "user_id": f"user-{user_id}",
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }


def main():
    print(f"Enviando 100 registros a {STREAM_NAME}...")

    for i in range(100):
        partition_key = f"user-{i % 10}"
        data = json.dumps(build_event(i)).encode("utf-8")

        response = client.put_record(
            StreamName=STREAM_NAME,
            PartitionKey=partition_key,
            Data=data,
        )

        print(
            f"#{i+1:03d} -> shard {response['ShardId']} "
            f"seq {response['SequenceNumber']}"
        )

    print("\nListo: 100 registros enviados.")


if __name__ == "__main__":
    main()