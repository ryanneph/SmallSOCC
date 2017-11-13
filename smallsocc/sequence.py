# -*- coding: utf-8 -*-
"""
sequence.py

implements data structure containing a single "control point" item in a radiotherapy treatment sequence
with implementation for read-from-file and write-to-file methods

"""
import math
from enum import Enum, unique
import copy
import json
import json_serializer
from datetime import datetime
from PyQt5 import QtCore, QtQml
from PyQt5.QtCore import Qt, pyqtSignal, pyqtSlot, pyqtProperty
from PyQt5.QtQml import qmlRegisterType
from sequence_members import _sequenceitem_public_members, SequenceItemType, datetimefmt


""" Defines user roles for accessing data items in SequenceItem Object """
SequenceUserRoles = Enum("SequenceUserRoles",
        list(_sequenceitem_public_members.keys()), start=Qt.UserRole+1)

def _getEnumMemberFromInt(enum: Enum, idx: int):
    """ helper for accessing enum member from its mapped integer value """
    return list(enum.__members__.values())[idx]


#  # TODO: NOT YET IMPLEMENTED
#  # Define factories that produce getter/setter methods to register as QML properties
#  def getFactory(key):
#      def getter(self):
#          return QtCore.QVariant(self._members[key].basicvalue)
#      return getter

#  def setFactory(key):
#      def setter(self, val: object):
#          self._members[key].value = val
#      return setter

#  # class decorator that registers Named Members as class properties accessible to QML
#  class register_qml_properties:
#      def __init__(self, property_map):
#          print('starting to decorate')
#          self.property_map = property_map

#      def __call__(self, cls):
#          print('done decorating')
#          def constructor(**kwargs):
#              print("constructing class")
#              cls(**kwargs)
#              print("registering properties")
#              #  self.register(cls)
#              return cls
#          return constructor

#      def register(self, cls):
#          """ register NamedMembers as accessible properties to qml engine """
#          for k, v in self.property_map.items():
#              print('registering property with qml: {!s} {}'.format(type(v.basicvalue), k))
#              setattr(cls, str(k), pyqtProperty(type(v.basicvalue), fget=getFactory(k), fset=setFactory(k)))

#  @register_qml_properties(_sequenceitem_public_members)
class SequenceItem(QtCore.QObject):
    """ Backend representation for distinct setting of leaflet positions, beam angles,
    and occurence time in a treatment plan """

    # signal activation cascades to SequenceListModel
    onMemberDataChanged = pyqtSignal()

    def __init__(self, parent=None, **kwargs):
        """
        Keyword Args:
            All valid kwargs are detailed in _sequenceitem_public_members
        """
        QtCore.QObject.__init__(self, parent)
        # private members
        self._members = copy.deepcopy(_sequenceitem_public_members)

        if len(kwargs):
            # handle angle setting in degrees
            for k in ['rot_gantry_rad', 'rot_couch_rad']:
                if k in kwargs:
                    kr = k.replace('rad', 'deg')
                    self._members[kr].value = kwargs[k] * 180 / math.pi
                    del kwargs[k]

            # set from kwargs
            for k in self._members.keys():
                #  print('setting self._members[{!s}] to {!s}'.format(k, kwargs[k]))
                try: self._members[k].value = kwargs[k]
                except: continue

    def __repr__(self):
        s = ''
        for i, (k, v) in enumerate(self._members.items()):
            if i != 0: s += '\n'
            s += '{!s}: {!s}'.format(k, v.value)
        return s

    def packDict(self):
        """ construct a dictionary of (member name, basicvalue) pairs """
        d = {}
        for k, v in self._members.items():
            #  print(f'{k} is a {type(v.value)} with val: {v.value} and basicval: {v.basicvalue}')
            d[k] = v.basicvalue
        return d

    @classmethod
    def unpackDict(cls, d):
        """ construct object from (potentially incomplete) dictionary of member values, using
        default values where members are omitted

        *** d should be a dictionary of name (str): value pairs where "value" is not a Named Member but the
            valid value associated with the NamedMember member "name"
        """
        self = cls(**d)
        return self

    # permit javascript/qml to access NamedMember from map of members
    @pyqtSlot(QtCore.QVariant, result=QtCore.QVariant)
    @pyqtSlot(result=QtCore.QVariant)
    def get(self, key: object=None):
        """ provides method for getting a single member value or a dict/map of (member name, value) pairs
        if key is a single member name, return that member's value
        if key==None, return a dict/map of all (member name, value) pairs associated with this SequenceItem
        """
        if not key:
            # return map of all member data
            return QtCore.QVariant({k: v.basicvalue for k,v in self._members.items()})
        if key not in self._members:
            return None
        return QtCore.QVariant(self._members[key].basicvalue)

    @pyqtSlot(QtCore.QVariant, QtCore.QVariant, result=bool)
    @pyqtSlot(QtCore.QVariant, result=bool)
    def set(self, key: object=None, val: object=None):
        """ provides method for setting a single member or a set of members defined in a dict/map
        if key and val are both valid, set a single member variable according to its .value() property
        if val==None, treat key as a dict/map of (member name, setting value) pairs

        Returns (bool): indicates whether setting was successful
        """
        if isinstance(key, QtQml.QJSValue):
            key = key.toVariant()
        if isinstance(val, QtQml.QJSValue):
            val = val.toVariant()

        if val:
            print(f'setting new value for \"{key}\": {val}')
            self._members[key].value = val
        elif key:
            for k, v in key.items():
                #  print(type(k), type(v))
                print(f'setting new value for \"{k}\": {v}')
                self._members[k].value = v
        else: return False
        self.onMemberDataChanged.emit()
        return True


class SequenceListModel(QtCore.QAbstractListModel):
    """ Model for manipulating an ordered list of SequenceItems from QML ListView

    NOTE: anytime a new SequenceItem() instance is added to this collection, you MUST set the parent of the
          SequenceItem QObject to "self" of this class. Otherwise, when handing these instances to qml through
          self.getItem(), python will garbage collect the SequenceItem instance and qml will throw an error
    """

    onModelReset = pyqtSignal()
    onMemberDataChanged = pyqtSignal()

    ## CONSTRUCTORS
    def __init__(self, *args, **kwargs):
        """ initialize from dictionary if kwarg 'elements=[]' is provided """
        QtCore.QAbstractListModel.__init__(self, None)
        try:
            self._items = kwargs['elements']
        except:
            self._items = []

        for item in self._items:
            self.connectSignals(item)

    @classmethod
    def fromJson(cls, fname):
        self = cls()
        self.readFromJson(fname)
        return self

    @pyqtSlot(str, result=bool)
    def readFromJson(self, fname):
        """ Constructor from json file of SequenceItems """
        with open(fname, 'r') as f:
            d = json.load(f)

        try:
            seqitems = []
            for itemdict in d['SequenceList']:
                seqitems.append(SequenceItem(**itemdict, parent=self))
        except Exception as e:
            print(f"Error in {cls.__name__}.readFromJson(): failed to read SequenceList from file \"{fname}\"")
            return False

        self.beginResetModel()
        self._items = seqitems
        for item in self._items:
            self.connectSignals(item)
        self.endResetModel();
        self.onModelReset.emit()
        return True

    @pyqtSlot(str, result=bool)
    def writeToJson(self, fname: str):
        """ write all member vars to json for later recall """
        try:
            memlist = []
            for mem in self._items:
                memlist.append(mem.packDict())

            # wrap with header
            d = {'metadata': {'generated_on': datetime.now().strftime(datetimefmt)},
                 'SequenceList': memlist }

            #  js = json_serializer.to_json(d)
            js = json.dumps(d, indent=2, separators=(',', ':'), sort_keys=True)

            with open(fname, 'w') as f:
                f.write(js)
        except: return False

        return True

    def connectSignals(self, obj):
        """connect child's signal to parent accessible signal"""
        obj.onMemberDataChanged.connect(self.onMemberDataChanged)

    def disconnectSignals(self, obj):
        """Disconnect all child signal handlers"""
        obj.onMemberDataChanged.disconnect(self.onMemberDataChanged)

    ## METHODS
    # Virtual Base Method
    @pyqtSlot(QtCore.QModelIndex, result=int)
    def rowCount(self, parent=QtCore.QModelIndex()):
        return len(self._items)

    @pyqtSlot(int, result=SequenceItem)
    def getItem(self, index: int):
        """ Returns QObject """
        if index >= self.rowCount():
            return None
        return self._items[index]

    # Virtual Base Method
    @pyqtSlot(QtCore.QModelIndex, int, result=QtCore.QVariant)
    def data(self, index: QtCore.QModelIndex, role: int=Qt.DisplayRole):
        """ Get data item indexed by index.row() and member indicated by role """
        #  print("trying to get {}".format(_getEnumMemberFromInt(SequenceUserRoles, role-Qt.UserRole-1)))
        if not index.isValid(): return None
        if index.row() > self.rowCount(): return None
        if role == Qt.DisplayRole or role == Qt.EditRole:
            return self._items[index.row()]
        if Qt.UserRole < role < Qt.UserRole+len(SequenceUserRoles.__members__)+1:
            sequenceitem = self._items[index.row()]
            val = sequenceitem._members[_getEnumMemberFromInt(SequenceUserRoles, role-Qt.UserRole-1).name].basicvalue
            return val
        return None

    # Virtual Base Method
    def flags(self, index: QtCore.QModelIndex):
        """ indicates the capabilities of the model from Delegate's perspective """
        # necessary for setData to function properly
        flags = QtCore.QAbstractListModel.flags(index)
        flags |= Qt.ItemIsSelectable
        if index.isValid():
            flags |= Qt.ItemIsEditable | Qt.ItemIsDragEnabled | Qt.ItemNeverHasChildren
        else:
            flags |= Qt.ItemIsDropEnabled
        return flags

    # Virtual Base Method
    @pyqtSlot(int, int, result=bool)
    def insertRows(self, row: int, count: int, parent=QtCore.QModelIndex()):
        """ insert default constructed objects at row """
        if self.rowCount() <= 0:
            row = 0
        self.beginInsertRows(parent, row, row+count-1)
        for i in range(count):
            self._items.insert(row+i, SequenceItem(parent=self))
            self.connectSignals(self._items[row+i])
        self.endInsertRows()
        self.onMemberDataChanged.emit()
        return True

    # Virtual Base Method
    @pyqtSlot(int, int, result=bool)
    def removeRows(self, row: int, count: int, parent=QtCore.QModelIndex()):
        """ remove a number of rows from model """
        if self.rowCount() <= 0:
            return False
        self.beginRemoveRows(QtCore.QModelIndex(), row, row+count-1)
        for i in range(count):
            self.disconnectSignals(self._items[row+i])
        del self._items[row:row+count]
        self.endRemoveRows()
        self.onMemberDataChanged.emit()
        return True

    # Virtual Base Method
    @pyqtSlot(int, int, int, result=bool)
    def moveRows(self, sourceRow: int, count: int, destinationChild: int):
        """ Move sourceRow->sourceRow+count to destinationChild and trigger view refresh """
        if (sourceRow < 0 or self.rowCount() <= sourceRow) \
        or (destinationChild < 0 or self.rowCount() <= destinationChild):
            return False
        if count > 1:
            raise NotImplementedError(f'{__name__} is not yet implemented for count > 1')

        # see http://doc.qt.io/qt-5/qabstractitemmodel.html#beginMoveRows for explanation
        if (destinationChild < sourceRow):
            destIndex = destinationChild
        elif (sourceRow<=destinationChild<=(sourceRow+count-1)):
            destIndex = destinationChild-(sourceRow+count-1)-1+sourceRow
        else:
            destIndex = destinationChild+1
        self.beginMoveRows(QtCore.QModelIndex(), sourceRow, sourceRow+count-1, QtCore.QModelIndex(), destIndex)
        for i in range(count):
            self._items.insert(destinationChild, self._items.pop(sourceRow+i))
            #  print(f'moving from {sourceRow} to {destinationChild}')
        self.endMoveRows()
        self.onMemberDataChanged.emit()
        return True

    # Virtual Base Method
    @pyqtSlot(QtCore.QModelIndex, QtCore.QVariant, result=bool)
    def setData(self, index: QtCore.QModelIndex, value: QtCore.QVariant, role: int=Qt.EditRole):
        """ modify the value of data object at index """
        print(index.row(), value, role, _getEnumMemberFromInt(SequenceUserRoles, role))
        if not index.isValid():
            return False

        if role == Qt.EditRole:
            self._items[index.row()] = value
            self.dataChanged.emit(index, index)
        elif Qt.UserRole<role<Qt.UserRole+len(SequenceUserRoles.__members__)+1:
            print('setting for role {!s}'.format(_getEnumMemberFromInt(SequenceUserRoles, role)))
        else:
            return False

        self.onMemberDataChanged.emit()
        return True

    # Virtual Base Method
    def roleNames(self):
        """ Returns dict mapping all possible roles to their unique integers
            A role should be defined for every member that will be accessed by a QML Delegate """
        hashmap = {e.value: bytes(e.name, 'ascii') for e in SequenceUserRoles.__members__.values() }
        return hashmap
