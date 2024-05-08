from threading import Thread
from json import loads
from time import sleep

from redis import StrictRedis


class Channel:
	def __init__(self, root, channel_name):
		self._root=root

		self._log=root._log
		self._config=root._config

		self._channel_name=channel_name

		self._redis_cli=StrictRedis(
			host=self._config.redis.host,
			port=self._config.redis.port,
			db=self._config.redis.db
		)		

	def get(self):
		self._pubsub=self._redis_cli.pubsub()
		self._pubsub.subscribe(self._channel_name)
		for message in self._pubsub.listen():
			if message['type']=='message':
				message=message['data'].decode('utf-8')
				return message


	def put(self, data):
		self._redis_cli.publish(self._channel_name, data)