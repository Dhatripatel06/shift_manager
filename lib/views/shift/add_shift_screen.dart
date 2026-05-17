import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/shift_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/responsive_page.dart';
import '../../utils/formatters.dart';

/// Add/Edit shift form screen with date/time pickers and auto-calculations.
class AddShiftScreen extends StatelessWidget {
  const AddShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShiftController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.primaryDark : AppColors.surfaceLight,
      appBar: AppBar(
        title: Obx(() => Text(
              controller.isEditing.value ? 'Edit Shift' : 'Add New Shift',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ResponsivePage(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Date Picker ─────────────────────────────
              _buildSectionLabel('Date', isDark),
              const SizedBox(height: 8),
              Obx(() => _buildDatePicker(context, controller, isDark)),
              const SizedBox(height: 20),

              // ─── Event Name ──────────────────────────────
              _buildSectionLabel('Event Name', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.eventNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Concert at O2 Arena',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // ─── Job Role ────────────────────────────────
              _buildSectionLabel('Job Role', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.jobRoleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Bar Staff, Runner, Security',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // ─── Time Pickers ────────────────────────────
              _buildAdaptivePair(
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Start Time', isDark),
                        const SizedBox(height: 8),
                        Obx(() => _buildTimePicker(
                              context,
                              controller.selectedStartTime.value,
                              (time) {
                                controller.selectedStartTime.value = time;
                                controller.calculatePreview();
                          },
                          isDark,
                        )),
                      ],
                    ),
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('End Time', isDark),
                        const SizedBox(height: 8),
                        Obx(() => _buildTimePicker(
                              context,
                              controller.selectedEndTime.value,
                              (time) {
                                controller.selectedEndTime.value = time;
                                controller.calculatePreview();
                          },
                          isDark,
                        )),
                      ],
                    ),
              ),
              const SizedBox(height: 20),

              // ─── Break Hours ─────────────────────────────
              _buildAdaptivePair(
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Break Hours', isDark),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller.breakHoursController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            hintText: '0.0',
                            prefixIcon: Icon(Icons.coffee_outlined),
                          ),
                          onChanged: (_) => controller.calculatePreview(),
                        ),
                      ],
                    ),
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Pay Per Hour (GBP)', isDark),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller.payPerHourController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            hintText: '12.00',
                            prefixIcon: Icon(Icons.currency_pound),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          onChanged: (_) => controller.calculatePreview(),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 20),

              // ─── Notes ───────────────────────────────────
              _buildSectionLabel('Notes (Optional)', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any additional notes...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Auto Calculation Preview ────────────────
              Obx(() => _buildCalculationPreview(controller, isDark)),
              const SizedBox(height: 24),

              // ─── Submit Button ───────────────────────────
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                bool success;
                                if (controller.isEditing.value) {
                                  success = await controller.updateShift();
                                } else {
                                  success = await controller.addShift();
                                }
                                if (success) Get.back();
                              }
                            },
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryDark),
                              ),
                            )
                          : Text(
                              controller.isEditing.value
                                  ? 'Update Shift'
                                  : 'Save Shift',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  )),
              const SizedBox(height: 24),

              // ─── Motivational Quote ──────────────────────
              Center(
                child: Text(
                  AppConstants.motivationalQuote,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.accent.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildAdaptivePair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              first,
              const SizedBox(height: 20),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    ShiftController controller,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: controller.selectedDate.value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.accent,
                    ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          controller.selectedDate.value = date;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDarkElevated : AppColors.cardLightElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 12),
            Text(
              Formatters.formatDate(controller.selectedDate.value),
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Spacer(),
            Text(
              Formatters.formatDay(controller.selectedDate.value),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context,
    TimeOfDay time,
    ValueChanged<TimeOfDay> onChanged,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.accent,
                    ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDarkElevated : AppColors.cardLightElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? AppColors.primaryLight.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(width: 8),
            Text(
              time.format(context),
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationPreview(
    ShiftController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Auto Calculation',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCalcItem(
                'Net Hours',
                Formatters.formatHoursMinutes(
                    controller.calculatedNetHours.value),
                Icons.schedule_outlined,
                isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
              _buildCalcItem(
                'Total Pay',
                Formatters.formatCurrency(
                    controller.calculatedTotalPay.value),
                Icons.payments_outlined,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalcItem(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.accent,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
