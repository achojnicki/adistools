from .system import System
from .inspect import Inspect
from .parent import Parent

class Probes(System, Inspect, Parent):
	def __init__(self, parent):
		self._parent=parent


