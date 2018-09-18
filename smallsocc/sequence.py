# -*- coding: utf-8 -*-
"""
sequence.py

implements data structure containing a single "control point" item in a radiotherapy treatment sequence
with implementation for read-from-file and write-to-file methods

"""
import sys
import os
import math
from enum import Enum, unique
import copy
import json
import json_serializer
import logging
from datetime import datetime
from PyQt5 import QtCore, QtQml
from PyQt5.QtCore import Qt, pyqtSignal, pyqtSlot, pyqtProperty
from PyQt5.QtQml import qmlRegisterType
from sequence_members import _sequenceitem_public_members, SequenceItemType, datetimefmt

logger = logging.getLogger(__name__)

""" Defines user roles for accessing data items in SequenceItem Object """
SequenceUserRoles = Enum("SequenceUserRoles", list(_sequenceitem_public_members.keys()), start=Qt.UserRole)

def roleInt2Name(idx: int):
    """ helper for accessing enum member from its mapped integer value """
    e = SequenceUserRoles
    if Qt.UserRole <= idx < Qt.UserRole+len(e.__members__):
        return (list(e.__members__.values())[idx-Qt.UserRole]).name
    else:
        return None


class SequenceItem(QtCore.QObject):
    """ Backend representation for distinct setting of leaflet positions, beam angles,
    and occurence time in a treatment plan """

    def __init__(self, parent=None, **kwargs):
        """
        Keyword Args:
            All valid kwargs are detailed in _sequenceitem_public_members
        """
        QtCore.QObject.__init__(self, parent)
        # private members
        self._members = copy.deepcopy(_sequenceitem_public_members)
        self._memberstate = ""

        if len(kwargs):
            # handle angle setting in degrees
            for k in ['rot_gantry_rad', 'rot_couch_rad']:
                if k in kwargs:
                    kr = k.replace('rad', 'deg')
                    self._members[kr].value = kwargs[k] * 180 / math.pi
                    del kwargs[k]

            # set from kwargs
            for k, v in kwargs.items():
                try:
                    if k not in self._members:
                        logger.error('"{!s}" is not a property of SequenceItem'.format(k))
                    else:
                        logger.debug2('setting self._members[{!s}] to {!s}'.format(k, kwargs[k]))
                        self._members[k].value = kwargs[k]
                except:
                    logger.warning('failed to set SequenceItem property: {!s}'.format(k))
                    continue

    def __repr__(self):
        s = ''
        for i, (k, v) in enumerate(self._members.items()):
            if i != 0: s += '\n'
            s += '{!s}: {!s}'.format(k, v.value)
        return s

    def __getitem__(self, key):
        self.get(key)

    def __setitem__(self, key, val):
        self.set(key, val)

    def packDict(self):
        """ construct a dictionary of (member name, basicvalue) pairs """
        d = {}
        for k, v in self._members.items():
            if not v.volatile:
                logger.debug2('{} is a {} with val: {} and basicval: {}'.format(k, type(v.value), v.value, v.basicvalue))
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

        if val is not None:
            logger.debug2('setting new value for \"{}\": {}'.format(key, val))
            self._members[key].value = val
        elif key is not None:
            for k, v in key.items():
                logger.debug2('setting new value for \"{}\": {}'.format(k, v))
                self._members[k].value = v
        else: return False
        self.setModified()
        return True

    # signal activation cascades to SequenceListModel
    onMemberDataChanged = pyqtSignal()
    def setModified(self):
        self._members['is_unsaved'].value = True
        self.onMemberDataChanged.emit()

    def setUnmodified(self):
        self._members['is_unsaved'].value = False
        self.onMemberDataChanged.emit()



class SequenceListModel(QtCore.QAbstractListModel):
    """ Model for manipulating an ordered list of SequenceItems from QML ListView

    NOTE: anytime a new SequenceItem() instance is added to this collection, you MUST set the parent of the
          SequenceItem QObject to "self" of this class. Otherwise, when handing these instances to qml through
          self.getItem(), python will garbage collect the SequenceItem instance and qml will throw an error
    """

    ## CONSTRUCTORS
    def __init__(self, *args, **kwargs):
        """ initialize from dictionary if kwarg 'elements=[]' is provided """
        QtCore.QAbstractListModel.__init__(self, None)
        try:
            self._items = kwargs['elements']
        except:
            self._items = []

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
            logger.exception('Error in {}.readFromJson(): failed to read SequenceList from file "{}"'.format(self, fname))
            return False

        self.beginResetModel()
        self._items = seqitems
        self.endResetModel();
        self.sizeChanged.emit(self.rowCount())
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

            for idx, mem in enumerate(self._items):
                mem.setUnmodified()
                self.redrawItemDelegate(idx)

        except Exception as e:
            logger.exception(e)
            return False
        return True

    def redrawItemDelegate(self, idx):
        try:
            if isinstance(idx, int):
                modelindex = self.createIndex(idx, 0)
            else:
                modelindex = idx
            self.dataChanged.emit(modelindex, modelindex)
        except:
            logger.exception('delegate refresh failed for index "{}"'.format(str(idx)))

    ## METHODS
    # Virtual Base Method
    sizeChanged = pyqtSignal([int])
    @pyqtProperty(int, notify=sizeChanged)
    def size(self):
        return self.rowCount()

    @pyqtSlot(result=int)
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
    @pyqtSlot(int, int, result=QtCore.QVariant)
    @pyqtSlot(int, str, result=QtCore.QVariant)
    @pyqtSlot(QtCore.QModelIndex, result=QtCore.QVariant)
    @pyqtSlot(int, result=QtCore.QVariant)
    def data(self, index: QtCore.QModelIndex, role: int=Qt.DisplayRole):
        """ Get data item indexed by index.row() and member indicated by role """
        if isinstance(index, int):
            index = self.createIndex(index, 0)
        if not index.isValid():
            return False

        if isinstance(role, str):
            rolename = role
            role = SequenceUserRoles[rolename].value
        elif isinstance(role, int):
            rolename = roleInt2Name(role)

        if index.row() > self.rowCount(): return False
        if role == Qt.DisplayRole or role == Qt.EditRole:
            return self._items[index.row()].get()
        if Qt.UserRole <= role < Qt.UserRole+len(SequenceUserRoles.__members__):
            logger.debug2('accessing delegate data role: {}:{}'.format(role, rolename))
            sequenceitem = self._items[index.row()]
            val = sequenceitem._members[rolename].basicvalue
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
    @pyqtSlot(result=bool)
    @pyqtSlot(int, int, result=bool)
    def insertRows(self, row: int=-1, count: int=1, parent=QtCore.QModelIndex()):
        """ insert default constructed objects at row """
        if count < 1: return False
        if self.rowCount() <= 0:
            row = 0
        elif row < 0:
            # add to end of list
            row = self.rowCount()
        self.beginInsertRows(parent, row, row+count-1)
        for i in range(count):
            self._items.insert(row+i, SequenceItem(parent=self, type=SequenceItemType.Manual))
        self.endInsertRows()
        self.sizeChanged.emit(self.rowCount())
        return True

    # Virtual Base Method
    @pyqtSlot(int, int, result=bool)
    def removeRows(self, row: int, count: int, parent=QtCore.QModelIndex()):
        """ remove a number of rows from model """
        if self.rowCount() <= 0 or row < 0 or count < 1:
            return False
        self.beginRemoveRows(QtCore.QModelIndex(), row, row+count-1)
        del self._items[row:row+count]
        self.endRemoveRows()
        if self.rowCount() <=0:
            self.beginResetModel()
            self.endResetModel();
        self.sizeChanged.emit(self.rowCount())
        return True

    @pyqtSlot()
    def clear(self):
        self.removeRows(0, self.rowCount())

    # Virtual Base Method
    @pyqtSlot(int, int, int, result=bool)
    def moveRows(self, sourceRow: int, count: int, destinationChild: int):
        """ Move sourceRow->sourceRow+count to destinationChild and trigger view refresh """
        if (sourceRow < 0 or self.rowCount() <= sourceRow) \
        or (destinationChild < 0 or self.rowCount() <= destinationChild):
            return False
        if count > 1:
            raise NotImplementedError('{} is not yet implemented for count > 1'.format(__name__))

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
            logger.debug2('moving from {} to {}'.format(sourceRow, destinationChild))
        self.endMoveRows()
        return True

    # Virtual Base Method
    @pyqtSlot(QtCore.QModelIndex, QtQml.QJSValue, result=bool)
    @pyqtSlot(int, QtQml.QJSValue,      result=bool)
    @pyqtSlot(int, QtQml.QJSValue, str, result=bool)
    def setData(self, index: QtCore.QModelIndex, value: QtCore.QVariant, role: int=Qt.EditRole):
        """ modify the value of data object at index """
        if isinstance(index, int):
            index = self.createIndex(index, 0)
        if not index.isValid():
            return False

        if isinstance(role, str):
            rolename = role
            role = SequenceUserRoles[rolename].value
        elif isinstance(role, int):
            rolename = roleInt2Name(role)

        if isinstance(value, QtQml.QJSValue):
            value = value.toVariant()

        logger.debug2("setting data at row {} to {} using role {}: {}".format(index.row(), value, role, rolename))

        if role == Qt.EditRole and isinstance(value, SequenceItem):
            self._items[index.row()] = value
            self.dataChanged.emit(index, index)
        elif isinstance(value, dict):
            for k, v in value.items():
                self._items[index.row()][k] = v
        elif Qt.UserRole <= role < Qt.UserRole+len(SequenceUserRoles.__members__):
            self._items[index.row()][rolename] = value
        else:
            return False
        self.redrawItemDelegate(index)
        return True

    # Virtual Base Method
    def roleNames(self):
        """ Returns dict mapping all possible roles to their unique integers
            A role should be defined for every member that will be accessed by a QML Delegate """
        hashmap = {e.value: bytes(e.name, 'ascii') for e in SequenceUserRoles.__members__.values() }
        return hashmap
