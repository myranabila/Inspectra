/// DOSH (Department of Occupational Safety and Health) Registration Numbers
/// Fixed mapping for each equipment type in accordance with Malaysian regulations

/// DOSH Registration Numbers for Equipment Types
/// Format: DOSH/PV/[State]/[Year]/[Number]
/// These are fixed per equipment type for consistency across the system
class DoshConfig {
  static const Map<String, String> doshRegistrationMap = {
    'Reactor': 'DOSH/PV/SEL/2024/001-R',           // Reactor vessels
    'Pressure Vessel': 'DOSH/PV/SEL/2024/002-PV',  // Pressure vessels
    'Heat Exchanger': 'DOSH/PV/SEL/2024/003-HE',   // Heat exchangers
    'Storage Tank': 'DOSH/PV/SEL/2024/004-ST',     // Storage tanks
    'Tower': 'DOSH/PV/SEL/2024/005-TW',            // Towers/columns
  };

  /// Get the fixed DOSH registration number for an equipment type
  /// 
  /// [equipmentType] The type of equipment (Reactor, Pressure Vessel, etc.)
  /// Returns DOSH registration number string
  /// Throws [ArgumentError] if equipment type is not recognized
  static String getDoshRegistration(String equipmentType) {
    if (!doshRegistrationMap.containsKey(equipmentType)) {
      throw ArgumentError(
        'Unknown equipment type: $equipmentType. '
        'Valid types are: ${doshRegistrationMap.keys.join(', ')}'
      );
    }
    
    return doshRegistrationMap[equipmentType]!;
  }

  /// Get DOSH registration with a fallback for unknown types
  /// Returns empty string if type is not found (instead of throwing error)
  static String getDoshRegistrationSafe(String? equipmentType) {
    if (equipmentType == null || equipmentType.isEmpty) {
      return '';
    }
    
    return doshRegistrationMap[equipmentType] ?? '';
  }

  /// Get all DOSH registration numbers
  /// Returns a copy of the mapping
  static Map<String, String> getAllDoshRegistrations() {
    return Map.from(doshRegistrationMap);
  }

  /// Check if an equipment type is valid
  static bool isValidEquipmentType(String equipmentType) {
    return doshRegistrationMap.containsKey(equipmentType);
  }

  /// Get list of all valid equipment types
  static List<String> getValidEquipmentTypes() {
    return doshRegistrationMap.keys.toList();
  }
}
