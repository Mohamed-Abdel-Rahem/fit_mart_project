// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:fitsmart/screens/VirtualDressRoomScreen/donation_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:fitsmart/cloudinary.dart';

class VirtualDressRoomScreen extends StatelessWidget {
  const VirtualDressRoomScreen({super.key});

  // NEW method to navigate to donation history
  void _goToDonationHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DonationHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Virtual Dress Room"),
          backgroundColor: colorScheme.primaryContainer,
        ),
        body: Center(
          child: Text(
            "Please log in to view your dress room.",
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    // Reference to the user's virtual_dress_room collection
    final dressRoomRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('virtual_dress_room')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Virtual Dress Room"),
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
        actions: [
          // NEW BUTTON: Donation History
          IconButton(
            icon: const Icon(Icons.history_toggle_off),
            onPressed: () => _goToDonationHistory(context),
            tooltip: 'View Donation History',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: dressRoomRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Error fetching garments: ${snapshot.error}"),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checkroom_outlined,
                      size: 80,
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your Dress Room is empty!",
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Save garments from the Try-On Studio to see them here.",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final garments = snapshot.data!.docs;

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Adjust for aesthetic card layout
              ),
              itemCount: garments.length,
              itemBuilder: (context, index) {
                final doc = garments[index];
                final imageUrl = doc['imageUrl'] as String;
                final docId = doc.id;

                return GarmentCard(
                  imageUrl: imageUrl,
                  docId: docId,
                  theme: theme,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class GarmentCard extends StatefulWidget {
  final String imageUrl;
  final String docId;
  final ThemeData theme;

  const GarmentCard({
    super.key,
    required this.imageUrl,
    required this.docId,
    required this.theme,
  });

  @override
  State<GarmentCard> createState() => _GarmentCardState();
}

class _GarmentCardState extends State<GarmentCard> {
  bool _isDeleting = false;

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // --- DONATE FUNCTIONALITY ---
  Future<void> _donateGarment() async {
    final colorScheme = widget.theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          "Confirm Donation",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "Are you sure you want to donate this garment? It will be moved to your donation history.",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Donate", style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final sourceDocRef = firestore
          .collection('Users')
          .doc(user.uid)
          .collection('virtual_dress_room')
          .doc(widget.docId);

      final targetCollectionRef = firestore
          .collection('Users')
          .doc(user.uid)
          .collection('virtual_donations'); // Destination collection

      // 1. Get the current document data
      final docSnapshot = await sourceDocRef.get();
      if (!docSnapshot.exists) {
        _showError("Garment not found in Dress Room.");
        // If operation fails locally, stop loading only if mounted
        if (mounted) setState(() => _isDeleting = false);
        return;
      }
      final data = docSnapshot.data();

      // 2. Create a new document in the donations collection
      await targetCollectionRef.add({
        ...data!, // Copy all existing fields
        'donatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Delete the original document from the dress room
      await sourceDocRef.delete();
      // Success. The parent StreamBuilder will rebuild and unmount this widget.

      _showError("Garment successfully moved to Donations!");
    } catch (e) {
      _showError("Failed to process donation: $e");
      // Only reset the loading state if the operation failed and the widget is still mounted
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }
  // --- END DONATE FUNCTIONALITY ---

  Future<void> _deleteGarment() async {
    final colorScheme = widget.theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          "Confirm Deletion",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "Are you sure you want to remove this garment permanently? It will be deleted from the cloud.",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete", style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      // 1. Delete from Cloudinary
      final uri = Uri.parse(widget.imageUrl);
      final uploadIndex = uri.path.indexOf('/upload/');
      String cloudinaryPath = uri.path.substring(uploadIndex + 8);

      final versionMatch = RegExp(r'^v\d+\/').firstMatch(cloudinaryPath);
      if (versionMatch != null) {
        cloudinaryPath = cloudinaryPath.substring(versionMatch.end);
      }

      final publicIdToDelete = cloudinaryPath.substring(
        0,
        cloudinaryPath.lastIndexOf('.'),
      );

      await cloudinary.deleteResources(
        publicIds: [publicIdToDelete],
        resourceType: CloudinaryResourceType.image,
      );

      // 2. Delete from Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('virtual_dress_room')
          .doc(widget.docId)
          .delete();

      // Success. The parent StreamBuilder will rebuild and unmount this widget.
      _showError("Garment removed successfully!");
    } catch (e) {
      // If Cloudinary fails, try to delete Firestore anyway to avoid orphaned records
      try {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .collection('virtual_dress_room')
            .doc(widget.docId)
            .delete();
      } catch (_) {
        _showError("Failed to delete garment locally. Contact support.");
      }
      _showError("Failed to delete garment: $e");

      // ONLY reset the loading state if the operation failed and the widget is still mounted
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Garment Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.imageUrl,
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
                    size: 50,
                    color: colorScheme.error,
                  ),
                );
              },
            ),
          ),

          // Deleting/Donating Overlay
          if (_isDeleting)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      "Processing...",
                      style: widget.theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Delete Button (Top Right - Permanent Deletion)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.delete_forever,
                color: colorScheme.error,
                size: 30,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface.withOpacity(0.7),
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
              onPressed: _isDeleting ? null : _deleteGarment,
              tooltip: 'Permanently Delete Garment',
            ),
          ),

          // NEW: Donate Button (Bottom Right - Moves to Donations)
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.card_giftcard,
                color: colorScheme
                    .primary, // Use primary color for the donate action
                size: 30,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surface.withOpacity(0.7),
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
              onPressed: _isDeleting ? null : _donateGarment,
              tooltip: 'Donate Garment (Move to Donation History)',
            ),
          ),
        ],
      ),
    );
  }
}
