import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../my_tasks_page.dart';
import '../history_page.dart';
import '../threads_list_page.dart';
import '../reminders_page.dart';
import '../inspector_profile_page.dart';
import '../assign_task_page.dart';
import '../manager_approvals_page.dart';
import '../inspector_management_page.dart';
import '../manager_user_management_page.dart';
import '../dashboard_page.dart';
import '../manager_dashboard_page.dart';
import '../utils/sidebar_state.dart';
import '../utils/animations_config.dart';

/// A reusable collapsible sidebar with full navigation
/// Can be used across all pages in the app for consistent navigation
class CollapsibleSidebar extends StatefulWidget {
  final String currentPage;
  final bool isMainPage; // If true, hide Back button (main feature pages)
  
  const CollapsibleSidebar({
    super.key,
    required this.currentPage,
    this.isMainPage = true, // Default to true (hide Back on main pages)
  });
  
  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  String? _userRole;
  
  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }
  
  Future<void> _loadUserRole() async {
    final role = await AuthService.getUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }
  
  void _toggleSidebar() {
    setState(() {
      SidebarState.toggle();
    });
  }
  
  void _navigateTo(Widget page) {
    // Use smooth fade transition for main page navigation
    Navigator.pushReplacement(
      context,
      FadePageRoute(page: page),
    );
  }
  
  void _navigateToPage(Widget page) {
    // Use smooth slide+fade transition for sub-page navigation
    Navigator.push(
      context,
      SlidePageRoute(page: page),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isManager = _userRole == 'manager';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: SidebarState.isCollapsed ? 70 : 260,
      decoration: BoxDecoration(
        gradient: AppTheme.sidebarGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with toggle button
          _buildHeader(isManager),
          const SizedBox(height: 8),
          
          // Navigation items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavSection('MAIN'),
                  _buildNavItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    page: 'dashboard',
                    onTap: () {
                      if (isManager) {
                        _navigateTo(const ManagerDashboardPage());
                      } else {
                        _navigateTo(const DashboardModule());
                      }
                    },
                  ),
                  
                  if (isManager) ...[
                    const SizedBox(height: 24),
                    _buildNavSection('MANAGEMENT'),
                    _buildNavItem(
                      icon: Icons.assignment_ind_rounded,
                      label: 'Assign Task',
                      page: 'assign_task',
                      onTap: () => _navigateTo(const AssignTaskPage()),
                    ),
                    _buildNavItem(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending Approvals',
                      page: 'approvals',
                      onTap: () => _navigateTo(const ManagerApprovalsPage()),
                    ),
                    _buildNavItem(
                      icon: Icons.people_rounded,
                      label: 'Inspector Management',
                      page: 'inspector_management',
                      onTap: () => _navigateTo(const InspectorManagementPage()),
                    ),
                    _buildNavItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'User Management',
                      page: 'user_management',
                      onTap: () => _navigateTo(const ManagerUserManagementPage()),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    _buildNavSection('TASKS'),
                    _buildNavItem(
                      icon: Icons.assignment_rounded,
                      label: 'Pending Task',
                      page: 'my_tasks',
                      onTap: () => _navigateTo(const MyTasksPage()),
                    ),
                    _buildNavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      page: 'history',
                      onTap: () => _navigateTo(const HistoryPage()),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildNavSection('COMMUNICATION'),
                  _buildNavItem(
                    icon: Icons.message_rounded,
                    label: 'Messages',
                    page: 'messages',
                    onTap: () => _navigateTo(const ThreadsListPage()),
                  ),
                  if (!isManager)
                    _buildNavItem(
                      icon: Icons.notifications_rounded,
                      label: 'Reminders',
                      page: 'reminders',
                      onTap: () => _navigateTo(const RemindersPage()),
                    ),
                  
                  const SizedBox(height: 24),
                  _buildNavSection('ACCOUNT'),
                  _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'My Profile',
                    page: 'profile',
                    onTap: () => _navigateTo(const InspectorProfilePage()),
                  ),
                ],
              ),
            ),
          ),
          
          // Back & Logout Section
          const Divider(color: Colors.white24),
          // Only show Back button on sub-pages, not main feature pages
          if (!widget.isMainPage)
            _buildNavItem(
              icon: Icons.arrow_back_rounded,
              label: 'Back',
              page: '',
              onTap: () {
                // If we can go back in navigation stack, do so
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  // Otherwise, navigate to appropriate dashboard with smooth transition
                  if (_userRole == 'manager') {
                    Navigator.pushReplacement(
                      context,
                      FadePageRoute(page: const ManagerDashboardPage()),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      FadePageRoute(page: const DashboardModule()),
                    );
                  }
                }
              },
            ),
          _buildNavItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            page: '',
            isDestructive: true,
            onTap: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildHeader(bool isManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _toggleSidebar,
            icon: Icon(
              SidebarState.isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: Colors.white,
            ),
            tooltip: SidebarState.isCollapsed ? 'Expand Menu' : 'Collapse Menu',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          if (!SidebarState.isCollapsed) ...[
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/ipetro_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.business_rounded,
                      color: Color(0xFFDC2626),
                      size: 28,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'i',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: 'PETRO',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    isManager ? 'Manager Portal' : 'Inspector Portal',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildNavSection(String title) {
    if (SidebarState.isCollapsed) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String page,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isActive = widget.currentPage == page;
    final color = isDestructive 
        ? AppTheme.primaryRed
        : isActive 
            ? Colors.white 
            : const Color(0xFF94A3B8);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryRed.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SidebarState.isCollapsed ? 0 : 12, 
              vertical: 12
            ),
            child: Row(
              mainAxisAlignment: SidebarState.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
                if (!SidebarState.isCollapsed) ...[ 
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
