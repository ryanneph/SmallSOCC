import math
from enum import Enum, unique
from datetime import datetime
from named_member import NamedMember

# default format for all datetime strings
datetimefmt = '%Y %b %d %H:%M:%S'

@unique
class SequenceItemType(Enum):
    """ Defines types of sequence items that can exists """
    Auto, Manual = range(2)


## CUSTOM GETTERS/SETTERS
def date_created_getter(dt: datetime, fmt: str=datetimefmt, as_basic=False, *args, **kwargs) -> str:
    """ return str repr of datetime obj """
    if as_basic: return dt.strftime(fmt)
    else: return dt

def date_created_setter(val: object):
    """ set datetime from obj or str """
    if isinstance('datetime'):
        return val
    try: return datetime.strptime(val, datetimefmt)
    except: raise RuntimeError(f"string: \"{val}\" couldn't be mapped to a valid \"datetime\"")

def type_getter(e: SequenceItemType, as_basic=False, *args, **kwargs):
    if as_basic:
        return e.name
    else: return e

def type_setter(val: object):
    """ set enum type from string or enum directly """
    if isinstance(val, SequenceItemType):
        return val
    try:
        return SequenceItemType[str(val)]
    except: raise RuntimeError(f"string: \"{val}\" couldn't be mapped to a valid \"SequenceItemType\"")

#  def deg_to_rad(deg: float) -> float:
#      return math.pi * deg / 180

#  def rad_to_deg(rad: float) -> float:
#      return 180 * rad / math.pi

#  def rot_deg_getter(rad: float, *args, **kwargs) -> float:
#      return rad_to_deg(rad)

#  def rot_deg_setter(deg: float, *args, **kwargs) -> float:
#      return deg_to_rad(deg)



## Defines all accessible members and their getters/setters
## All items in this dict will be automatically instantiated as valid Qt Roles for the data model
##   and will hence be accessible properties from QML
_sequenceitem_public_members = {v.name: v for v in
    [
        NamedMember('extension_list', [0 for _ in range(8)]),
        NamedMember('rot_gantry_deg', 0),
        NamedMember('rot_couch_deg', 0),
        NamedMember('timecode_ms', 0),
        NamedMember('description', ''),
        NamedMember('date_created', value_initializer=lambda: datetime.now(), getter=date_created_getter, setter=date_created_setter),
        NamedMember('type', SequenceItemType.Auto, getter=type_getter, setter=type_setter),
    ] }
