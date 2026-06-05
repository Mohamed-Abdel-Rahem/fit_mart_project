// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:fitsmart/cloudinary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

class CustomImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final double? imageSize;
  final void Function(String photoUrl) onImageUploaded;

  const CustomImagePicker({
    super.key,
    this.currentImageUrl,
    this.imageSize,
    required this.onImageUploaded,
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker>
    with SingleTickerProviderStateMixin {
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;
    try {
      _animationController.forward().then(
        (_) => _animationController.reverse(),
      );
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _pickedImage = pickedImage;
          _errorMessage = null;
        });
        await _uploadImageToCloudinary();
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error picking image: $error';
      });
    }
  }

  Future<File> _resizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image.');
    }

    final resizedImage = img.copyResize(originalImage, width: 600);
    final tempDir = Directory.systemTemp;
    final resizedFile = File('${tempDir.path}/resized_image.jpg');
    resizedFile.writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

    return resizedFile;
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_pickedImage == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final resizedImage = await _resizeImage(File(_pickedImage!.path));

      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: resizedImage.path,
          resourceType: CloudinaryResourceType.image,
        ),
      );

      if (response.isSuccessful) {
        setState(() {
          _uploadedImageUrl = response.secureUrl!;
          if (kDebugMode) {
            print(response.secureUrl!);
          }
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // This is generally where the profile photo URL is saved in Firebase Auth
          await user.updatePhotoURL(_uploadedImageUrl);
        }
        widget.onImageUploaded(_uploadedImageUrl!);
      } else {
        setState(() {
          _errorMessage = 'Error uploading image: ${response.error}';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error uploading image: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ImageProvider _getImageProvider() {
    try {
      if (_pickedImage != null) {
        return FileImage(File(_pickedImage!.path));
      } else if (_uploadedImageUrl != null) {
        return NetworkImage(_uploadedImageUrl!);
      } else if (widget.currentImageUrl != null &&
          widget.currentImageUrl!.isNotEmpty) {
        return NetworkImage(widget.currentImageUrl!);
      } else {
        // Fallback placeholder image
        return const AssetImage('assets/images/default_avatar.png');
      }
    } catch (error) {
      // In case of error loading NetworkImage
      return const AssetImage('assets/images/default_avatar.png');
    }
  }

  bool _isUsingDefaultImage() {
    return (widget.currentImageUrl == null ||
            widget.currentImageUrl!.isEmpty) &&
        _pickedImage == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final double radius = widget.imageSize ?? 60;

    // Outer container for background/framing
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Subtle background color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_errorMessage != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign
                            .left, // Ensure text is left-aligned for English
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onErrorContainer,
                      ),
                      onPressed: () => setState(() => _errorMessage = null),
                    ),
                  ],
                ),
              ),
            ),
          Tooltip(
            message: 'Tap to change profile picture',
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: _pickImage,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2.5,
                        ),
                        color: colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: colorScheme.surface,
                        radius: radius,
                        backgroundImage: _getImageProvider(),
                        child: _isUsingDefaultImage()
                            ? Icon(
                                Icons.person,
                                size: radius * 0.6,
                                color: colorScheme.onSurfaceVariant,
                              )
                            : null,
                      ),
                    ),
                    if (_isLoading)
                      Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Fixed deprecated withOpacity
                          color: colorScheme.surface.withAlpha(204),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                            backgroundColor: colorScheme.surfaceContainerLow,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'Change Profile Picture',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
