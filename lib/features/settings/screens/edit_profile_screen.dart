import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palmpay/l10n/app_localizations.dart';
import 'package:palmpay/services/api_service.dart';
import 'package:palmpay/utils/constants/image_text.dart';
import 'package:palmpay/utils/themes/text_theme.dart';

import 'package:palmpay/features/settings/providers/profile_refresh_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isUploading = false;

  String? _remoteImageUrl;
  File? _localImageFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService.getUserDetails(),
        ApiService.getProfileImage()
            .then<Map<String, dynamic>?>((v) => v)
            .catchError((_) => null),
      ]);

      final user = results[0] as dynamic;
      final imageRes = results[1];

      String? imageUrl;
      if (imageRes is Map<String, dynamic>) {
        final v = imageRes['image_url'] ?? imageRes['imageUrl'];
        if (v is String && v.trim().isNotEmpty) {
          imageUrl = ApiService.normalizePublicImageUrl(v);
        }
      }

      if (!mounted) return;
      setState(() {
        _nameController.text = user.fullname;
        _phoneController.text = user.phone;
        _remoteImageUrl = imageUrl;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    final fullname = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullname.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('required')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ApiService.updateProfile(fullname: fullname, phone: phone);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ref.read(profileRefreshProvider.notifier).state++;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('profile_updated_successfully')),
          backgroundColor: const Color(0xFF238EC2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _localImageFile = File(picked.path);
    });
  }

  Future<void> _uploadImage() async {
    final l10n = AppLocalizations.of(context);
    final file = _localImageFile;
    if (file == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final res = await ApiService.uploadProfileImage(imageFile: file);
      final v = res['image_url'] ?? res['imageUrl'];

      if (!mounted) return;
      setState(() {
        _remoteImageUrl = (v is String && v.trim().isNotEmpty)
            ? ApiService.normalizePublicImageUrl(v)
            : _remoteImageUrl;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('profile_image_updated')),
          backgroundColor: const Color(0xFF00AA44),
        ),
      );

      ref.read(profileRefreshProvider.notifier).state++;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider _avatarImage() {
    if (_localImageFile != null) {
      return FileImage(_localImageFile!);
    }
    final url = _remoteImageUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return const AssetImage(AImageText.palmPayLogo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: SizedBox(
            width: 17,
            height: 15,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                Icons.arrow_back,
                color: const Color(0xFF333333),
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
        title: Text(
          l10n.t('edit_profile'),
          style: ATextTheme.textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            image: DecorationImage(
                              image: _avatarImage(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          bottom: -4,
                          end: -4,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _isUploading ? null : _pickImage,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: (_localImageFile == null || _isUploading)
                          ? null
                          : _uploadImage,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload, size: 18),
                      label: Text(
                        _isUploading
                            ? l10n.t('uploading')
                            : l10n.t('upload_profile_photo'),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF333333),
                        side: const BorderSide(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    label: l10n.t('full_name'),
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  _Field(
                    label: l10n.t('phone_number'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text(l10n.t('save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 20 / 14,
            letterSpacing: -0.5,
            color: const Color(0xFF333333),
          ),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsetsDirectional.fromSTEB(
              16,
              14,
              16,
              14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF238EC2), width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
