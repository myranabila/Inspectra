"""
DOSH (Department of Occupational Safety and Health) Registration Numbers
Fixed mapping for each equipment type in accordance with Malaysian regulations
"""

# DOSH Registration Numbers for Equipment Types
# Format: DOSH/PV/[State]/[Year]/[Number]
# These are fixed per equipment type for consistency across the system

DOSH_REGISTRATION_MAP = {
    "Reactor": "DOSH/PV/SEL/2024/001-R",           # Reactor vessels
    "Pressure Vessel": "DOSH/PV/SEL/2024/002-PV",  # Pressure vessels
    "Heat Exchanger": "DOSH/PV/SEL/2024/003-HE",   # Heat exchangers
    "Storage Tank": "DOSH/PV/SEL/2024/004-ST",     # Storage tanks
    "Tower": "DOSH/PV/SEL/2024/005-TW"             # Towers/columns
}

def get_dosh_registration(equipment_type: str) -> str:
    """
    Get the fixed DOSH registration number for an equipment type
    
    Args:
        equipment_type: The type of equipment (Reactor, Pressure Vessel, etc.)
    
    Returns:
        DOSH registration number string
    
    Raises:
        ValueError: If equipment type is not recognized
    """
    if equipment_type not in DOSH_REGISTRATION_MAP:
        raise ValueError(
            f"Unknown equipment type: {equipment_type}. "
            f"Valid types are: {', '.join(DOSH_REGISTRATION_MAP.keys())}"
        )
    
    return DOSH_REGISTRATION_MAP[equipment_type]


def get_all_dosh_registrations() -> dict:
    """
    Get all DOSH registration numbers
    
    Returns:
        Dictionary mapping equipment types to DOSH registration numbers
    """
    return DOSH_REGISTRATION_MAP.copy()


# Equipment type validation
VALID_EQUIPMENT_TYPES = list(DOSH_REGISTRATION_MAP.keys())


def is_valid_equipment_type(equipment_type: str) -> bool:
    """Check if an equipment type is valid"""
    return equipment_type in VALID_EQUIPMENT_TYPES
