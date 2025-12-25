"""
MANAGER UI - Updated Assign Task Page
File: lib/assign_task_page.dart

This shows the KEY CHANGES needed to the existing assign_task_page.dart
Replace the form section with this updated version
"""

// DROPDOWN DATA CONSTANTS (Add at top of file)
class EquipmentData {
  static const List<String> types = [
    'Reactor',
    'Pressure Vessel',
    'Heat Exchanger',
    'Storage Tank',
    'Tower',
  ];
  
  static const List<String> areas = [
    'Plant 1',
    'Plant 2',
    'Utility Area',
    'Offsite Area',
    'Process Area',
  ];
  
  static String getTagPrefix(String equipmentType) {
    switch (equipmentType) {
      case 'Reactor':
        return 'R';
      case 'Pressure Vessel':
        return 'P';
      case 'Heat Exchanger':
        return 'H';
      case 'Storage Tank':
        return 'T';
      case 'Tower':
        return 'TW';
      default:
        return '';
    }
  }
  
  static String getTagFormat(String equipmentType) {
    final prefix = getTagPrefix(equipmentType);
    return prefix.isEmpty ? '' : '$prefix + 3 digits (e.g., ${prefix}001)';
  }
