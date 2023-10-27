from .constants import LOG_LEVELS
from .methods import adislog_methods 
from .inspect import inspect
from .process import get_process_details
from .traceback import parse_frame
from .exceptions import EXCEPTION_BACKEND_DO_NOT_EXISTS

from pprint import pformat
from time import strftime

import sys
import traceback

class adistoolslog(adislog_methods):
    def __init__(self,
                 debug:bool=False,
                 backends:list or array=['rabbitmq_emitter'],
                 rabbitmq_host=None,
                 rabbitmq_port=None,
                 rabbitmq_user=None,
                 rabbitmq_passwd=None,
                 rabbitmq_queue='logs',
                 root=None
                 ):
        self._backends=[]
        self._time_format="%d/%m/%Y %H:%M:%S"
        self._debug=debug
        self._exception_data=[]
        self._root=root
        self._inspect=inspect()
        
        
        
        for a in backends:
            o=None        
            
            if a == 'rabbitmq_emitter':
                from .backends import rabbitmq_emiter
                o=rabbitmq_emiter.rabbitmq_emiter(
                    rabbitmq_host=rabbitmq_host,
                    rabbitmq_port=rabbitmq_port,
                    rabbitmq_user=rabbitmq_user,
                    rabbitmq_passwd=rabbitmq_passwd,
                    rabbitmq_queue=rabbitmq_queue
                    )
            
            
            else:
                raise EXCEPTION_BACKEND_DO_NOT_EXISTS
            
            if o:
                self._backends.append(o)
            
    @property        
    def _log_data(self):
        if hasattr(self._root, 'session'):
            return self._root.session.log_data
        return {}

    def _message(self,log_level:int, log_item):
        if log_level >0 or self._debug: 
            if type(log_item) is str:
                message=log_item
            
            elif type(log_item) is tuple or type(log_item) is list:
                message=pformat(log_item)
                
            elif type(log_item) is dict:
                message=pformat(log_item)
            
            elif type(log_item) is int:
                message=log_item
                
            elif type(log_item) is bytes or type(log_item) is bytearray:
                message=log_item.decode('utf-8')

            else:
                message=str(log_item) 
            
            time=strftime(self._time_format)
            caller_info=self._inspect.get_caller()
            process_details=get_process_details()
                            
            msg={
            "project_name": self._root.project_name,
            "log_level":LOG_LEVELS[log_level],
            "message":message, 
            "datetime":time, 
            **caller_info, 
            **process_details,
            **self._log_data
            }

            if self._exception_data:
                msg['excpt_data']=[parse_frame(a) for a in self._exception_data] 
                
            self._emit_to_backends(msg)


    def _emit_to_backends(self, msg):
        for backend in self._backends:
            backend.emit(**msg)

    def _parse_tb(self, tb):
        self._exception_data.append(tb.tb_frame)

    def _except(self, etype,value, tb):
        #TODO: use the value: traceback.format_exception(value)

        while True:
            self._parse_tb(tb)
            if tb.tb_next:
                tb=tb.tb_next
            else:
                break
            
        self.fatal("Exception %s occured!" % value)
        sys.exit(1)
        
