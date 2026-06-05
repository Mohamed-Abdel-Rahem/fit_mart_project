// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Screen to display the full image and details of a single saved try-on result.
class TryOnDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String formattedDate;
  final int garmentsCount;

  const TryOnDetailScreen({
    super.key,
    required this.imageUrl,
    required this.formattedDate,
    required this.garmentsCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Try-On Details"),
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Saved: $formattedDate",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "$garmentsCount garment(s) applied",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
              ),
              const SizedBox(height: 30),
              // Display the large image
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 600,
                  maxWidth: 500,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder:
                        (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 300,
                            width: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 300,
                      width: 300,
                      color: colorScheme.surfaceContainerHigh,
                      child: const Center(
                        child: Text(
                          "Error loading image",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
