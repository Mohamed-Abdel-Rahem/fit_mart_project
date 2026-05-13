import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { female, male }

class SizeCalculatorScreen extends StatefulWidget {
  const SizeCalculatorScreen({super.key});

  @override
  State<SizeCalculatorScreen> createState() => _SizeCalculatorScreenState();
}

class _SizeCalculatorScreenState extends State<SizeCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipsController = TextEditingController();

  Gender _selectedGender = Gender.female;
  String? _recommendedSize;
  String? _fitNotes;

  // Loading states
  bool _isSaving = false;
  bool _isLoadingData = true; // NEW: Track initial load state

  @override
  void initState() {
    super.initState();
    _loadSavedMeasurements(); // NEW: Fetch data when screen loads
  }

  @override
  void dispose() {
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    super.dispose();
  }

  // --- NEW: FIREBASE LOADING LOGIC ---
  Future<void> _loadSavedMeasurements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data()!.containsKey('measurements')) {
          final data = doc.data()!['measurements'] as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              if (data['chest'] != null) {
                _chestController.text = data['chest'].toString();
              }
              if (data['waist'] != null) {
                _waistController.text = data['waist'].toString();
              }
              if (data['hips'] != null) {
                _hipsController.text = data['hips'].toString();
              }

              if (data['gender'] != null) {
                _selectedGender = data['gender'] == 'male'
                    ? Gender.male
                    : Gender.female;
              }
            });

            // If we successfully loaded measurements, calculate the size immediately
            // so the user sees their results without pressing the button.
            if (_chestController.text.isNotEmpty &&
                _waistController.text.isNotEmpty &&
                _hipsController.text.isNotEmpty) {
              _calculateAdvancedSize(skipValidation: true);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading measurements: $e");
      // Optionally show a snackbar here, but silently failing on load is often better UX
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // UPDATED: Added skipValidation flag for initial data loading
  void _calculateAdvancedSize({bool skipValidation = false}) {
    if (!skipValidation) {
      if (!_formKey.currentState!.validate()) return;
    }

    final double chest = double.tryParse(_chestController.text) ?? 0;
    final double waist = double.tryParse(_waistController.text) ?? 0;
    final double hips = double.tryParse(_hipsController.text) ?? 0;

    int chestSizeIndex = 0;
    int waistSizeIndex = 0;
    int hipSizeIndex = 0;

    if (_selectedGender == Gender.female) {
      chestSizeIndex = _getIndex(chest, [84, 89, 94, 100, 106]);
      waistSizeIndex = _getIndex(waist, [64, 69, 74, 80, 86]);
      hipSizeIndex = _getIndex(hips, [90, 95, 100, 106, 112]);
    } else {
      chestSizeIndex = _getIndex(chest, [88, 96, 104, 112, 124]);
      waistSizeIndex = _getIndex(waist, [73, 81, 89, 97, 109]);
      hipSizeIndex = _getIndex(hips, [88, 96, 104, 112, 120]);
    }

    int maxSizeIndex = max(chestSizeIndex, max(waistSizeIndex, hipSizeIndex));
    int minSizeIndex = min(chestSizeIndex, min(waistSizeIndex, hipSizeIndex));

    final sizeLabels = [
      'Extra Small (XS)',
      'Small (S)',
      'Medium (M)',
      'Large (L)',
      'Extra Large (XL)',
      'Double XL (XXL)',
    ];

    String finalSize = sizeLabels[maxSizeIndex];
    String notes = "This size should provide a comfortable, standard fit.";

    if (maxSizeIndex - minSizeIndex >= 2) {
      notes =
          "Your measurements span multiple sizes. We recommend looking for 'Relaxed', 'Athletic', or 'Curvy' fits.";
      if (chestSizeIndex > waistSizeIndex && chestSizeIndex > hipSizeIndex) {
        notes += " Look for extra room in the chest/shoulders.";
      } else if (waistSizeIndex > chestSizeIndex &&
          waistSizeIndex > hipSizeIndex) {
        notes += " Consider garments with a relaxed midsection.";
      } else if (hipSizeIndex > waistSizeIndex &&
          hipSizeIndex > chestSizeIndex) {
        notes += " A-line cuts or relaxed-fit trousers will suit you best.";
      }
    } else if (maxSizeIndex - minSizeIndex == 1) {
      notes =
          "You are between sizes. Choose $finalSize for a looser fit, or size down for a tailored look.";
    }

    setState(() {
      _recommendedSize = finalSize;
      _fitNotes = notes;
    });
  }

  int _getIndex(double measurement, List<double> thresholds) {
    for (int i = 0; i < thresholds.length; i++) {
      if (measurement <= thresholds[i]) return i;
    }
    return thresholds.length;
  }

  // --- FIREBASE SAVING LOGIC ---
  Future<void> _saveToFirestore() async {
    if (_recommendedSize == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("You must be logged in to save measurements.");
      }

      final measurementData = {
        'chest': double.tryParse(_chestController.text),
        'waist': double.tryParse(_waistController.text),
        'hips': double.tryParse(_hipsController.text),
        'gender': _selectedGender.name,
        'calculatedSize': _recommendedSize,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'measurements': measurementData,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurements saved to your profile!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildThemedInputCard({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String hint,
    required TextEditingController controller,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: colorScheme.surfaceContainerHigh,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: colorScheme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,

                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),

                      const SizedBox(width: 6),

                      GestureDetector(
                        onTap: () => _showMeasurementGuide(title),

                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      suffixText: 'cm',
                      suffixStyle: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeasurementGuide(String type) {
    String title = '';
    String description = '';
    IconData icon = Icons.accessibility;

    switch (type) {
      case 'Chest / Bust':
        title = 'How to Measure Chest';
        description =
            'Wrap the tape around the fullest part of your chest while keeping it level and relaxed.';
        icon = Icons.accessibility_new;
        break;

      case 'Waist':
        title = 'How to Measure Waist';
        description =
            'Measure around the narrowest part of your waist, usually above your belly button.';
        icon = Icons.horizontal_rule;
        break;

      case 'Hips':
        title = 'How to Measure Hips';
        description =
            'Measure around the widest part of your hips while standing naturally.';
        icon = Icons.tune;
        break;
    }

    showModalBottomSheet(
      context: context,

      backgroundColor: Theme.of(context).colorScheme.surface,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(icon, size: 60, color: colorScheme.primary),

              const SizedBox(height: 16),

              Text(
                title,

                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                description,

                textAlign: TextAlign.center,

                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
        title: Text(
          'Size Calculator',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // NEW: Show a loading indicator while fetching from Firebase
      body: _isLoadingData
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            'Enter Measurements',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get personalized AI sizing recommendations',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(
                          value: Gender.female,
                          icon: Icon(Icons.female),
                          label: Text('Womenswear'),
                        ),
                        ButtonSegment(
                          value: Gender.male,
                          icon: Icon(Icons.male),
                          label: Text('Menswear'),
                        ),
                      ],
                      selected: {_selectedGender},
                      onSelectionChanged: (Set<Gender> newSelection) {
                        setState(() {
                          _selectedGender = newSelection.first;
                          _recommendedSize = null;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedForegroundColor: colorScheme.onPrimary,
                        selectedBackgroundColor: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildThemedInputCard(
                      context: context,
                      colorScheme: colorScheme,
                      icon: Icons.accessibility_new,
                      title: 'Chest / Bust',
                      hint: 'Fullest part',
                      controller: _chestController,
                    ),
                    _buildThemedInputCard(
                      context: context,
                      colorScheme: colorScheme,
                      icon: Icons.horizontal_rule,
                      title: 'Waist',
                      hint: 'Narrowest part',
                      controller: _waistController,
                    ),
                    _buildThemedInputCard(
                      context: context,
                      colorScheme: colorScheme,
                      icon: Icons.tune,
                      title: 'Hips',
                      hint: 'Widest part',
                      controller: _hipsController,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _calculateAdvancedSize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Calculate Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),

                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },

                      child: _recommendedSize != null
                          ? Card(
                              key: ValueKey(_recommendedSize),

                              color: colorScheme.primaryContainer,
                              elevation: 6,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),

                              child: Padding(
                                padding: const EdgeInsets.all(24.0),

                                child: Column(
                                  children: [
                                    Text(
                                      'Your Smart Fit',

                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      _recommendedSize!,

                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),

                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16.0,
                                      ),
                                      child: Divider(height: 1),
                                    ),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: colorScheme.primary,
                                          size: 24,
                                        ),

                                        const SizedBox(width: 16),

                                        Expanded(
                                          child: Text(
                                            _fitNotes!,

                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                  height: 1.4,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    SizedBox(
                                      width: double.infinity,

                                      child: _isSaving
                                          ? Center(
                                              child: CircularProgressIndicator(
                                                color: colorScheme.primary,
                                              ),
                                            )
                                          : OutlinedButton.icon(
                                              onPressed: _saveToFirestore,

                                              icon: const Icon(
                                                Icons.cloud_upload,
                                              ),

                                              label: const Text(
                                                'Save to My Profile',
                                              ),

                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    colorScheme.primary,

                                                side: BorderSide(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                ),

                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),

                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
