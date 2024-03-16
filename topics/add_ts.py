#!/usr/bin/python3
import json
from kafka import KafkaConsumer
from kafka import KafkaProducer
import time
from dotenv import load_dotenv
from pathlib import Path
import os
import sys

root_path = Path(__file__).parent.parent
sys.path.append(str(root_path / 'logger'))

from log import Log


load_dotenv(dotenv_path=str(root_path / '.env'))

logger = Log()

KAFKA_HOST_PORT = os.getenv('KAFKA_HOST_PORT', 9092)

logger.info(f"add_ts topic - connecting to consumer ... - info: port {KAFKA_HOST_PORT}")

consumer = KafkaConsumer(
    'add_ts',
    bootstrap_servers=[f'localhost:{KAFKA_HOST_PORT}'],
    # auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id='my-group2',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

logger.info('add_ts topic - connected to consumer !')

producer = KafkaProducer(
    bootstrap_servers=[f'localhost:{KAFKA_HOST_PORT}'],
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)

for message in consumer:
    print('HERE')
    logger.info(f"Partition:{message.partition}\tOffset:{message.offset}\tKey:{message.key}\tValue:{message.value}")

    data = message.value
    data['ts'] = time.strftime('%Y-%m-%d %H:%M:%S')
    producer.send('add_info', value=data)
    producer.flush()
    
    logger.info(f'Kafka add_ts topic: id: {data["id"]} - username: {data["username"]} - sent to next topic')
