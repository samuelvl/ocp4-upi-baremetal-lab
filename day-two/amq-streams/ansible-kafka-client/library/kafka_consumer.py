#!/usr/bin/python

# Copyright: (c) 2021, Samu Veloso <samuvl@redhat.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type
from json import loads
from kafka import KafkaConsumer, TopicPartition

DOCUMENTATION = r'''
---
module: kafka_consumer

short_description: A Kafka client that consumes records from the Kafka cluster

version_added: "1.0.0"

description: A Kafka client that consumes records from the Kafka cluster.

options:
    bootstrap:
        description: Kafka endpoint that the consumer should contact to
        bootstrap initial cluster metadata.
        required: true
        type: str
    topic:
        description: Kafka topic.
        required: true
        type: str
    tls:
        description: Enable if Kafka is using TLS. 
        required: false
        type: dict

author:
    - Samu Veloso (@samuelvl)
'''

EXAMPLES = r'''
- name: Read records from example topic in my localhost Kafka cluster
  samuelvl.community.kafka_consumer:
    bootstrap: "localhost:9092"
    topic: example
    tls:
        ca_certificate: files/certificate.pem
'''

RETURN = r'''
# These are examples of possible return values, and in general should use other names for return values.
changed:
    description: True if data has been read from Kafka.
    type: bool
    returned: always
    sample: False
data:
    description: Data read from Kafka.
    type: dict
    returned: always
    sample: "{'user':'bob'}"
'''

from ansible.module_utils.basic import AnsibleModule


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        bootstrap=dict(type='str', required=True),
        topic=dict(type='str', required=True),
        tls=dict(type='dict', required=False),
    )

    # seed the result dict in the object
    result = dict(
        changed=False,
        data={},
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    # manipulate or modify the state as needed (this is going to be the
    # part where your module will do what it needs to do)

    kafka_bootstrap = module.params['bootstrap']
    kafka_topic = module.params['topic']

    if "tls" in module.params:
        consumer = KafkaConsumer(
            bootstrap_servers=[kafka_bootstrap],
            security_protocol='SSL',
            ssl_cafile=module.params['tls']['ca_certificate'],
            value_deserializer=lambda x: loads(x.decode('utf-8'))
        )
    else:
        consumer = KafkaConsumer(
            kafka_topic,
            bootstrap_servers=[kafka_bootstrap],
            security_protocol='PLAINTEXT',
            value_deserializer=lambda x: loads(x.decode('utf-8'))
        )

    # Assign partition to consumer 
    partition = TopicPartition(kafka_topic, 0)
    consumer.assign([partition])

    # Read last message
    last_offset = consumer.position(partition)
    consumer.seek(partition, last_offset-1)
    for message in consumer:
        result['data'] = message.value
        break

    result['changed'] = True

    # in the event of a successful module execution, you will want to
    # simple AnsibleModule.exit_json(), passing the key/value results
    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
