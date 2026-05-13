import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitsmart/app_routes.dart';
import 'package:fitsmart/cloudinary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class SignUpScreen extends StatefulWidget {
  final String? prefillName;
  final String? prefillEmail;

  const SignUpScreen({super.key, this.prefillName, this.prefillEmail});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  final TextEditingController _phoneController = TextEditingController();
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _photoUrl;
  bool get _isPrefilled => widget.prefillEmail != null;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
    _emailController = TextEditingController(text: widget.prefillEmail ?? '');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  Future<void> _createAccount() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showSnackBar('Please fill in all required fields.');
      return;
    }

    if (!_isPrefilled) {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _showSnackBar('Please fill in all required fields.');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match.');
        return;
      }
    }

    try {
      User? user;
      if (!_isPrefilled) {
        UserCredential credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        user = credential.user;
      } else {
        user = FirebaseAuth.instance.currentUser;
      }

      if (user == null) {
        _showSnackBar('An error occurred during account creation.');
        return;
      }

      await user.updateDisplayName(_nameController.text.trim());
      if (!_isPrefilled && _photoUrl != null) {
        await user.updatePhotoURL(_photoUrl);
      }

      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _isPrefilled ? widget.prefillEmail : _emailController.text.trim(),
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Account created successfully! Welcome!');
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'Auth Error');
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: Column(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Client Registration',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome! Please create a new account.',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CustomImagePicker(
                            currentImageUrl: _isPrefilled
                                ? FirebaseAuth.instance.currentUser?.photoURL
                                : null,
                            onImageUploaded: (url) => _photoUrl = url,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel(theme, colorScheme, 'Name'),
                        _buildField(_nameController, 'Enter your name', colorScheme),
                        const SizedBox(height: 16),
                        _buildLabel(theme, colorScheme, 'Phone Number'),
                        _buildField(_phoneController, 'Enter phone number', colorScheme, type: TextInputType.phone),
                        if (!_isPrefilled) ...[
                          const SizedBox(height: 16),
                          _buildLabel(theme, colorScheme, 'Email Address'),
                          _buildField(_emailController, 'Enter email address', colorScheme, type: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildLabel(theme, colorScheme, 'Password'),
                          _buildField(_passwordController, 'Enter password', colorScheme, 
                            obscure: _obscurePassword,
                            suffix: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildLabel(theme, colorScheme, 'Confirm Password'),
                          _buildField(_confirmPasswordController, 'Re-enter password', colorScheme, 
                            obscure: _obscureConfirmPassword,
                            suffix: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildSubmitButton(colorScheme, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLoginLink(theme, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, ColorScheme colorScheme, String label) {
    return Text(
      label,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, ColorScheme colorScheme, {bool obscure = false, TextInputType? type, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          hintText: hint,
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.outlineVariant)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: Text(_isPrefilled ? 'Complete Profile' : 'Create Account', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme, ColorScheme colorScheme) {
    return TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
      child: Text.rich(
        TextSpan(
          text: 'Already have an account? ',
          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          children: [
            TextSpan(
              text: 'Login',
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final double imageSize;
  final void Function(String photoUrl) onImageUploaded;

  const CustomImagePicker({
    super.key,
    this.currentImageUrl,
    this.imageSize = 80,
    required this.onImageUploaded,
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _isPickerActive = false;

  Future<void> _pickImage() async {
    if (_isPickerActive) return;

    setState(() => _isPickerActive = true);

    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _pickedImage = picked);
        await _uploadToCloudinary();
      }
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_pickedImage == null) return;
    setState(() => _isLoading = true);

    try {
      final bytes = await File(_pickedImage!.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final resized = img.copyResize(decoded, width: 500);
      final tempFile = File('${Directory.systemTemp.path}/avatar.jpg')
        ..writeAsBytesSync(img.encodeJpg(resized, quality: 85));

      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: tempFile.path,
          resourceType: CloudinaryResourceType.image,
        ),
      );

      if (response.isSuccessful) {
        _uploadedImageUrl = response.secureUrl;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await user.updatePhotoURL(_uploadedImageUrl);
        widget.onImageUploaded(_uploadedImageUrl!);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _isLoading || _isPickerActive ? null : _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: widget.imageSize,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: _pickedImage != null
                ? FileImage(File(_pickedImage!.path))
                : (_uploadedImageUrl != null || (widget.currentImageUrl?.isNotEmpty ?? false))
                    ? NetworkImage(_uploadedImageUrl ?? widget.currentImageUrl!)
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          if (!_isLoading)
            Positioned(
              bottom: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}