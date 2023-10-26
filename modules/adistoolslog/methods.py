from .constants import LEVEL_DEBUG, LEVEL_INFO, LEVEL_WARNING, LEVEL_FATAL, LEVEL_ERROR, LEVEL_SUCCESS

class adislog_methods:
    def debug(self,*args):
        self._message(LEVEL_DEBUG,*args)
    
    def info(self,*args):
        self._message(LEVEL_INFO,*args)
        
    def warning(self,*args):
        self._message(LEVEL_WARNING,*args)
    
    def error(self,*args):
        self._message(LEVEL_ERROR,*args)
    
    def fatal(self,*args):
        self._message(LEVEL_FATAL,*args)
    
    def success(self,*args):
        self._message(LEVEL_SUCCESS,*args)
         
