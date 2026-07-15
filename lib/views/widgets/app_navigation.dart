import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fatora/core/constants/app_colors.dart';

class AppNavigation {
  static const dashboardRoute = '/dashboard';
  static const invoicesRoute = '/invoices';
  static const newInvoiceRoute = '/invoice/new';
  static const settingsRoute = '/settings';

  static const _routes = [
    dashboardRoute,
    invoicesRoute,
    newInvoiceRoute,
    settingsRoute,
  ];

  static const _labels = [
    'الرئيسية',
    'الفواتير',
    'فاتورة جديدة',
    'الإعدادات',
  ];

  static const _icons = [
    CupertinoIcons.home,
    CupertinoIcons.doc_text_fill,
    CupertinoIcons.add_circled_solid,
    CupertinoIcons.settings,
  ];

  static void openIndex(
    BuildContext context,
    int index, {
    required int currentIndex,
  }) {
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  static Future<void> showMenu(
    BuildContext context, {
    required int currentIndex,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_labels.length, (index) {
                final isSelected = index == currentIndex;
                return ListTile(
                  leading: Icon(
                    _icons[index],
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(
                    _labels[index],
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openIndex(context, index, currentIndex: currentIndex);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  static Widget bottomNav({
    required BuildContext context,
    required int currentIndex,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline.withOpacity(0.3))),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => openIndex(context, index, currentIndex: currentIndex),
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text_fill), label: 'الفواتير'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.add_circled_solid, size: 28), label: 'فاتورة جديدة'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }

  static Widget desktopSideNav({
    required BuildContext context,
    required int currentIndex,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        border: Border(left: BorderSide(color: AppColors.outline.withOpacity(0.2))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'FAWTARA',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          for (var index = 0; index < _labels.length; index++)
            _SideNavItem(
              label: _labels[index],
              icon: _icons[index],
              isSelected: index == currentIndex,
              onTap: () => openIndex(context, index, currentIndex: currentIndex),
            ),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        tileColor: isSelected ? AppColors.primaryContainer : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
