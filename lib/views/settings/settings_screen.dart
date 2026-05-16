import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../services/sync_service.dart';
import '../../services/export_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/sync_indicator.dart';

/// Settings screen with profile, sync, export, and logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final syncService = Get.find<SyncService>();
    final exportService = Get.find<ExportService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Settings', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            const SizedBox(height: 24),

            // Profile
            _sectionTitle('Profile', isDark),
            const SizedBox(height: 8),
            _card(isDark: isDark, child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                backgroundImage: authCtrl.photoUrl != null ? NetworkImage(authCtrl.photoUrl!) : null,
                child: authCtrl.photoUrl == null ? Text(authCtrl.displayName.isNotEmpty ? authCtrl.displayName[0].toUpperCase() : 'U', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor)) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(authCtrl.displayName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(authCtrl.email ?? '', style: GoogleFonts.outfit(fontSize: 12, color: primaryColor)),
              ])),
              const SyncIndicator(),
            ])),
            const SizedBox(height: 24),

            // Data & Sync
            _sectionTitle('Data & Sync', isDark),
            const SizedBox(height: 8),
            _card(isDark: isDark, child: Column(children: [
              _settingRow(icon: Icons.sync_rounded, title: 'Sync Now', subtitle: 'Sync all data to cloud', isDark: isDark, trailing: IconButton(icon: Icon(Icons.sync_rounded, color: primaryColor), onPressed: () { syncService.syncAll(); Get.snackbar('Syncing', 'Data sync started...', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); })),
              _divider(isDark),
              _settingRow(icon: Icons.cloud_download_outlined, title: 'Restore from Cloud', subtitle: 'Restore all shifts from Firebase', isDark: isDark, trailing: IconButton(icon: Icon(Icons.cloud_download_outlined, color: AppColors.info), onPressed: () async { try { final count = await syncService.fullRestore(); Get.snackbar('Restored ✅', '$count shifts restored', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); } catch (e) { Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); } })),
            ])),
            const SizedBox(height: 24),

            // Export
            _sectionTitle('Export', isDark),
            const SizedBox(height: 8),
            _card(isDark: isDark, child: Column(children: [
              _settingRow(icon: Icons.table_chart_outlined, title: 'Export as CSV', subtitle: 'Spreadsheet format', isDark: isDark, trailing: IconButton(icon: Icon(Icons.download_outlined, color: AppColors.chartGreen), onPressed: () async { try { final ctrl = Get.find<ShiftController>(); final shifts = ctrl.getAllShiftsForExport(); if (shifts.isEmpty) { Get.snackbar('No Data', 'No shifts to export', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); return; } final path = await exportService.exportToCsv(shifts); Get.snackbar('Exported ✅', 'CSV saved to: $path', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4), margin: const EdgeInsets.all(16)); } catch (e) { Get.snackbar('Error', 'Export failed: $e', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); } })),
              _divider(isDark),
              _settingRow(icon: Icons.picture_as_pdf_outlined, title: 'Export as PDF', subtitle: 'Professional report', isDark: isDark, trailing: IconButton(icon: Icon(Icons.download_outlined, color: AppColors.error), onPressed: () async { try { final ctrl = Get.find<ShiftController>(); final shifts = ctrl.getAllShiftsForExport(); if (shifts.isEmpty) { Get.snackbar('No Data', 'No shifts to export', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); return; } final path = await exportService.exportToPdf(shifts); Get.snackbar('Exported ✅', 'PDF saved to: $path', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4), margin: const EdgeInsets.all(16)); } catch (e) { Get.snackbar('Error', 'Export failed: $e', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)); } })),
            ])),
            const SizedBox(height: 24),

            // About
            _sectionTitle('About', isDark),
            const SizedBox(height: 8),
            _card(isDark: isDark, child: _settingRow(icon: Icons.info_outline_rounded, title: AppConstants.appName, subtitle: 'Version ${AppConstants.appVersion}', isDark: isDark)),
            const SizedBox(height: 24),

            // Logout
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(authCtrl),
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text('Sign Out', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(height: 24),

            // Footer
            Center(child: Column(children: [
              Text('🙏 जय बजरंगबली 🙏', style: GoogleFonts.outfit(fontSize: 14, color: primaryColor.withValues(alpha: 0.5))),
              const SizedBox(height: 6),
              Text(AppConstants.motivationalQuote, style: GoogleFonts.outfit(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ])),
            const SizedBox(height: 80),
          ]),
        ),
      ),
    );
  }

  static Widget _sectionTitle(String t, bool isDark) => Text(t, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, letterSpacing: 1));

  static Widget _card({required bool isDark, required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: isDark ? AppColors.cardDark : AppColors.cardLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.cardDarkElevated.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1))),
    child: child,
  );

  static Widget _settingRow({required IconData icon, required String title, required String subtitle, required bool isDark, Widget? trailing}) {
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    return Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: primaryColor)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
      ])),
      if (trailing != null) trailing,
    ]);
  }

  static Widget _divider(bool isDark) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: isDark ? AppColors.cardDarkElevated.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)));

  static void _confirmLogout(AuthController authCtrl) {
    Get.dialog(AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure? Your data is safely stored in the cloud.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(onPressed: () { Get.back(); authCtrl.signOut(); }, style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Sign Out')),
      ],
    ));
  }
}
