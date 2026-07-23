import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/complaint/admin_complaint_controller.dart';
import 'package:smartstitch/core/widgets/shared_widgets.dart';

import '../../../core/theme/app.theme.dart';
import 'detail_widgets.dart';


enum ComplaintReplyMode { manual, template, ai }

/// Full "Response Editor" section: response-type selector, template/AI
/// pickers, rich text area, meta dropdowns, internal notes, and send action.
class ComplaintSmartReplyPanel extends StatefulWidget {
  final bool isDark;
  final String complaintId;
  final String category;
  final String description;
  final String currentStatus;
  const ComplaintSmartReplyPanel({
    super.key,
    required this.isDark,
    required this.complaintId,
    required this.category,
    required this.description,
    required this.currentStatus,
  });

  @override
  State<ComplaintSmartReplyPanel> createState() => _SmartReplyPanelState();
}

class _SmartReplyPanelState extends State<ComplaintSmartReplyPanel> {
  final ctrl = AdminComplaintController.to;
  final TextEditingController textCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  ComplaintReplyMode mode = ComplaintReplyMode.manual;
  String? selectedTemplate;
  String eta = '24 hours';
  String priority = 'Medium';
  bool customerVisible = true;

  static const etaOptions = ['24 hours', '48 hours', '3-5 days', '1 week'];
  static const priorityOptions = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    textCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(String label) {
    setState(() {
      selectedTemplate = label;
      textCtrl.text = AdminComplaintController.smartTemplates[label] ?? '';
    });
  }

  void _applyAiReply() {
    setState(() {
      textCtrl.text = ctrl.generateAiReply(category: widget.category, description: widget.description);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Smart Reply',
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1 — Choose Response Type', style: AppTextStyles.labelLarge.copyWith(color: ComplaintUI.textSecondary(isDark))),
          const SizedBox(height: 10),
          _ModeSelector(
            isDark: isDark,
            mode: mode,
            onChanged: (m) {
              setState(() {
                mode = m;
                if (m == ComplaintReplyMode.manual) textCtrl.clear();
                if (m == ComplaintReplyMode.ai) _applyAiReply();
              });
            },
          ),
          const SizedBox(height: 18),

          if (mode == ComplaintReplyMode.template) ...[
            Text('Step 2 — Choose a Template', style: AppTextStyles.labelLarge.copyWith(color: ComplaintUI.textSecondary(isDark))),
            const SizedBox(height: 10),
            _TemplateDropdown(isDark: isDark, selected: selectedTemplate, onSelect: _applyTemplate),
            const SizedBox(height: 16),
          ],

          if (mode == ComplaintReplyMode.ai) ...[
            Row(children: [
              Text('AI Suggested Reply', style: AppTextStyles.labelLarge.copyWith(color: ComplaintUI.textSecondary(isDark))),
              const Spacer(),
              TextButton.icon(
                onPressed: _applyAiReply,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Regenerate'),
              ),
            ]),
            const SizedBox(height: 6),
          ],

          // ── Response Editor ──────────────────────────────────────────
          _EditorToolbar(isDark: isDark),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: ComplaintUI.surface2(isDark),
              borderRadius: AppRadius.medium,
              border: Border.all(color: ComplaintUI.border(isDark)),
            ),
            child: TextField(
              controller: textCtrl,
              maxLines: 6,
              enabled: mode != ComplaintReplyMode.template || selectedTemplate != null,
              style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textPrimary(isDark)),
              decoration: InputDecoration(
                hintText: mode == ComplaintReplyMode.template && selectedTemplate == null
                    ? 'Select a template above to load a reply…'
                    : 'Write a response...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(onPressed: () {}, icon: Icon(Icons.emoji_emotions_outlined, color: ComplaintUI.textSecondary(isDark)), tooltip: 'Emoji'),
                IconButton(onPressed: () {}, icon: Icon(Icons.attach_file_rounded, color: ComplaintUI.textSecondary(isDark)), tooltip: 'Attachment'),
              ]),
              Text('${textCtrl.text.length} characters', style: AppTextStyles.caption.copyWith(color: ComplaintUI.textHint(isDark))),
            ],
          ),
          const SizedBox(height: 16),

          // ── Meta dropdowns ───────────────────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetaDropdown(isDark: isDark, label: 'Estimated Resolution', value: eta, options: etaOptions,
                  onChanged: (v) => setState(() => eta = v)),
              _MetaDropdown(isDark: isDark, label: 'Priority', value: priority, options: priorityOptions,
                  onChanged: (v) => setState(() => priority = v)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Internal notes ───────────────────────────────────────────
          Text('Internal Notes (Admin Only)', style: AppTextStyles.labelSmall.copyWith(color: ComplaintUI.textSecondary(isDark))),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.warningSoftDark : AppColors.warningSoft,
              borderRadius: AppRadius.medium,
              border: Border.all(color: AppColors.warning.withValues(alpha: .35)),
            ),
            child: TextField(
              controller: noteCtrl,
              maxLines: 2,
              style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textPrimary(isDark)),
              decoration: const InputDecoration(
                hintText: 'Visible to admins only — never shown to the customer…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Customer visible toggle ──────────────────────────────────
          // ✅ FIXED: thumb was the same teal as the active track, making it
          // invisible ("teal on teal"). Thumb is now white when ON (with a
          // teal track) and a neutral grey when OFF, so the switch state is
          // always legible.
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: ComplaintUI.textSecondary(isDark)),
              const SizedBox(width: 8),
              Expanded(child: Text('Customer Visible', style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textPrimary(isDark)))),
              Switch(
                value: customerVisible,
                activeThumbColor: Colors.white,
                activeTrackColor: ComplaintUI.accent(isDark),
                inactiveThumbColor: isDark ? Colors.grey.shade400 : Colors.grey.shade100,
                inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                onChanged: (v) => setState(() => customerVisible = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ FIXED: both buttons now share the same explicit height (48)
          // and matching vertical padding, so "Save Note" and "Send
          // Response" line up exactly instead of one looking taller.
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                    ),
                    onPressed: () {
                      if (noteCtrl.text.trim().isNotEmpty) {
                        ctrl.addInternalNote(widget.complaintId, noteCtrl.text);
                        noteCtrl.clear();
                      }
                    },
                    icon: const Icon(Icons.push_pin_outlined, size: 18),
                    label: const Text('Save Note'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ComplaintUI.accent(isDark),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                    ),
                    onPressed: () {
                      ctrl.updatePriority(widget.complaintId, priority);
                      ctrl.setEstimatedResolution(widget.complaintId, eta);
                      ctrl.sendReply(
                        complaintId: widget.complaintId,
                        replyMessage: textCtrl.text,
                        currentStatus: widget.currentStatus,
                        customerVisible: customerVisible,
                      );
                      textCtrl.clear();
                      setState(() => selectedTemplate = null);
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Response'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final bool isDark;
  final ComplaintReplyMode mode;
  final ValueChanged<ComplaintReplyMode> onChanged;
  const _ModeSelector({required this.isDark, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (ComplaintReplyMode.manual, 'Manual Reply', Icons.edit_note_rounded),
      (ComplaintReplyMode.template, 'Smart Template', Icons.dashboard_customize_rounded),
      (ComplaintReplyMode.ai, 'AI Suggested Reply', Icons.auto_awesome_rounded),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final selected = mode == o.$1;
        return InkWell(
          borderRadius: AppRadius.full,
          onTap: () => onChanged(o.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? ComplaintUI.accent(isDark) : ComplaintUI.surface2(isDark),
              borderRadius: AppRadius.full,
              border: Border.all(color: selected ? Colors.transparent : ComplaintUI.border(isDark)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16, color: selected ? Colors.white : ComplaintUI.textSecondary(isDark)),
              const SizedBox(width: 6),
              Icon(o.$3, size: 16, color: selected ? Colors.white : ComplaintUI.textSecondary(isDark)),
              const SizedBox(width: 6),
              Text(o.$2,
                  style: AppTextStyles.labelSmall.copyWith(color: selected ? Colors.white : ComplaintUI.textSecondary(isDark))),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

class _TemplateDropdown extends StatelessWidget {
  final bool isDark;
  final String? selected;
  final ValueChanged<String> onSelect;
  const _TemplateDropdown({required this.isDark, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ComplaintUI.surface2(isDark),
        borderRadius: AppRadius.medium,
        border: Border.all(color: ComplaintUI.border(isDark)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text('Select a template', style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textHint(isDark))),
          value: selected,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: ComplaintUI.textSecondary(isDark)),
          dropdownColor: ComplaintUI.surface(isDark),
          items: AdminComplaintController.smartTemplates.keys
              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTextStyles.bodyMedium.copyWith(color: ComplaintUI.textPrimary(isDark)))))
              .toList(),
          onChanged: (v) { if (v != null) onSelect(v); },
        ),
      ),
    );
  }
}

class _MetaDropdown extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _MetaDropdown({
    required this.isDark, required this.label, required this.value,
    required this.options, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: ComplaintUI.textSecondary(isDark))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ComplaintUI.surface2(isDark),
              borderRadius: AppRadius.medium,
              border: Border.all(color: ComplaintUI.border(isDark)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: ComplaintUI.textSecondary(isDark)),
                dropdownColor: ComplaintUI.surface(isDark),
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o, style: AppTextStyles.bodySmall.copyWith(color: ComplaintUI.textPrimary(isDark)))))
                    .toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final bool isDark;
  const _EditorToolbar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Visual affordance for a rich-text toolbar. Wire to flutter_quill (or
    // similar) if/when a rich-text package is added to the project.
    final icons = [Icons.format_bold_rounded, Icons.format_italic_rounded, Icons.format_underline_rounded,
        Icons.format_list_bulleted_rounded, Icons.link_rounded];
    return Row(
      children: icons
          .map((i) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(i, size: 17, color: ComplaintUI.textSecondary(isDark)),
                  visualDensity: VisualDensity.compact,
                ),
              ))
          .toList(),
    );
  }
}

// ─── ACTION BUTTONS ───────────────────────────────────────────────────────

class ComplaintActionButtons extends StatelessWidget {
  final bool isDark;
  final String complaintId;
  final String status;
  const ComplaintActionButtons({super.key, required this.isDark, required this.complaintId, required this.status});

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminComplaintController.to;

    Future<void> run({
      required String title,
      required String message,
      required VoidCallback action,
      bool danger = false,
      String confirmLabel = 'Confirm',
    }) async {
      final ok = await confirmComplaintAction(context, isDark: isDark, title: title, message: message, danger: danger, confirmLabel: confirmLabel);
      if (ok) action();
    }

    return ComplaintSectionCard(
      isDark: isDark,
      title: 'Actions',
      icon: Icons.bolt_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          if (status == 'pending')
            _ActionBtn(
              isDark: isDark, icon: Icons.play_circle_outline_rounded, label: 'Mark In Progress',
              onTap: () => run(
                title: 'Mark In Progress',
                message: 'This will move the complaint into active review. Continue?',
                action: () => ctrl.markInProgress(complaintId),
              ),
            ),
          if (status != 'resolved' && status != 'closed')
            _ActionBtn(
              isDark: isDark, icon: Icons.check_circle_outline_rounded, label: 'Resolve Complaint', filled: true,
              onTap: () => run(
                title: 'Resolve Complaint',
                message: 'Make sure a response has been sent before resolving. Continue?',
                confirmLabel: 'Resolve',
                action: () {
                  // Uses whatever adminReply already exists; the Smart Reply
                  // panel above is the primary way to attach a message.
                  ctrl.markInProgress(complaintId);
                },
              ),
            ),
          if (status != 'closed')
            _ActionBtn(
              isDark: isDark, icon: Icons.lock_outline_rounded, label: 'Close Complaint',
              onTap: () => run(
                title: 'Close Complaint',
                message: 'Closing will stop further updates on this ticket. Continue?',
                confirmLabel: 'Close',
                action: () => ctrl.closeComplaint(complaintId),
              ),
            ),
          if (status == 'resolved' || status == 'closed')
            _ActionBtn(
              isDark: isDark, icon: Icons.refresh_rounded, label: 'Reopen',
              onTap: () => run(
                title: 'Reopen Complaint',
                message: 'This will reset the status back to pending. Continue?',
                confirmLabel: 'Reopen',
                action: () => ctrl.reopenComplaint(complaintId),
              ),
            ),
          _ActionBtn(
            isDark: isDark, icon: Icons.delete_outline_rounded, label: 'Delete', danger: true,
            onTap: () => run(
              title: 'Delete Complaint',
              message: 'This action is permanent and cannot be undone. Continue?',
              confirmLabel: 'Delete',
              danger: true,
              action: () => ctrl.deleteComplaint(complaintId),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final bool isDark, danger, filled;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.isDark, required this.icon, required this.label, required this.onTap,
    this.danger = false, this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : ComplaintUI.accent(isDark);
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color, width: 1.4)),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}