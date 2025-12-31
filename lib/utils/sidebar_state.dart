/// Global sidebar state management
/// Shared across all pages to maintain consistent collapse state
class SidebarState {
  static bool _isCollapsed = false;
  
  static bool get isCollapsed => _isCollapsed;
  
  static void setCollapsed(bool value) {
    _isCollapsed = value;
  }
  
  static void toggle() {
    _isCollapsed = !_isCollapsed;
  }
}
