// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:fitsmart/cloudinary.dart';
import 'package:fitsmart/screens/TryOnScreens/try_on_history_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({super.key});
  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  File? _personImage;
  final List<File> _garmentImages = [];
  Uint8List? _resultImage;
  bool _isLoading = false;
  // Renaming _isSaving to _isGeneralLoading to better reflect shared usage
  bool _isGeneralLoading = false;
  final ImagePicker _picker = ImagePicker();
  late final GenerativeModel _model;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NEW: Controller for user prompt text
  final TextEditingController _promptController = TextEditingController();

  // Track which garment is currently being saved to show specific loading state
  File? _savingGarmentFile;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _initializeGemini() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    _model = FirebaseAI.googleAI().generativeModel(
      model:
          'gemini-2.5-flash-image', // The recommended model for image editing tasks
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text, ResponseModalities.image],
      ),
    );
  }

  Future<void> _pickPersonImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _personImage = File(picked.path));
    }
  }

  Future<void> _pickGarmentImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (_garmentImages.length < 4) {
        setState(() => _garmentImages.add(File(picked.path)));
      } else {
        _showError("Limit reached. You can select up to 4 garments.");
      }
    }
  }

  // Helper function to download image URL to a local File
  Future<File?> _downloadImageToFile(String url) async {
    try {
      // This requires dart:io for HttpClient
      final response = await HttpClient()
          .getUrl(Uri.parse(url))
          .then((request) => request.close());

      // consolidateHttpClientResponseBytes is available via flutter/foundation.dart
      final bytes = await consolidateHttpClientResponseBytes(response);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/garment_download_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      if (kDebugMode) {
        print("Download error: $e");
      }
      _showError("Failed to download image: $e");
      return null;
    }
  }

  Future<void> _pickGarmentFromDressRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("You must be logged in to access your Dress Room.");
      return;
    }

    // Prevent selecting if the limit is already reached
    if (_garmentImages.length >= 4) {
      _showError("Garment limit (4) already reached. Remove an item first.");
      return;
    }

    setState(() => _isGeneralLoading = true);

    try {
      // 1. Fetch all garment URLs from Firestore
      final snapshot = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('virtual_dress_room')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> garments = snapshot.docs.map((doc) {
        return {'imageUrl': doc['imageUrl'], 'id': doc.id};
      }).toList();

      if (garments.isEmpty) {
        _showError(
          "Your Virtual Dress Room is empty. Save some garments first!",
        );
        return;
      }

      // 2. Show a dialog for the user to select a garment
      final selectedGarment = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          return _buildGarmentSelectionDialog(context, garments);
        },
      );

      // 3. Process selection
      if (selectedGarment != null) {
        final imageUrl = selectedGarment['imageUrl'] as String;

        // Double check limit after dialog closure (just in case user removed items outside of the screen)
        if (_garmentImages.length >= 4) {
          _showError(
            "Garment limit (4) already reached. Remove an item first.",
          );
          return;
        }

        // We must download the image to a local File
        final file = await _downloadImageToFile(imageUrl);

        if (file != null) {
          setState(() => _garmentImages.add(file));
          _showError("Garment added from Dress Room.");
        }
        // _downloadImageToFile already calls _showError on failure
      }
    } catch (e) {
      _showError("Error accessing Dress Room: $e");
      if (kDebugMode) {
        print("Dress Room Error: $e");
      }
    } finally {
      setState(() => _isGeneralLoading = false);
    }
  }

  Future<void> _generateVirtualTryOn() async {
    if (_personImage == null || _garmentImages.isEmpty) {
      _showError("Please select a person photo and at least one garment.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final personBytes = await _personImage!.readAsBytes();
      final personPart = InlineDataPart('image/jpeg', personBytes);

      final garmentParts = await Future.wait(
        _garmentImages.map((file) async {
          final bytes = await file.readAsBytes();
          return InlineDataPart('image/jpeg', bytes);
        }),
      );

      // Extract user text input for refinement
      final userPrompt = _promptController.text.trim();
      final refinementInstruction = userPrompt.isNotEmpty
          ? "\n\nUser refinement instruction: $userPrompt"
          : "";

      final promptText =
          """
You are a professional virtual fashion stylist and photo editor.
Replace ALL clothing that the person in the first image is currently wearing with the exact clothing items provided in the subsequent images (the new garments).
Make it look perfectly realistic:
- Match the pose, body shape, and lighting exactly
- Proper fit, wrinkles, shadows, fabric drape, and how it falls on the body
- Keep the person's face, hair, hands, feet, jewelry, and background 100% unchanged
- High-resolution, photorealistic result, no cartoon or artificial look
- Seamless blending, no visible edges or artifacts
$refinementInstruction
Only output the final edited image. Do NOT include any text in the response.
""";
      final prompt = Content.multi([
        TextPart(promptText),
        personPart,
        ...garmentParts,
      ]);

      final response = await _model.generateContent([prompt]);

      if (response.inlineDataParts.isNotEmpty) {
        final imageBytes = response.inlineDataParts.first.bytes;
        setState(() {
          _resultImage = imageBytes;
        });
      } else {
        final text = response.text ?? "Response was empty.";
        if (kDebugMode) {
          print("Model Text Response: $text");
        }
        _showError(
          "No image was generated. Try rephrasing or using fewer garments. Text response: $text",
        );
      }
    } catch (e) {
      _showError("Error during generation: $e");
      if (kDebugMode) {
        print("Full Generation Error: $e");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveResultImage() async {
    if (_resultImage == null) {
      _showError("No generated image to save.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("You must be logged in to save results.");
      return;
    }

    setState(() => _isGeneralLoading = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/vto_result_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(_resultImage!);

      final response = await cloudinary.uploadFile(
        filePath: tempFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'virtual_try_on/${user.uid}',
        fileName: 'vto_result_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful && response.secureUrl != null) {
        final imageUrl = response.secureUrl!;

        await _firestore
            .collection('Users')
            .doc(user.uid)
            .collection('virtual_try_on')
            .add({
              'imageUrl': imageUrl,
              'timestamp': FieldValue.serverTimestamp(),
              'garmentsCount': _garmentImages.length,
            });

        _showError("Try-on image saved successfully to the cloud!");

        await tempFile.delete();
      } else {
        throw Exception(response.error ?? "Cloudinary upload failed.");
      }
    } catch (e) {
      _showError("Failed to save image: $e");
      if (kDebugMode) {
        print("Full Save Error: $e");
      }
    } finally {
      setState(() => _isGeneralLoading = false);
    }
  }

  // UPDATED METHOD: Saves a single garment to the Virtual Dress Room
  Future<void> _saveSingleGarmentToDressRoom(File garmentFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("You must be logged in to save garments.");
      return;
    }

    // Set saving state for this specific file
    setState(() => _savingGarmentFile = garmentFile);

    try {
      final dressRoomCollection = _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('virtual_dress_room'); // New collection for garments

      // 1. Upload to Cloudinary
      final response = await cloudinary.uploadFile(
        filePath: garmentFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'dress_room/${user.uid}', // Dedicated folder
        fileName: 'garment_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful && response.secureUrl != null) {
        final imageUrl = response.secureUrl!;

        // 2. Save URL to Firestore
        await dressRoomCollection.add({
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'filename': garmentFile.path.split('/').last,
        });

        _showError("Garment saved successfully to the Virtual Dress Room!");
      } else {
        throw Exception(response.error ?? "Cloudinary upload failed.");
      }
    } catch (e) {
      _showError("Failed to save garment: $e");
      if (kDebugMode) {
        print("Full Save Garment Error: $e");
      }
    } finally {
      // Clear saving state
      setState(() => _savingGarmentFile = null);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // Navigation method for the history screen
  void _goToHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TryOnHistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Virtual Try-On Studio"),
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_toggle_off_outlined),
            tooltip: 'View Try-On History',
            onPressed: _goToHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Person Photo Upload
            _buildImagePicker(
              label: "1. Upload Your Photo (Full body recommended)",
              image: _personImage,
              onTap: _pickPersonImage,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 30),
            // 2. Garment Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "2. Select New Outfit Pieces (up to 4)",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                // REMOVED: The dedicated Dress Room button.
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._garmentImages.map(
                  // Pass the current loading state into the thumbnail
                  (img) => _garmentThumbnail(img, colorScheme),
                ),
                _addGarmentButton(
                  colorScheme,
                ), // This button is now updated to handle both options
                // Removed _saveGarmentsButton as requested
              ],
            ),

            const SizedBox(height: 30),
            // 3. Optional Prompt Input
            _buildPromptInput(theme, colorScheme),

            const SizedBox(height: 40),
            // 4. Generate Button
            Center(
              child: ElevatedButton(
                onPressed:
                    _isLoading ||
                        _isGeneralLoading ||
                        _savingGarmentFile != null
                    ? null
                    : _generateVirtualTryOn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        "Generate Try-On Image",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            // 5. Result Display
            if (_resultImage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "4. Result:",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 600,
                        maxWidth: 500,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        color: colorScheme.surface,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_resultImage!, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isGeneralLoading ||
                              _isLoading ||
                              _savingGarmentFile != null
                          ? null
                          : _saveResultImage,
                      icon: _isGeneralLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            )
                          : Icon(
                              Icons.cloud_upload_outlined,
                              color: colorScheme.onSecondaryContainer,
                            ),
                      label: Text(
                        _isGeneralLoading
                            ? "Saving..."
                            : "Save to Cloud & History",
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "3. Optional: Style Guidance / Refinements",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _promptController,
          maxLines: 4,
          minLines: 1,
          decoration: InputDecoration(
            hintText:
                "E.g., 'Give the shirt realistic wrinkles and change the lighting to soft studio light.' (Max 200 chars)",
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            fillColor: colorScheme.surfaceContainerHigh,
            filled: true,
            counterText: '', // Hide default counter
          ),
          maxLength: 200,
          style: TextStyle(color: colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? image,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 350,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: image == null ? 2 : 0,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        size: 80,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to select a photo',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }

  // REMOVED: _buildDressRoomButton is no longer needed.
  // The functionality is moved into the updated _addGarmentButton below.

  // UPDATED: Dialog to select a saved garment, now explicitly theme-aware.
  Widget _buildGarmentSelectionDialog(
    BuildContext context,
    List<Map<String, dynamic>> garments,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      title: Text(
        "Select from Dress Room",
        style: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: garments.length,
          itemBuilder: (context, index) {
            final garment = garments[index];
            return GestureDetector(
              onTap: () {
                // Return the selected garment data
                Navigator.of(context).pop(garment);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    garment['imageUrl'] as String,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: colorScheme.error,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colorScheme.secondary)),
        ),
      ],
    );
  }

  // FIXED: Simplified conditional dimming logic to fix image display issue.
  Widget _garmentThumbnail(File img, ColorScheme colorScheme) {
    final isSavingThisFile = _savingGarmentFile == img;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              // Use Stack for layering the image and the overlay
              fit: StackFit.expand,
              children: [
                // 1. The original image
                Image.file(img, width: 100, height: 100, fit: BoxFit.cover),
                // 2. Conditional Dimming Overlay
                if (isSavingThisFile)
                  Container(
                    color: colorScheme.surfaceVariant.withOpacity(
                      0.7,
                    ), // Apply dimming overlay
                  ),
              ],
            ),
          ),
        ),
        // 1. Delete Button (Top Right)
        Positioned(
          top: -10,
          right: -10,
          child: IconButton(
            icon: Icon(Icons.cancel, color: colorScheme.error, size: 28),
            onPressed: () => setState(() => _garmentImages.remove(img)),
          ),
        ),
        // 2. Save Button (Bottom Left)
        Positioned(
          bottom: -10,
          left: -10,
          child: IconButton(
            icon: isSavingThisFile
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.tertiary,
                    ),
                  )
                : Icon(
                    Icons.cloud_download,
                    color: colorScheme.tertiary,
                    size: 28,
                  ),
            tooltip: 'Save to Dress Room',
            onPressed: isSavingThisFile || _isLoading || _isGeneralLoading
                ? null
                : () => _saveSingleGarmentToDressRoom(img),
          ),
        ),
      ],
    );
  }

  // UPDATED: Now prompts the user to choose between uploading a new photo
  // or selecting from the saved Dress Room.
  Widget _addGarmentButton(ColorScheme colorScheme) {
    final isAnyLoading =
        _isLoading || _isGeneralLoading || _savingGarmentFile != null;

    return GestureDetector(
      onTap: isAnyLoading
          ? null
          : () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(
                            Icons.add_a_photo,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            'Upload New Garment',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close the bottom sheet
                            _pickGarmentImage();
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.checkroom_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            'Select from Dress Room',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close the bottom sheet
                            _pickGarmentFromDressRoom();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border.all(color: colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isAnyLoading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              )
            : Icon(Icons.add_a_photo, size: 40, color: colorScheme.primary),
      ),
    );
  }

  // Removed _saveGarmentsButton as requested
}
