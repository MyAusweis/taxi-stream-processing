# from google.cloud import pubsub_v1

# project_id = "thelab-240901"
# topic_name = "subscriptions/test"

# publisher = pubsub_v1.PublisherClient()
# topic_path = publisher.topic_path(project_id, topic_name)

# topic = publisher.create_topic(topic_path)

# print('Topic created: {}'.format(topic))

import os
from google.cloud import pubsub_v1
from google.api_core.exceptions import AlreadyExists
from serviceclient import TaxiCounts

topic_name = 'projects/{project_id}/topics/{topic}'.format(
        project_id = "pubsub-public-data",
        topic='taxirides-realtime',  # Set this to something appropriate.
    )
project_id = "thelab-240901"

subscription_name = 'projects/{project_id}/subscriptions/{sub}'.format(
    project_id=project_id,
    sub='taxirides_test',  # Set this to something appropriate.
)

def setup(topic_name, subscribeription_name):
    subscriber = pubsub_v1.SubscriberClient()
    print("subscriber: ", subscriber)
    print("topic_name: ", topic_name)
    print("subscription_name: ", subscription_name)
    try:
        subscriber.create_subscription(
        name=subscription_name, topic=topic_name)
    except AlreadyExists as e:
        print("The subscription topic already exists. Moving ahead to subscribing.",)
    except Exception as e:
        print(e)
    return subscriber

# def callback(message):
#     print("Message: ")
#     print(message.data)
#     # print(".", end = '')
#     message.ack()

def save_and_ack(t,subscriber, received_messages):
    if t.add_counts(len(received_messages)):
        ack_ids = [msg.ack_id for msg in received_messages]
        subscriber.acknowledge(subscription_name, ack_ids)
   
if __name__ == '__main__':
    import sys
    #if len(sys.argv) != 2:
    #    print("%s <http://service_host:port>" % (sys.argv[0]))
    #    exit(1)
    subscriber = setup(topic_name, subscription_name)

    t = TaxiCounts("http://taxiservice-main:80")
    # future = subscriber.subscribe(subscription_name, callback)
    # future.result()
    while True:
        # subscription_path = subscriber.subscription_path(project_id, subscription_name)
        response = subscriber.pull(subscription_name, max_messages=10)
        save_and_ack(t, subscriber, response.received_messages)
