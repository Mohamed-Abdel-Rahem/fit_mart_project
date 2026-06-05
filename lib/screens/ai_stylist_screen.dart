// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

const String _kOpenMeteoApiUrl = 'https://api.open-meteo.com/v1/forecast';

class AIStylistScreen extends StatefulWidget {
  const AIStylistScreen({super.key});

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen> {
  late final GenerativeModel _model;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  final List<Content> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeGemini() {
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(
        "You are a warm, knowledgeable, and professional fashion and wardrobe stylist. Use the current weather context provided in the user's message to tailor your fashion advice.\n\n"
        "CRITICAL RULES FOR LINKS:\n"
        "1. NEVER attempt to generate direct product URLs (like amazon.com/item or zara.com/dress). They frequently break or result in 404 errors.\n"
        "2. Instead, you MUST provide a Google Shopping search link so the user can see real, available options.\n"
        "3. Format the link strictly like this: [Shop for Product Name](https://www.google.com/search?tbm=shop&q=product+name+here)\n"
        "4. You MUST replace all spaces in the URL 'q=' parameter with the '+' symbol (e.g., q=blue+denim+jacket).\n"
        "5. Only use standard Markdown for links.",
      ),
      tools: [Tool.googleSearch()],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    String safeUrl = urlString.trim();
    if (!safeUrl.startsWith('http://') && !safeUrl.startsWith('https://')) {
      safeUrl = 'https://$safeUrl';
    }

    final Uri url = Uri.parse(safeUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $safeUrl');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('stylist_chat')
          .orderBy('timestamp')
          .get();

      if (snapshot.docs.isEmpty) {
        final greeting =
            "Hello! I'm your AI Stylist. Tell me what outfit or style dilemma you're facing today!";
        _addLocalMessage(Content.model([TextPart(greeting)]));
        await _saveMessageToFirestore('model', greeting);
      } else {
        final loadedHistory = <Content>[];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final role = data['role'] as String?;
          final text = data['text'] as String?;

          if (role != null && text != null) {
            if (role == 'user') {
              loadedHistory.add(Content.text(text));
            } else {
              loadedHistory.add(Content.model([TextPart(text)]));
            }
          }
        }
        setState(() {
          _chatHistory.clear();
          _chatHistory.addAll(loadedHistory);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error loading chat history: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMessageToFirestore(String role, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('stylist_chat')
          .add({
        'role': role,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving message: $e");
    }
  }

  // --- NEW: Function to clear chat history ---
  Future<void> _clearChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show confirmation dialog before deleting
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content: const Text(
              'This will permanently delete your entire chat history with the AI Stylist.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // Exit if user canceled
    if (confirmDelete != true) return;

    setState(() => _isLoading = true);

    try {
      final collection = _firestore
          .collection('Users')
          .doc(user.uid)
          .collection('stylist_chat');

      // Get all documents in the chat
      final snapshot = await collection.get();

      // Use a WriteBatch to delete everything efficiently
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear the local state so the UI updates
      setState(() {
        _chatHistory.clear();
      });

      // Send a fresh greeting
      final greeting =
          "Hello! I'm your AI Stylist. Tell me what outfit or style dilemma you're facing today!";
      _addLocalMessage(Content.model([TextPart(greeting)]));
      await _saveMessageToFirestore('model', greeting);

    } catch (e) {
      debugPrint("Error deleting chat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to clear chat: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addLocalMessage(Content content) {
    setState(() {
      _chatHistory.add(content);
    });
    _scrollToBottom();
  }

  Future<String> _getCurrentWeatherDescription() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return "Location services are disabled on the device.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return "Location permission was denied. Cannot get weather context.";
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final url = Uri.parse(
        '$_kOpenMeteoApiUrl?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,wind_speed_10m&temperature_unit=celsius&wind_speed_unit=ms&timezone=auto',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final current = data['current'];
        final temp = current['temperature_2m'] as num;
        final windSpeed = current['wind_speed_10m'] as num;
        final units = data['current_units'];
        final tempUnit = units['temperature_2m'] ?? '°C';
        final windUnit = units['wind_speed_10m'] ?? 'm/s';

        final lat = position.latitude.toStringAsFixed(2);
        final lon = position.longitude.toStringAsFixed(2);

        return "The current weather (Lat: $lat, Lon: $lon) is ${temp.toStringAsFixed(1)}$tempUnit and the wind speed is ${windSpeed.toStringAsFixed(1)}$windUnit. Tailor your outfit advice accordingly.";
      } else {
        return "Weather service error: Received status code ${response.statusCode}.";
      }
    } catch (e) {
      return "Failed to get weather data due to an exception: $e";
    }
  }

  Future<void> _sendMessage() async {
    final originalText = _textController.text.trim();
    if (originalText.isEmpty || _isLoading) return;

    _addLocalMessage(Content.text(originalText));
    _textController.clear();
    setState(() => _isLoading = true);

    await _saveMessageToFirestore('user', originalText);

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Guest User';

    final weatherInfo = await _getCurrentWeatherDescription();

    final contextualInputText =
        "The person asking this question is '$userName'. User input: '$originalText'. WEATHER CONTEXT: $weatherInfo";

    final modelInput = Content.text(contextualInputText);

    final historyForModel = [
      ..._chatHistory.where((c) => c.role != 'user'),
      modelInput,
    ];

    try {
      final response = await _model.generateContent(historyForModel);

      final rawText = response.candidates.first.content.parts
          .whereType<TextPart>()
          .map((p) => p.text)
          .join('');

      _addLocalMessage(Content.model([TextPart(rawText)]));
      await _saveMessageToFirestore('model', rawText);
    } catch (e) {
      final errorMsg =
          "Error: Could not connect to the stylist. Please check your connection. $e";
      _addLocalMessage(Content.model([TextPart(errorMsg)]));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar(bool isUser, User? user, ColorScheme colorScheme) {
    if (isUser) {
      final initials = (user?.displayName ?? 'Guest')
          .split(' ')
          .map((word) => word.isNotEmpty ? word[0] : '')
          .join()
          .toUpperCase();

      return CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.primary.withOpacity(0.2),
        foregroundColor: colorScheme.primary,
        backgroundImage:
            user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
        child: user?.photoURL == null
            ? (initials.isNotEmpty
                ? Text(
                    initials.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : const Icon(Icons.person, size: 20))
            : null,
      );
    } else {
      return ClipOval(
        child: Image.asset(
          'assets/icon/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => CircleAvatar(
            backgroundColor: colorScheme.secondary.withOpacity(0.2),
            foregroundColor: colorScheme.secondary,
            radius: 18,
            child: const Icon(Icons.auto_fix_high, size: 20),
          ),
        ),
      );
    }
  }

  Widget _buildMessageBubble(
    String text,
    bool isUser,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: MarkdownBody(
        data: text,
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchUrl(href);
          }
        },
        styleSheet: MarkdownStyleSheet(
          p: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
          a: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? Colors.white : colorScheme.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          listBullet: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Stylist Chat"),
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
        actions: [
          // --- NEW: Clear Chat Button ---
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat History',
            onPressed: _isLoading ? null : _clearChatHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message.role == 'user';
                final text =
                    message.parts.isNotEmpty && message.parts.first is TextPart
                        ? (message.parts.first as TextPart).text
                        : "Invalid message format.";

                final chatContent = Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: isUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      _buildAvatar(isUser, user, colorScheme),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildMessageBubble(
                          text,
                          isUser,
                          theme,
                          colorScheme,
                        ),
                      ),
                    ],
                    if (isUser) ...[
                      Flexible(
                        child: _buildMessageBubble(
                          text,
                          isUser,
                          theme,
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAvatar(isUser, user, colorScheme),
                    ],
                  ],
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: chatContent,
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerLow,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Ask your stylist a question...",
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  onPressed: _isLoading ? null : _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}