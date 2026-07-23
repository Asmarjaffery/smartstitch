import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smartstitch/admin/users/admin_user_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminUserController>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: Column(
        children: [
          // ── Search ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: controller.setSearch,
              decoration: const InputDecoration(
                hintText: 'Search user...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: AppColors.lightSurface,
              ),
            ),
          ),

          // ── Role Filter ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.selectedRole.value,
                decoration: const InputDecoration(labelText: 'Filter Role'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'artist', child: Text('Artist')),
                  DropdownMenuItem(value: 'rider', child: Text('Rider')),
                ],
                onChanged: (value) => controller.setRole(value ?? 'all'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── User List ──────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.filteredUsers.isEmpty) {
                return const Center(
                  child: Text('No Users Found', style: AppTextStyles.bodyLarge),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredUsers.length,
                itemBuilder: (_, index) {
                  final user = controller.filteredUsers[index];
                  final data = user.data() as Map<String, dynamic>;
                  final userId = user.id;
                  final name = data['name'] ?? 'Unknown User';
                  final email = data['email'] ?? '';
                  final role = data['role'] ?? 'customer';
                  final isBlocked = data['isBlocked'] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: isBlocked
                            ? AppColors.error.withValues(alpha: 0.3)
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _showUserDetailSheet(
                          context, data, userId, controller),
                      leading: CircleAvatar(
                        backgroundColor: isBlocked
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.primarySoft,
                        child: Text(
                          name[0].toUpperCase(),
                          style: TextStyle(
                            color:
                                isBlocked ? AppColors.error : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isBlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: AppRadius.full,
                              ),
                              child: Text(
                                'Blocked',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(email,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.lightTextSecondary)),
                          const SizedBox(height: 4),
                          _RoleBadge(role: role),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.medium),
                        onSelected: (value) {
                          switch (value) {
                            case 'view':
                              _showUserDetailSheet(
                                  context, data, userId, controller);
                              break;
                            case 'block':
                              controller.toggleBlockUser(userId, isBlocked);
                              break;
                            case 'delete':
                              controller.deleteUser(userId, name);
                              break;
                            case 'customer':
                            case 'artist':
                            case 'rider':
                              controller.updateUserRole(userId, value);
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(children: [
                              Icon(Icons.visibility_rounded,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('View Details'),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'block',
                            child: Row(children: [
                              Icon(
                                isBlocked
                                    ? Icons.lock_open_rounded
                                    : Icons.block_rounded,
                                size: 16,
                                color: isBlocked
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 10),
                              Text(isBlocked ? 'Unblock User' : 'Block User'),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'customer',
                            child: Row(children: [
                              Icon(Icons.person_rounded,
                                  size: 16, color: AppColors.success),
                              SizedBox(width: 10),
                              Text('Make Customer'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'artist',
                            child: Row(children: [
                              Icon(Icons.content_cut_rounded,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 10),
                              Text('Make Artist'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'rider',
                            child: Row(children: [
                              Icon(Icons.delivery_dining_rounded,
                                  size: 16, color: AppColors.info),
                              SizedBox(width: 10),
                              Text('Make Rider'),
                            ]),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_rounded,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete User',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  VIEW DETAIL BOTTOM SHEET
  // ══════════════════════════════════════════════════════════
  void _showUserDetailSheet(
    BuildContext context,
    Map<String, dynamic> data,
    String userId,
    AdminUserController controller,
  ) {
    final isBlocked = data['isBlocked'] ?? false;
    final role = data['role'] ?? 'customer';
    final name = data['name'] ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar + Name + Role
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.lightTextPrimary)),
                const SizedBox(height: 6),
                Row(children: [
                  _RoleBadge(role: role),
                  if (isBlocked) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: AppRadius.full,
                      ),
                      child: Text('Blocked',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ]),
              ]),
            ]),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Details
            _DetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: data['email'] ?? '-',
            ),
            _DetailRow(
              icon: Icons.phone_rounded,
              label: 'Phone',
              value: data['phone'] ?? '-',
            ),
            _DetailRow(
              icon: Icons.shield_rounded,
              label: 'Status',
              value: isBlocked ? 'Blocked' : 'Active',
              valueColor: isBlocked ? AppColors.error : AppColors.success,
            ),
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Joined',
              value: _formatDate(data['createdAt']),
            ),
            

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),

            // Change Role Section
            Text('Change Role',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.lightTextSecondary)),
            const SizedBox(height: 10),
            Row(children: [
              _RoleButton(
                label: 'Customer',
                icon: Icons.person_rounded,
                color: AppColors.success,
                isActive: role == 'customer',
                onTap: () {
                  controller.updateUserRole(userId, 'customer');
                  Get.back();
                },
              ),
              const SizedBox(width: 8),
              _RoleButton(
                label: 'Artist',
                icon: Icons.content_cut_rounded,
                color: AppColors.primary,
                isActive: role == 'artist',
                onTap: () {
                  controller.updateUserRole(userId, 'artist');
                  Get.back();
                },
              ),
              const SizedBox(width: 8),
              _RoleButton(
                label: 'Rider',
                icon: Icons.delivery_dining_rounded,
                color: AppColors.info,
                isActive: role == 'rider',
                onTap: () {
                  controller.updateUserRole(userId, 'rider');
                  Get.back();
                },
              ),
            ]),

            const SizedBox(height: 16),

            // Block / Delete Buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.toggleBlockUser(userId, isBlocked);
                  },
                  icon: Icon(
                    isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                    size: 16,
                  ),
                  label: Text(isBlocked ? 'Unblock' : 'Block'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isBlocked ? AppColors.success : AppColors.warning,
                    side: BorderSide(
                        color:
                            isBlocked ? AppColors.success : AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    controller.deleteUser(userId, name);
                  },
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      if (value is Timestamp) {
        return value.toDate().toString().split(' ')[0];
      }
      if (value is String) {
        return value.split('T')[0];
      }
    } catch (_) {}
    return '-';
  }

// ══════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  Color get _color {
    switch (role) {
      case 'artist':
        return AppColors.primary;
      case 'rider':
        return AppColors.info;
      case 'admin':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  IconData get _icon {
    switch (role) {
      case 'artist':
        return Icons.content_cut_rounded;
      case 'rider':
        return Icons.delivery_dining_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: AppRadius.full,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(role, style: AppTextStyles.caption.copyWith(color: _color)),
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.lightTextHint),
          const SizedBox(width: 10),
          Text('$label: ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.lightTextSecondary)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: valueColor ?? AppColors.lightTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      );
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : AppColors.lightBackground,
              borderRadius: AppRadius.medium,
              border: Border.all(
                color: isActive ? color : AppColors.lightBorder,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 18,
                    color: isActive ? color : AppColors.lightTextHint),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? color : AppColors.lightTextHint,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
