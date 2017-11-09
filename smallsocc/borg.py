"""
Like a singleton with a focus on shared STATE rather than shared IDENTITY.

Borg can be inherited and ensures that all instances of the inheriting derived class share their state
    such that any instance will access the same properties and methods. The ID of each instance is unique and
    thus, each will provide a different key

By default all sub-classes of Borg will share state with all others (regardless of sub-class type). To restrict
    state sharing only to like sub-class instances, add the static (class) variable _shared_state = {} to
    the derived class definition
"""

class Borg():
    _shared_state = {}
    def __init__(self):
        self.__dict__ = self._shared_state
