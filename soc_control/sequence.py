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
from PyQt5 import QtCore
from PyQt5.QtCore import Qt, pyqtSignal, pyqtSlot
from PyQt5.QtQml import qmlRegisterType
from sequence_members import _sequenceitem_public_members, SequenceItemType, datetimefmt


""" Defines user roles for accessing data items in SequenceItem Object """
SequenceUserRoles = Enum("SequenceUserRoles",
        list(_sequenceitem_public_members.keys()), start=Qt.UserRole+1)

def _getEnumMemberFromInt(enum: Enum, idx: int):
    """ helper for accessing enum member from its mapped integer value """
    return list(enum.__members__.values())[idx]


class SequenceItem():
    """ Backend representation for distinct setting of leaflet positions, beam angles,
    and occurence time in a treatment plan """

    def __init__(self, **kwargs):
        """
        Keyword Args:
            All valid kwargs are detailed in _sequenceitem_public_members
        """
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
                try: self._members[k].value = kwargs[k]
                except: pass

    def __repr__(self):
        s = ''
        for i, (k, v) in enumerate(self._members.items()):
            if i != 0: s += '\n'
            s += '{!s}: {!s}'.format(k, v.value)
        return s

    def packDict(self):
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


class SequenceListModel(QtCore.QAbstractListModel):
    """ Model for manipulating an ordered list of SequenceItems from QML ListView """

    def __init__(self, *args, **kwargs):
        """ initialize from dictionary if kwarg 'elements=[]' is provided """
        QtCore.QAbstractListModel.__init__(self, None)
        try:
            elements = kwargs['elements']
            self._elements = elements
        except:
            self._elements = []

    # Virtual Base Method
    def rowCount(self, parent=QtCore.QModelIndex()):
        return len(self._elements)

    # Virtual Base Method
    def data(self, index: QtCore.QModelIndex, role: int=Qt.DisplayRole):
        """ Get data item indexed by index.row() and member indicated by role """
        if not index.isValid(): return None
        if index.row() > len(self._elements): return None
        if role == Qt.DisplayRole or role == Qt.EditRole:
            return self._elements[index.row()]
        if Qt.UserRole < role < Qt.UserRole+len(SequenceUserRoles.__members__)+1:
            sequenceitem = self._elements[index.row()]
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
        self.layoutAboutToBeChanged.emit()
        self.beginInsertRows(parent, row, row+count-1)
        for i in range(count):
            self._elements.insert(row+i, SequenceItem())
        self.endInsertRows()
        self.layoutChanged.emit()
        return True

    # Virtual Base Method
    @pyqtSlot(int, int, result=bool)
    def removeRows(self, row: int, count: int, parent=QtCore.QModelIndex()):
        """ remove a number of rows from model """
        self.beginRemoveRows(QtCore.QModelIndex(), row, row+count-1)
        del self._elements[row:row+count]
        self.endRemoveRows()
        return True

    # Virtual Base Method
    @pyqtSlot(int, int, int, result=bool)
    def moveRows(self, sourceRow: int, count: int, destinationChild: int):
        """ Move sourceRow->sourceRow+count to destinationChild and trigger view refresh """
        if (sourceRow < 0 or len(self._elements) <= sourceRow) \
        or (destinationChild < 0 or len(self._elements) <= destinationChild):
            return False
        if count > 1:
            raise NotImplementedError(f'{__name__} is not yet implemented for count > 1')

        self.layoutAboutToBeChanged.emit()
        self.beginMoveRows(self.index(sourceRow), sourceRow, count, self.index(destinationChild), destinationChild)
        for i in range(count):
            self._elements.insert(destinationChild, self._elements.pop(sourceRow+i))
            #  print(f'moving from {sourceRow} to {destinationChild}')
        self.endMoveRows()
        self.layoutChanged.emit()
        return True

    # Virtual Base Method
    def setData(self, index: QtCore.QModelIndex, value: QtCore.QVariant, role: int=Qt.EditRole):
        """ modify the value of data object at index """
        if not index.isValid() or role != Qt.EditRole:
            return False

        self._elements[index.row()] = value
        self.dataChanged.emit(index, index)
        return True

    # Virtual Base Method
    def roleNames(self):
        """ Returns dict mapping all possible roles to their unique integers
            A role should be defined for every member that will be accessed by a QML Delegate """
        hashmap = {e.value: bytes(e.name, 'ascii') for e in SequenceUserRoles.__members__.values() }
        return hashmap

    def writeToJson(self, fname: str):
        """ write all member vars to json for later recall """
        memlist = []
        for mem in self._elements:
            memlist.append(mem.packDict())

        # wrap with header
        d = {'metadata': {'generated_on': datetime.now().strftime(datetimefmt)},
             'SequenceList': memlist }

        #  js = json_serializer.to_json(d)
        js = json.dumps(d, indent=2, separators=(',', ':'), sort_keys=True)

        with open(fname, 'w') as f:
            f.write(js)

    @classmethod
    def readFromJson(cls, fname):
        with open(fname, 'r') as f:
            d = json.load(f)

        try:
            seqitems = []
            for itemdict in d['SequenceList']:
                seqitems.append(SequenceItem(**itemdict))
        except Exception as e:
            raise RuntimeError(f"Error in {cls.__name__}.readFromJson(): failed to read SequenceList from file \"{fname}\"")

        return SequenceListModel(elements=seqitems)

# Necessary to make this type accessible from QML
#  qmlRegisterType(SequenceListModel, 'com.soc.types.SequenceListModel', 1, 0, 'SequenceListModel')


####################################################################################################
# TODO Replace with xml/ini/json load method
## SAMPLE ITEMS FOR DEBUG
#  sample_sequenceitems = [
#      SequenceItem(rot_couch_deg=5, rot_gantry_deg=0, timecode_ms=1500, datecreatedstr="2016 Oct 31 12:00:00", type='Manual'),
#      SequenceItem(rot_couch_deg=12, rot_gantry_deg=120, timecode_ms=1500, description="descriptive text2", type=SequenceItemType.Auto),
#      SequenceItem(rot_couch_deg=24, rot_gantry_deg=25, timecode_ms=1500, description="descriptive text3"),
#      SequenceItem(rot_couch_deg=0, rot_gantry_deg=45, timecode_ms=1500, description="descriptive text4"),
#  ]
#  samplelistmodel = SequenceListModel(elements=sample_sequenceitems)
#  samplelistmodel.writeToJson('test_output.json')

