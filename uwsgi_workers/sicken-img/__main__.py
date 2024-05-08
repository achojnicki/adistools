from adistools.adisconfig import adisconfig
from adistools.log import Log

from flask import Flask, Response, request, render_template
from pymongo import MongoClient
from base64 import b64decode
from datetime import datetime
from html import escape


class IMG:
    project_name='sicken-img'
    def __init__(self):
        self._config=adisconfig('/opt/adistools/configs/sicken-img.yaml')
        self._log=Log(
            parent=self,
            backends=['rabbitmq_emitter'],
            debug=self._config.log.debug,
            rabbitmq_host=self._config.rabbitmq.host,
            rabbitmq_port=self._config.rabbitmq.port,
            rabbitmq_user=self._config.rabbitmq.user,
            rabbitmq_passwd=self._config.rabbitmq.password,
        )  

        self._mongo_cli=MongoClient(
            self._config.mongo.host,
            self._config.mongo.port,
        )

        self._mongo_db=self._mongo_cli[self._config.mongo.db]
        self._images=self._mongo_db['images']

    def add_metric(self,redirection_uuid, redirection_query, remote_addr, user_agent, time):
        document={
            "redirection_uuid"  : redirection_uuid,
            "redirection_query" : redirection_query,
            "time"              : {

                "timestamp"         : time.timestamp(),
                "strtime"          : time.strftime("%m/%d/%Y, %H:%M:%S")
                },
            "client_details"    : {
                "remote_addr"       : remote_addr,
                "user_agent"        : user_agent,
                }
            }

        self._metrics.insert_one(document)



    def _get_query(self, image_uuid):
        return {'image_uuid' : image_uuid}

    @property
    def _remote_addr(self):
        if request.headers.getlist("X-Forwarded-For"):
            return request.headers.getlist("X-Forwarded-For")[0]
        else:
            return str(request.remote_addr)


    def redirect(self, image_uuid):

        image=self._images.find_one(self._get_query(image_uuid))
        if image:
            time=datetime.now()
            user_agent=str(request.user_agent)
            
            #self.add_metric(
            #    redirection_query=redirection_query,
            #    redirection_uuid=redirection_uuid,
            #    remote_addr=self.remote_addr,
            #    user_agent=user_agent,
            #    time=time
            #    )

            return Response(
                b64decode(image['image']),
                mimetype='image/jpg',
                )

        else:
            return Response(
                "Not found",
                mimetype="text/html")


application=Flask(
    __name__,
    template_folder="template",
    static_folder='static'
    )
img=IMG()
application.add_url_rule("/<image_uuid>", view_func=img.redirect)


