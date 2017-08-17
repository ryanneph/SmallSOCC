"""leafletassembly.py

Collection of controllable leaflets in custom configurations
"""

class LeafletAssemblyBase():
    """Base class for all leaflet assembly types"""
    def __init__(self):
        self.leaflets = []


    def set_positions(pos_map):
        for idx, pos in pos_map.items()
            soc_hw.set_position(idx, pos)
