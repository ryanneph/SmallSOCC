#  from collections import MutableMapping
import copy

class NamedMember():
    """ Defines a key-value pair with associated getter/setter functions for dynamically making
    members available to qml and file read/write operations """

    def __init__(self, name: str, value: object=None, getter=None, setter=None, value_initializer=None):
        """ support for value_initializer callables to support default init of certain varables
        such as datetime.now() which would otherwise always have the now() from parsing time """
        self.name = name
        # prefer to value init from callable when available
        if value_initializer:
            self._value = value_initializer()
        else:
            self._value = value
        self._getter = getter
        self._setter = setter
        self._value_initializer = value_initializer

    def __copy__(self):
        return NamedMember(name=copy.copy(self.name), value=copy.copy(self._value),
                           getter=self._getter, setter=self._setter,
                           value_initializer=self._value_initializer)

    def __deepcopy__(self, memodict):
        return NamedMember(
            name   = copy.deepcopy(self.name, memodict),
            value  = copy.deepcopy(self._value, memodict),
            getter = copy.deepcopy(self._getter, memodict),
            setter = copy.deepcopy(self._setter, memodict),
            value_initializer = copy.deepcopy(self._value_initializer, memodict)
        )

    @property
    def value(self):
        """ use _getter as middleware for returning _value """
        if self.hasGetter():
            return self._getter(self._value)
        return self._value

    @value.setter
    def value(self, val: object):
        """ use _setter as middleware for setting _value """
        if self.hasSetter():
            self._value = self._setter(val)
        else:
            self._value = val

    @property
    def basicvalue(self):
        """ use 'as_basic' version of _getter
        well-behaved _getter methods should implement handling of the 'as_basic=bool' kwarg """
        if self.hasGetter():
            return self._getter(self._value, as_basic=True)
        return self._value

    @basicvalue.setter
    def basicvalue(self, val: object):
        self.value = val

    def hasGetter(self) -> bool:
        return self._getter is not None

    def hasSetter(self) -> bool:
        return self._setter is not None
