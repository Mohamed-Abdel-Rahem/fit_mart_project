// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added Firebase Auth import
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

const String _kOpenMeteoApiUrl = 'https://api.open-meteo.com/v1/forecast';

String cleanGeminiResponse(String rawText) {
  if (rawText.isEmpty) {
    return "No response returned by AI.";
  }

  // 1. Split into lines and process each one
  final lines = rawText.trim().split('\n');
  final cleanedLines = <String>[];

  for (String line in lines) {
    String cleanedLine = line.trim();
    // Remove bold markdown syntax (**text**)
    cleanedLine = cleanedLine.replaceAllMapped(
      RegExp(r'\*\*([^\*]+)\*\*'),
      (match) => match.group(1)!,
    );
    // Remove leading list markers (-, *, #, 1., etc.)
    cleanedLine = cleanedLine.replaceAll(
      RegExp(r'^[\s#*-]+\s*|^[0-9]+\.\s*'),
      '',
    );

    if (cleanedLine.isNotEmpty) {
      cleanedLines.add(cleanedLine);
    }
  }
  return cleanedLines.join('\n\n').trim();
}

class AIStylistScreen extends StatefulWidget {
  const AIStylistScreen({super.key});

  @override
  State<AIStylistScreen> createState() => _AIStylistScreenState();
}

class _AIStylistScreenState extends State<AIStylistScreen> {
  late final GenerativeModel _model;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Content> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeGemini() async {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.text(
        "You are a warm, knowledgeable, and professional fashion and wardrobe stylist. Provide clear, concise, and helpful advice. Keep the tone encouraging and positive. Use the current weather context provided in the user's message to tailor your fashion advice.",
      ),
    );

    // Initial greeting from the AI
    _addMessage(
      Content.model([
        const TextPart(
          "Hello! I'm your AI Stylist. Tell me what outfit or style dilemma you're facing today!",
        ),
      ]),
    );
  }

  void _addMessage(Content content) {
    setState(() {
      _chatHistory.add(content);
    });
    // Scroll to the latest message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _getCurrentWeatherDescription() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return "Location services are disabled on the device.";
      }

      // 2. Request/Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return "Location permission was denied. Cannot get weather context.";
        }
      }

      // 3. Get current position (latitude and longitude)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // 4. Fetch weather data using coordinates and Open-Meteo API
      final url = Uri.parse(
        '$_kOpenMeteoApiUrl?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,wind_speed_10m&temperature_unit=celsius&wind_speed_unit=ms&timezone=auto',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 5. Safely extract data based on the Open-Meteo response structure
        final current = data['current'];
        final temp = current['temperature_2m'] as num;
        final windSpeed = current['wind_speed_10m'] as num;
        final units = data['current_units'];
        final tempUnit = units['temperature_2m'] ?? '°C';
        final windUnit = units['wind_speed_10m'] ?? 'm/s';

        // Return a clear, concise string for the AI's context
        final lat = position.latitude.toStringAsFixed(2);
        final lon = position.longitude.toStringAsFixed(2);

        return "The current weather (Lat: $lat, Lon: $lon) is ${temp.toStringAsFixed(1)}$tempUnit and the wind speed is ${windSpeed.toStringAsFixed(1)}$windUnit. Tailor your outfit advice accordingly.";
      } else {
        return "Weather service error: Received status code ${response.statusCode}.";
      }
    } catch (e) {
      // Catch exceptions like network errors
      return "Failed to get weather data due to an exception: $e";
    }
  }

  Future<void> _sendMessage() async {
    final originalText = _textController.text.trim();
    if (originalText.isEmpty || _isLoading) return;

    // 1. Add original user message to UI history immediately
    _addMessage(Content.text(originalText));
    _textController.clear();
    setState(() => _isLoading = true);

    // Get current authenticated user details for personalization
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Guest User';

    // 2. Get the current weather context
    final weatherInfo = await _getCurrentWeatherDescription();

    // 3. Construct the FULL contextual prompt for the model, including the user's name
    final contextualInputText =
        "The person asking this question is '$userName'. User input: '$originalText'. WEATHER CONTEXT: $weatherInfo";

    // 4. Create the contextual message part
    final modelInput = Content.text(contextualInputText);

    // 5. Prepare the chat history with the new user message
    final historyForModel = [
      ..._chatHistory.where((c) => c.role != 'user'),
      modelInput,
    ];

    try {
      // 6. Send the contextualized history to maintain full conversation context
      final response = await _model.generateContent(historyForModel);

      // 7. Extract the content and CLEAN it with the new Dart function
      final rawText = response.candidates.first.content.parts
          .whereType<TextPart>()
          .map((p) => p.text)
          .join(''); // Get the full raw text

      final cleanedText = cleanGeminiResponse(rawText);
      _addMessage(Content.model([TextPart(cleanedText)]));
    } catch (e) {
      // Show error
      _addMessage(
        Content.model([
          TextPart(
            "Error: Could not connect to the stylist. Please check your connection. $e",
          ),
        ]),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar(bool isUser, User? user, ColorScheme colorScheme) {
    if (isUser) {
      // User Avatar: Try photoURL, then initials, then icon
      final initials = (user?.displayName ?? 'Guest')
          .split(' ')
          .map((word) => word.isNotEmpty ? word[0] : '')
          .join()
          .toUpperCase();

      return CircleAvatar(
        radius: 18,
        backgroundColor: colorScheme.primary.withOpacity(0.2),
        foregroundColor: colorScheme.primary,
        backgroundImage: user?.photoURL != null
            ? NetworkImage(user!.photoURL!)
            : null,
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
      // AI Stylist Avatar: Use assets/icon/logo.png with a fallback
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
            child: const Icon(Icons.auto_fix_high, size: 20), // Fallback icon
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
        maxWidth: MediaQuery.of(context).size.width * 0.70,
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
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Moved theme, colorScheme, and added user variable as requested
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Stylist Chat"),
        backgroundColor: colorScheme.primaryContainer,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Chat Messages Area
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

                // Build the Row containing avatar and bubble
                final chatContent = Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  // Use MainAxisAlignment to align content to start/end
                  mainAxisAlignment: isUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isUser) ...[
                      // AI message (Avatar on Left)
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
                      // User message (Avatar on Right)
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

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                color: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerLow,
              ),
            ),

          // Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    // FIX: Explicitly set text style and use filled background for contrast
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Ask your stylist a question...",
                      filled: true,
                      fillColor: colorScheme
                          .surfaceContainerLow, // Use a distinct fill color
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
