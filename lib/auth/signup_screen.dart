import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartstitch/controllers/auth_controller.dart';
import 'package:smartstitch/core/theme/app.theme.dart';
import 'package:smartstitch/core/utils/validators.dart';
import 'package:smartstitch/core/widgets/app_logo.dart';
import 'package:smartstitch/routes/routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Common fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Artist fields
  final _businessNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cnicController = TextEditingController();
  final List<String> _selectedSpecializations = [];
  final _shopAddressController = TextEditingController();
  final _shopCityController = TextEditingController();
  final _shopProvinceController = TextEditingController();

  // Rider fields
  final _riderCnicController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // Animation controllers
  late AnimationController _headerCtrl;
  late AnimationController _formCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _headerSlide;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    AuthController.to.fetchSpecializations();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _formCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _headerCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () => _formCtrl.forward());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerCtrl.dispose();
    _formCtrl.dispose();
    _pulseCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _bioController.dispose();
    _cnicController.dispose();
    _shopAddressController.dispose();
    _shopCityController.dispose();
    _shopProvinceController.dispose();
    _riderCnicController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() {
      _selectedImage = image;
      _selectedImageBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  void _signup() {
    if (!_formKey.currentState!.validate()) return;

    if (_tabController.index == 0) {
      AuthController.to.signupCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        profileImage: _selectedImage,
      );
    } else if (_tabController.index == 1) {
      if (_selectedSpecializations.isEmpty) {
        Get.snackbar('Missing Specializations', 'Please select at least one specialization',
          backgroundColor: AppColors.primary, colorText: Colors.white,
          borderRadius: 12, margin: const EdgeInsets.all(16), snackPosition: SnackPosition.TOP);
        return;
      }
      AuthController.to.signupArtist(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        businessName: _businessNameController.text.trim(),
        bio: _bioController.text.trim(),
        cnicNumber: _cnicController.text.trim(),
        specializations: _selectedSpecializations,
        shopAddress: _shopAddressController.text.trim(),
        shopCity: _shopCityController.text.trim(),
        shopProvince: _shopProvinceController.text.trim(),
        profileImage: _selectedImage,
      );
    } else {
      AuthController.to.signupRider(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        cnicNumber: _riderCnicController.text.trim(),
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleNumber: _vehicleNumberController.text.trim(),
        profileImage: _selectedImage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fillColor = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;
    final primarySoft = isDark ? AppColors.darkSurface2 : AppColors.primarySoft;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -70,
            child: _BlurBlob(color: isDark ? AppColors.primary.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.08), size: 280),
          ),
          Positioned(
            top: 160,
            left: -80,
            child: _BlurBlob(color: isDark ? AppColors.primaryDark.withValues(alpha: 0.03) : AppColors.primaryDark.withValues(alpha: 0.05), size: 200),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ✅ BACK BUTTON
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.customerHome),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: AppRadius.medium,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Header ───────────────────────────────────────────
                  SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        child: Column(
                          children: [
                            ScaleTransition(
                              scale: _logoScale,
                              child: AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (_, child) => ScaleTransition(scale: _pulse, child: child),
                                child: AppLogo(size: 90, isDark: isDark),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Create Account',
                              style: AppTextStyles.h1.copyWith(color: textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Join SmartStitch today',
                              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Form ─────────────────────────────────────────────
                  SlideTransition(
                    position: _formSlide,
                    child: FadeTransition(
                      opacity: _formFade,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Custom Toggle Tab ──────────────────
                              Container(
                                height: 52,
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: AppRadius.medium,
                                  boxShadow: AppShadows.soft(AppColors.primary),
                                ),
                                child: Row(
                                  children: [
                                    _TabToggleButton(
                                      label: 'Customer',
                                      icon: Icons.person_outline_rounded,
                                      isSelected: _tabController.index == 0,
                                      isDark: isDark,
                                      onTap: () {
                                        _tabController.animateTo(0);
                                        setState(() {});
                                      },
                                    ),
                                    _TabToggleButton(
                                      label: 'Artist',
                                      icon: Icons.content_cut_rounded,
                                      isSelected: _tabController.index == 1,
                                      isDark: isDark,
                                      onTap: () {
                                        _tabController.animateTo(1);
                                        setState(() {});
                                      },
                                    ),
                                    _TabToggleButton(
                                      label: 'Rider',
                                      icon: Icons.delivery_dining_rounded,
                                      isSelected: _tabController.index == 2,
                                      isDark: isDark,
                                      onTap: () {
                                        _tabController.animateTo(2);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Form Card ─────────────────────────
                              Container(
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: AppRadius.large,
                                  boxShadow: AppShadows.soft(AppColors.primary),
                                ),
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Text(
                                        _tabController.index == 0
                                            ? 'Personal Information'
                                            : _tabController.index == 1
                                                ? 'Artist Details'
                                                : 'Rider Details',
                                        key: ValueKey(_tabController.index),
                                        style: AppTextStyles.h5.copyWith(color: textPrimary),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fill in your details to get started',
                                      style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                                    ),
                                    const SizedBox(height: 20),

                                    // ── Profile Image Picker (optional) ────
                                    Center(
                                      child: Column(
                                        children: [
                                          GestureDetector(
                                            onTap: _pickImage,
                                            child: Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 45,
                                                  backgroundColor: primarySoft,
                                                  backgroundImage: _selectedImageBytes != null
                                                      ? MemoryImage(_selectedImageBytes!)
                                                      : null,
                                                  child: _selectedImageBytes == null
                                                      ? Icon(
                                                          Icons.person_outline_rounded,
                                                          size: 42,
                                                          color: AppColors.primary,
                                                        )
                                                      : null,
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(color: surfaceColor, width: 2),
                                                    ),
                                                    child: const Icon(
                                                      Icons.camera_alt_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _selectedImageBytes == null
                                                    ? 'Add profile photo (optional)'
                                                    : 'Photo selected',
                                                style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
                                              ),
                                              if (_selectedImageBytes != null) ...[
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: _removeImage,
                                                  child: Text(
                                                    'Remove',
                                                    style: AppTextStyles.bodySmall.copyWith(
                                                      color: AppColors.error,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (_selectedImageBytes == null)
                                            Text(
                                              "Skip? We'll use a default avatar for you",
                                              style: AppTextStyles.bodySmall.copyWith(color: textHint),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Common fields
                                    _SignupField(
                                      controller: _nameController,
                                      hint: 'Full Name',
                                      icon: Icons.person_outline_rounded,
                                      validator: AppValidators.validateName,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 14),
                                    _SignupField(
                                      controller: _emailController,
                                      hint: 'Email Address',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: AppValidators.validateEmail,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 14),
                                    _SignupField(
                                      controller: _phoneController,
                                      hint: 'Phone (03XXXXXXXXX)',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: AppValidators.validatePhone,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 14),
                                    _SignupField(
                                      controller: _passwordController,
                                      hint: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      validator: AppValidators.validatePassword,
                                      suffixIcon: GestureDetector(
                                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                        child: Icon(
                                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: textHint,
                                          size: 20,
                                        ),
                                      ),
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 14),
                                    _SignupField(
                                      controller: _confirmPasswordController,
                                      hint: 'Confirm Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscureConfirm,
                                      validator: (v) => AppValidators.validateConfirmPassword(v, _passwordController.text),
                                      suffixIcon: GestureDetector(
                                        onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                        child: Icon(
                                          _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: textHint,
                                          size: 20,
                                        ),
                                      ),
                                      isDark: isDark,
                                    ),

                                    // ── Role-specific fields ────
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeInOutCubic,
                                      child: _tabController.index == 1
                                          ? _buildArtistFields(isDark)
                                          : _tabController.index == 2
                                              ? _buildRiderFields(isDark)
                                              : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Create Account Button ─────────────
                              Obx(() => _PrimaryButton(
                                label: 'Create Account',
                                onPressed: _signup,
                                isLoading: AuthController.to.isLoading.value,
                                isDark: isDark,
                              )),

                              const SizedBox(height: 20),

                              // ── Login Link ────────────────────────
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
                                    ),
                                    GestureDetector(
                                      onTap: () => Get.back(),
                                      child: Text(
                                        'Sign In',
                                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistFields(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        _SignupField(controller: _businessNameController, hint: 'Business/Shop Name', icon: Icons.store_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Business name is required' : null, isDark: isDark),
        const SizedBox(height: 14),
        _SignupField(controller: _bioController, hint: 'Brief Bio', icon: Icons.description_outlined, maxLines: 3, validator: (v) => v == null || v.trim().isEmpty ? 'Bio is required' : null, isDark: isDark),
        const SizedBox(height: 14),
        _SignupField(controller: _cnicController, hint: 'CNIC Number (XXXXX-XXXXXXX-X)', icon: Icons.badge_outlined, keyboardType: TextInputType.number, validator: (v) => v == null || v.trim().isEmpty ? 'CNIC is required' : null, isDark: isDark),

        const SizedBox(height: 22),
        Row(children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text('Shop Address', style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
        ]),
        const SizedBox(height: 6),
        Text('Where customers can find or drop off items', style: AppTextStyles.bodySmall.copyWith(color: textSecondary)),
        const SizedBox(height: 14),
        _SignupField(controller: _shopAddressController, hint: 'Shop Address (Street, Area)', icon: Icons.location_on_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Shop address is required' : null, isDark: isDark),
        const SizedBox(height: 14),
        _SignupField(controller: _shopCityController, hint: 'City', icon: Icons.location_city_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null, isDark: isDark),
        const SizedBox(height: 14),
        _SignupField(controller: _shopProvinceController, hint: 'Province', icon: Icons.map_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Province is required' : null, isDark: isDark),

        const SizedBox(height: 22),
        Row(children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text('Specializations', style: AppTextStyles.labelLarge.copyWith(color: textPrimary)),
        ]),
        const SizedBox(height: 6),
        Text('Select all that apply', style: AppTextStyles.bodySmall.copyWith(color: textSecondary)),
        const SizedBox(height: 14),

        Obx(() {
          if (AuthController.to.isLoadingSpecs.value) {
            return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)));
          }
          if (AuthController.to.specializations.isEmpty) {
            return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No specializations available', style: AppTextStyles.bodySmall.copyWith(color: textSecondary)));
          }
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AuthController.to.specializations.map((spec) {
              final isSelected = _selectedSpecializations.contains(spec);
              return _SpecializationChip(label: spec, isSelected: isSelected, onTap: () => setState(() { isSelected ? _selectedSpecializations.remove(spec) : _selectedSpecializations.add(spec); }));
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildRiderFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        _SignupField(controller: _riderCnicController, hint: 'CNIC Number (XXXXX-XXXXXXX-X)', icon: Icons.badge_outlined, keyboardType: TextInputType.number, validator: (v) => v == null || v.trim().isEmpty ? 'CNIC is required' : null, isDark: isDark),
        const SizedBox(height: 14),
        _SignupField(controller: _vehicleTypeController, hint: 'Vehicle Type (e.g., Bike, Car)', icon: Icons.two_wheeler_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Vehicle type is required' : null, isDark: isDark),
        const SizedBox(height: 14),
        _SignupField(controller: _vehicleNumberController, hint: 'Vehicle Registration Number', icon: Icons.confirmation_number_outlined, validator: (v) => v == null || v.trim().isEmpty ? 'Vehicle number is required' : null, isDark: isDark),
      ],
    );
  }
}

// ─── WIDGETS ──────────────────────────────────────────────────────────────────────────────────

class _SpecializationChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecializationChip({required this.label, required this.isSelected, required this.onTap});

  @override
  State<_SpecializationChip> createState() => _SpecializationChipState();
}

class _SpecializationChipState extends State<_SpecializationChip> with SingleTickerProviderStateMixin {
  late AnimationController _chipCtrl;
  late Animation<double> _chipScale;

  @override
  void initState() {
    super.initState();
    _chipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _chipScale = Tween<double>(begin: 1.0, end: 0.94).animate(_chipCtrl);
  }

  @override
  void dispose() {
    _chipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface2 : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTapDown: (_) => _chipCtrl.forward(),
      onTapUp: (_) { _chipCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _chipCtrl.reverse(),
      child: ScaleTransition(
        scale: _chipScale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.primary : bgColor,
            borderRadius: AppRadius.full,
            border: Border.all(color: widget.isSelected ? AppColors.primary : borderColor, width: 1.5),
            boxShadow: widget.isSelected ? AppShadows.soft(AppColors.primary) : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: AppTextStyles.labelMedium.copyWith(color: widget.isSelected ? Colors.white : textColor)),
              if (widget.isSelected) ...[const SizedBox(width: 5), const Icon(Icons.check_rounded, color: Colors.white, size: 14)],
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int maxLines;
  final bool isDark;

  const _SignupField({
    required this.controller, required this.hint, required this.icon, this.keyboardType,
    this.obscureText = false, this.validator, this.suffixIcon, this.maxLines = 1, required this.isDark,
  });

  @override
  State<_SignupField> createState() => _SignupFieldState();
}

class _SignupFieldState extends State<_SignupField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textHint = widget.isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final borderColor = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fillColor = widget.isDark ? AppColors.darkSurface2 : AppColors.lightBackground;
    final primarySoft = widget.isDark ? AppColors.darkSurface2 : AppColors.primarySoft;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        boxShadow: _focused ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 12, offset: const Offset(0, 4))] : [],
      ),
      child: Focus(
        onFocusChange: (v) => setState(() => _focused = v),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          validator: widget.validator,
          maxLines: widget.maxLines,
          style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: textHint),
            prefixIcon: Icon(widget.icon, color: textHint, size: 20),
            suffixIcon: widget.suffixIcon != null ? Padding(padding: const EdgeInsets.only(right: 4), child: widget.suffixIcon) : null,
            filled: true,
            fillColor: _focused ? primarySoft : fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: borderColor, width: 1.2)),
            enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: borderColor, width: 1.2)),
            focusedBorder: const OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
            errorBorder: const OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: AppColors.error, width: 1.2)),
            focusedErrorBorder: const OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide(color: AppColors.error, width: 1.8)),
          ),
        ),
      ),
    );
  }
}

class _TabToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TabToggleButton({required this.label, required this.icon, required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? AppShadows.soft(AppColors.primary) : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : textHint),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.labelMedium.copyWith(color: isSelected ? Colors.white : textHint)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDark;

  const _PrimaryButton({required this.label, required this.onPressed, this.isLoading = false, required this.isDark});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); if (!widget.isLoading) widget.onPressed(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.medium,
            boxShadow: AppShadows.primary,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(widget.label, style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}