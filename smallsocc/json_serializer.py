# -*- coding: utf-8 -*-
"""
Borrowed from https://stackoverflow.com/a/10420059/6347151 - jterrace under BSD licence
"""

SPACE = " "
NEWLINE = "\n"

def to_json(o, level=0, indent=2, separators=(",", ":")):
    com, col = separators

    ret = ""
    if isinstance(o, dict):
        ret += "{" + NEWLINE
        comma = ""
        for k,v in o.items():
            ret += comma
            comma = com + "\n"
            ret += SPACE * indent * (level+1)
            ret += '"' + str(k) + '"' + col
            ret += to_json(v, level + 1)

        ret += '\n' + SPACE * indent * level + "}"
    elif isinstance(o, str):
        ret += '"' + o + '"'
    elif isinstance(o, list):
        ret += "[" + com.join([to_json(e, level+1) for e in o]) + "]"
    elif isinstance(o, bool):
        ret += "true" if o else "false"
    elif isinstance(o, int):
        ret += str(o)
    elif isinstance(o, float):
        ret += '%.7g' % o
    elif o is None:
        ret += 'null'
    else:
        raise TypeError("Unknown type '%s' for json serialization" % str(type(o)))
    return ret
