from inspect import stack, currentframe

class inspect:
    def __init__(self):
        pass

    def get_caller(self):
        i=stack()[3]
        resp={"filename":i.filename,
              "function": i.function,
              "line_number":i.lineno}
        return resp

    @property
    def caller(self):
        return currentframe().f_back.f_back.f_back.f_locals["self"]