#!/usr/bin/python3
import json
from kafka import KafkaConsumer
from kafka import KafkaProducer
from faker import Faker
from dotenv import load_dotenv
from pathlib import Path
import os
import sys

root_path = Path(__file__).parent.parent
sys.path.append(str(root_path / 'logger'))

from log import Log


load_dotenv(dotenv_path=str(root_path / '.env'))

logger = Log()
fake = Faker()

KAFKA_HOST_PORT = os.getenv('KAFKA_HOST_PORT', 9092)

logger.info(f"add_info topic - connecting to consumer ... - info: port {KAFKA_HOST_PORT}")

consumer = KafkaConsumer(
    'add_info',
    bootstrap_servers=[f'localhost:{KAFKA_HOST_PORT}'],
    # auto_offset_reset='earliest',
    enable_auto_commit=True,
    group_id='my-group2',
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

logger.info('add_info topic - connected to consumer !')

producer = KafkaProducer(
    bootstrap_servers=[f'localhost:{KAFKA_HOST_PORT}'],
    value_serializer=lambda x: json.dumps(x).encode('utf-8')
)


def add_info(data: dict):
    data['credit_card'] = fake.credit_card_number(card_type='visa')
    return data


for message in consumer:
    logger.info(f"Partition:{message.partition}\tOffset:{message.offset}\tKey:{message.key}\tValue:{message.value}")

    data = add_info(message.value)

    producer.send('add_to_db', value=data)
    producer.flush()


    logger.info(f'Kafka add_info topic: id: {data["id"]} - username: {data["username"]} - sent to next topic')
