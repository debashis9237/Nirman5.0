import 'dart:async';
import 'dart:io'; // Import for File
import 'dart:math'; // Ensure Random is imported
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:file_picker/file_picker.dart'; // Import file_picker
import 'package:intl/intl.dart'; // For formatting timestamps
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isWaitingForApiResponse = false;

  static const String _apiKey =
      "AIzaSyCMOVqzMDw53FWNTIx8QJ9Ahk27rJ3vHJg"; // TODO: Replace

  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  int _messageCounter = 0;

  bool _isTypingPaused = false;
  String? _fullAiResponseForTyping;
  Key? _aiMessageKeyBeingTyped;
  int _typingAnimationCharIndex =
      0; // Tracks current char index for typing animation

  // New state variables for pending attachment
  String? _pendingAttachmentPath;
  String? _pendingAttachmentType;
  String? _pendingAttachmentName;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: _apiKey);
    _chat = _model.startChat();

    // Example: Add an initial greeting from the AI when the page loads
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _addInitialGreeting();
    // });
  }

  // void _addInitialGreeting() {
  //   const String greeting = "Hello! How can I help you today?";
  //   _startAiTypingAnimation(greeting);
  // }

  void _cancelCurrentTypingAnimation() {
    _typingTimer?.cancel();
    _typingTimer = null;
  }

  void _pauseAiTyping() {
    if (_typingTimer != null && _typingTimer!.isActive) {
      _typingTimer?.cancel();
      _typingTimer = null;
      setState(() {
        _isTypingPaused = true;
      });
    }
  }

  void _resumeAiTyping() {
    if (_isTypingPaused &&
        _fullAiResponseForTyping != null &&
        _aiMessageKeyBeingTyped != null) {
      setState(() {
        _isTypingPaused = false;
      });
      _animateNextCharacter(); // Restart the animation from where it left off
    }
  }

  Future<void> _sendMessage() async {
    _cancelCurrentTypingAnimation(); // Cancel any ongoing typing
    // Reset typing-specific state for a new message sequence
    setState(() {
      _isTypingPaused = false;
      _fullAiResponseForTyping = null;
      _aiMessageKeyBeingTyped = null;
      _typingAnimationCharIndex = 0;
    });

    final userMessageText = _controller.text;
    final String? currentAttachmentPath = _pendingAttachmentPath;
    final String? currentAttachmentType = _pendingAttachmentType;
    final String? currentAttachmentName = _pendingAttachmentName;

    if (userMessageText.isEmpty && currentAttachmentPath == null) {
      return; // Nothing to send
    }

    // Construct the user message for the UI
    String displayMessageText = userMessageText;
    if (currentAttachmentPath != null) {
      if (userMessageText.isNotEmpty) {
        displayMessageText = "$userMessageText (with $currentAttachmentName)";
      } else {
        // If only an attachment is sent, use its name for the display message
        displayMessageText =
            "Sent ${currentAttachmentType ?? 'file'}: ${currentAttachmentName ?? 'attachment'}";
      }
    }

    final userMessageKey = ValueKey(_messageCounter++);
    final userAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final userMessageForUi = {
      "sender": "user",
      "text": displayMessageText,
      "timestamp": DateTime.now(),
      "key": userMessageKey,
      "animationController": userAnimationController,
    };

    setState(() {
      _messages.add(userMessageForUi);
      _isWaitingForApiResponse = true;
    });
    _scrollToBottom();
    userAnimationController.forward();

    // Now clear the input field and pending attachment state
    _controller.clear();
    setState(() {
      _pendingAttachmentPath = null;
      _pendingAttachmentType = null;
      _pendingAttachmentName = null;
    });

    try {
      List<Part> parts = [];

      // Add text part if exists
      if (userMessageText.isNotEmpty) {
        parts.add(TextPart(userMessageText));
      }

      // Add data part if attachment exists
      if (currentAttachmentPath != null && currentAttachmentType != null) {
        final file = File(currentAttachmentPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          String mimeType =
              _getMimeType(currentAttachmentPath, currentAttachmentType);
          parts.add(DataPart(mimeType, bytes));
          print(
              "Sending attachment: $currentAttachmentName, MIME: $mimeType, Size: ${bytes.length} bytes");
        } else {
          _addErrorMessage(
              "Attachment file not found: ${currentAttachmentName ?? 'file'}");
          setState(() {
            _isWaitingForApiResponse = false;
          });
          return;
        }
      }

      if (parts.isEmpty) {
        _addErrorMessage(
            "Nothing to send to AI."); // Should be caught earlier, but as a safeguard
        setState(() {
          _isWaitingForApiResponse = false;
        });
        return;
      }

      final content = Content.multi(parts);
      final response = await _chat.sendMessage(content);
      final aiText = response.text;

      setState(() {
        _isWaitingForApiResponse = false;
      });

      if (aiText != null && aiText.isNotEmpty) {
        // Ensure UI has settled from user message and loading indicator removal
        Future.delayed(const Duration(milliseconds: 100), () {
          _startAiTypingAnimation(aiText);
        });
      } else {
        _addErrorMessage(aiText == null
            ? "AI response was null or contained no text."
            : "AI response was empty.");
      }
    } catch (e) {
      print("Error sending message: $e");
      if (e is GenerativeAIException) {
        _addErrorMessage(
            "AI Error: ${e.message}. Please check your input or API key.");
      } else {
        _addErrorMessage("Sorry, I couldn't get a response. Please try again.");
      }
      setState(() {
        _isWaitingForApiResponse = false;
        // Ensure typing states are reset on error too
        _typingTimer?.cancel();
        _typingTimer = null;
        _isTypingPaused = false;
        _fullAiResponseForTyping = null;
        _aiMessageKeyBeingTyped = null;
      });
    }
  }

  void _startAiTypingAnimation(String text) {
    _cancelCurrentTypingAnimation(); // Ensure any previous timer is stopped.

    final aiMessageKey = ValueKey("ai_${_messageCounter++}");
    final aiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final aiMessage = {
      "sender": "ai",
      "text": "", // Start with empty text
      "timestamp": DateTime.now(),
      "key": aiMessageKey,
      "animationController": aiAnimationController,
      "isTyping": true,
    };

    setState(() {
      _messages.add(aiMessage);
      _isTypingPaused = false;
      _fullAiResponseForTyping = text;
      _aiMessageKeyBeingTyped = aiMessageKey;
      _typingAnimationCharIndex = 0;
    });
    _scrollToBottom(); // Scroll when new AI message bubble is added

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        aiAnimationController.forward();
      }
    });

    _animateNextCharacter(); // Start the character-by-character animation
  }

  void _animateNextCharacter() {
    if (_isTypingPaused ||
        _fullAiResponseForTyping == null ||
        _aiMessageKeyBeingTyped == null) {
      return;
    }

    final text = _fullAiResponseForTyping!;
    final messageKey = _aiMessageKeyBeingTyped!;

    final messageIndex = _messages.indexWhere((m) => m["key"] == messageKey);
    if (messageIndex == -1) {
      _cancelCurrentTypingAnimation();
      return;
    }

    if (_typingAnimationCharIndex >= text.length) {
      setState(() {
        _messages[messageIndex]["isTyping"] = false;
      });
      _typingTimer = null;
      return;
    }

    setState(() {
      _messages[messageIndex]["text"] =
          text.substring(0, _typingAnimationCharIndex + 1);
      _scrollToBottom(); // Scroll as text is added
    });
    _typingAnimationCharIndex++;

    // Faster base delay: 5ms to 15ms (previously 20ms to 50ms)
    int baseDelayMillis = Random().nextInt(11) + 5;

    int punctuationDelayMillis = 0;
    if (_typingAnimationCharIndex > 0 &&
        _typingAnimationCharIndex <= text.length) {
      final charJustTyped = text[_typingAnimationCharIndex - 1];

      // Reduced punctuation delays
      if (charJustTyped == '.' ||
          charJustTyped == '!' ||
          charJustTyped == '?') {
        punctuationDelayMillis =
            Random().nextInt(50) + 50; // Extra 50-99ms (previously 200-349ms)
      } else if (charJustTyped == ',') {
        punctuationDelayMillis =
            Random().nextInt(30) + 30; // Extra 30-59ms (previously 100-199ms)
      } else if (charJustTyped == '\\n') {
        punctuationDelayMillis =
            Random().nextInt(40) + 40; // Extra 40-79ms (previously 150-249ms)
      }
    }

    final totalDelay = baseDelayMillis + punctuationDelayMillis;

    _typingTimer =
        Timer(Duration(milliseconds: totalDelay), _animateNextCharacter);
  }

  void _addErrorMessage(String messageText) {
    final errorKey = ValueKey(_messageCounter++);
    final errorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final errorMessage = {
      "sender": "ai",
      "text": messageText,
      "timestamp": DateTime.now(),
      "key": errorKey,
      "animationController": errorAnimationController,
      "isError": true,
    };
    setState(() {
      _messages.add(errorMessage);
    });
    _scrollToBottom();
    errorAnimationController.forward(); // Animate error message in
  }

  // --- New methods for file and image picking ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        print('Image picked: ${image.path}');
        _addUserMessageWithAttachment(image.name, "image", image.path);
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
      _addErrorMessage("Could not pick image. Please try again.");
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
          // type: FileType.custom,
          // allowedExtensions: ['jpg', 'pdf', 'doc', 'png', 'txt'], // Example
          );
      if (result != null) {
        PlatformFile file = result.files.first;
        print('File picked: ${file.name}');
        print('File path: ${file.path}');
        if (file.path != null) {
          _addUserMessageWithAttachment(file.name, "file", file.path!);
        } else {
          _addErrorMessage(
              "Could not get file path for attachment. Please try selecting the file again.");
          print(
              'File path was null. This might happen if bytes were requested directly from picker.');
        }
      } else {
        // User canceled the picker
        print('No file selected.');
      }
    } catch (e) {
      print('Error picking file: $e');
      _addErrorMessage("Could not pick file. Please try again.");
    }
  }

  // Helper to add a user message that signifies an attachment
  void _addUserMessageWithAttachment(
      String displayName, String type, String filePath) {
    final userMessageKey = ValueKey(_messageCounter++);
    final userAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // This message is purely for UI feedback that a file has been selected.
    final userDisplayMessage = {
      "sender": "user",
      "text":
          "Selected $type: ${displayName.split(Platform.pathSeparator).last}",
      "timestamp": DateTime.now(),
      "key": userMessageKey,
      "animationController": userAnimationController,
    };

    setState(() {
      _messages.add(userDisplayMessage);
      _pendingAttachmentPath = filePath;
      _pendingAttachmentType = type;
      _pendingAttachmentName = displayName.split(Platform.pathSeparator).last;
    });
    _scrollToBottom();
    userAnimationController.forward();
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text('Camera',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera); // Call _pickImage with camera
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text('Photos',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(
                      ImageSource.gallery); // Call _pickImage with gallery
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text('Document',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFile(); // Call _pickFile
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this new helper method at the end of the _ChatbotPageState class
  String _getMimeType(String filePath, String attachmentType) {
    String extension = filePath.split('.').last.toLowerCase();

    if (attachmentType == "image") {
      if (extension == "png") return "image/png";
      if (extension == "jpg" || extension == "jpeg") return "image/jpeg";
      if (extension == "gif") return "image/gif";
      if (extension == "webp") return "image/webp";
      if (extension == "heic") return "image/heic";
      if (extension == "heif") return "image/heif";
      return "image/jpeg"; // Default for images if specific type not matched
    } else if (attachmentType == "file") {
      // Common document types
      if (extension == "pdf") return "application/pdf";
      if (extension == "txt") return "text/plain";
      if (extension == "csv") return "text/csv";
      if (extension == "json") return "application/json";
      if (extension == "xml") return "application/xml";
      if (extension == "html") return "text/html";
      // Microsoft Office types
      if (extension == "doc") return "application/msword";
      if (extension == "docx")
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      if (extension == "ppt") return "application/vnd.ms-powerpoint";
      if (extension == "pptx")
        return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
      if (extension == "xls") return "application/vnd.ms-excel";
      if (extension == "xlsx")
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      // Audio types
      if (extension == "mp3") return "audio/mpeg";
      if (extension == "wav") return "audio/wav";
      if (extension == "aac") return "audio/aac";
      if (extension == "ogg") return "audio/ogg";
      if (extension == "flac") return "audio/flac";
      // Video types
      if (extension == "mp4") return "video/mp4";
      if (extension == "mov") return "video/quicktime";
      if (extension == "avi") return "video/x-msvideo";
      if (extension == "webm") return "video/webm";
      if (extension == "mkv") return "video/x-matroska";

      return "application/octet-stream"; // Generic fallback for other file types
    }
    return "application/octet-stream"; // Default fallback
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Delay slightly to allow the UI to update before scrolling
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _cancelCurrentTypingAnimation();
    _controller.dispose();
    _scrollController.dispose();
    for (var message in _messages) {
      (message['animationController'] as AnimationController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doctor'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        actions: const [], // Removed the global pause/resume button from here
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message['sender'] == 'user';
                final animationController =
                    message['animationController'] as AnimationController;

                Widget messageBubbleContent;
                if (message['isError'] == true) {
                  messageBubbleContent = Text(
                    message['text'],
                    style:
                        TextStyle(color: theme.colorScheme.error, fontSize: 15),
                  );
                } else if (isUserMessage) {
                  messageBubbleContent = Text(
                    message['text'],
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 15),
                  );
                } else {
                  // AI message
                  messageBubbleContent = MarkdownBody(
                    data: message['text'],
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                      // You can customize other styles like h1, h2, code, etc.
                    ),
                  );
                }

                Widget messageContent = Container(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: isUserMessage
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUserMessage) ...[
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.2),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.android_rounded,
                                    color: theme.colorScheme.primary, size: 24);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        // Ensures bubble doesn't overflow
                        child: Column(
                          crossAxisAlignment: isUserMessage
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: isUserMessage
                                    ? theme.colorScheme.primary
                                    : (message['isError'] == true
                                        ? theme.colorScheme.errorContainer
                                        : theme.colorScheme
                                            .surfaceVariant), // Different color for AI & Error
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18.0),
                                  topRight: const Radius.circular(18.0),
                                  bottomLeft: isUserMessage
                                      ? const Radius.circular(18.0)
                                      : const Radius.circular(4.0),
                                  bottomRight: isUserMessage
                                      ? const Radius.circular(4.0)
                                      : const Radius.circular(18.0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child:
                                  messageBubbleContent, // Use the prepared content
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                DateFormat('hh:mm a')
                                    .format(message['timestamp'] as DateTime),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUserMessage) ...[
                        const SizedBox(width: 8),
                        // Could add user avatar here if desired
                        // CircleAvatar(child: Icon(Icons.person_outline)),
                      ],
                    ],
                  ),
                );

                // Use FadeTransition and SlideTransition driven by the message's controller
                return FadeTransition(
                  opacity: CurvedAnimation(
                      parent: animationController, curve: Curves.easeIn),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3), // Start slightly below
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeOutQuad,
                    )),
                    child: messageContent,
                  ),
                );
              },
            ),
          ),
          if (_isWaitingForApiResponse &&
              (_typingTimer == null || !_typingTimer!.isActive))
            const TypingIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                8.0, 12.0, 8.0, 24.0), // Adjusted padding
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Align items to bottom
              children: [
                // Action Button
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 0), // Adjust if send button size changes
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded,
                        color: theme.colorScheme.primary, size: 28),
                    onPressed: _isWaitingForApiResponse
                        ? null
                        : _showActionMenu, // Disable if API is waiting for initial response
                    tooltip: 'Attach files',
                  ),
                ),
                // Text Field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isWaitingForApiResponse
                          ? ''
                          : 'Message Pocket Doctor...', // Clearer hint
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 14.0),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                    enabled: !_isWaitingForApiResponse,
                    style: const TextStyle(fontSize: 15),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 4.0), // Reduced spacing

                // Pause/Resume Button
                if (_typingTimer != null &&
                    _typingTimer!.isActive &&
                    !_isTypingPaused)
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 0), // Adjust to align with send button
                    child: IconButton(
                      icon: Icon(Icons.pause_circle_outline_rounded,
                          color: theme.colorScheme.primary, size: 28),
                      onPressed: _pauseAiTyping,
                      tooltip: 'Pause typing',
                    ),
                  )
                else if (_isTypingPaused && _fullAiResponseForTyping != null)
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 0), // Adjust to align with send button
                    child: IconButton(
                      icon: Icon(Icons.play_circle_outline_rounded,
                          color: theme.colorScheme.primary, size: 28),
                      onPressed: _resumeAiTyping,
                      tooltip: 'Resume typing',
                    ),
                  ),

                // Send Button
                ElevatedButton(
                  onPressed: _isWaitingForApiResponse ? null : _sendMessage,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding:
                        const EdgeInsets.all(14.0), // Slightly smaller padding
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white, // For icon color
                    elevation: _isWaitingForApiResponse ? 0 : 2,
                  ),
                  child: _isWaitingForApiResponse
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildAiMessageContent(String text, ThemeData theme) {
  List<InlineSpan> spans = [];
  final lines = text.split('\\n');

  for (var i = 0; i < lines.length; i++) {
    String lineContent = lines[i];
    List<InlineSpan> currentLineSpans = [];

    // Check for bullet points
    if (lineContent.trim().startsWith('* ')) {
      currentLineSpans.add(TextSpan(
        text: "• ", // Bullet symbol
        style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.bold),
      ));
      lineContent = lineContent.trim().substring(2); // Remove '* '
    }

    // Process lineContent for bold text
    RegExp boldPattern = RegExp(r'\\*\\*(.*?)\\*\\*');
    int currentIndex = 0; // Current position in lineContent

    for (Match match in boldPattern.allMatches(lineContent)) {
      // Add text before the current bold match
      if (match.start > currentIndex) {
        currentLineSpans.add(TextSpan(
          text: lineContent.substring(currentIndex, match.start),
          // Style will be inherited from RichText's TextSpan or default
        ));
      }
      // Add the bold text itself (if group 1 is not empty)
      if (match.group(1) != null && match.group(1)!.isNotEmpty) {
        currentLineSpans.add(TextSpan(
          text: match.group(1)!,
          style: const TextStyle(fontWeight: FontWeight.bold), // Apply bold
        ));
      } else {
        // Handle empty bold like **** or **, or if group(1) is null (should not happen with (.*?))
        // Render the matched asterisks literally if the content between them is empty.
        currentLineSpans.add(TextSpan(
          text: match.group(0)!, // match.group(0) is the full match, e.g., "**"
          // Style will be inherited
        ));
      }
      currentIndex = match.end;
    }

    // Add any remaining text after the last bold match
    if (currentIndex < lineContent.length) {
      currentLineSpans.add(TextSpan(
        text: lineContent.substring(currentIndex),
        // Style will be inherited
      ));
    }

    spans.addAll(currentLineSpans);

    if (i < lines.length - 1) {
      spans.add(const TextSpan(text: '\\n')); // Add newline back
    }
  }

  if (spans.isEmpty && text.trim().isNotEmpty) {
    // Fallback if no spans were generated but text exists (e.g. text is just " ")
    // Render the original text with default styling.
    return Text(text,
        style:
            TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15));
  }

  if (spans.isEmpty && text.trim().isEmpty) {
    return const SizedBox
        .shrink(); // Return an empty widget for empty or whitespace-only text
  }

  return RichText(
    text: TextSpan(
      style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 15), // Default style for all spans
      children: spans,
    ),
  );
}

// New Typing Indicator Widget
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _dotAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 * index, 0.3 + 0.1 * index, // Staggered animation
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.android_rounded,
                      color: theme.colorScheme.primary, size: 18);
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.all(Radius.circular(18.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _dotAnimations[index],
                  builder: (context, child) {
                    return Opacity(
                      opacity: _dotAnimations[index].value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          color: theme.textTheme.bodyLarge?.color
                              ?.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to provide a TickerProvider if not available in the current context.
// This is a workaround for the SlideTransition animation needing a TickerProvider.
// A more robust solution would involve ensuring _ChatbotPageState itself is a TickerProviderStateMixin
// or passing one down if this widget were part of a larger animated structure.
// For simplicity here, we'll use a placeholder. This might cause issues if not handled correctly.
// Consider making _ChatbotPageState `with TickerProviderStateMixin`.
// class TickerProviderStateMixinNotAvailable implements TickerProvider {
//   @override
//   Ticker createTicker(TickerCallback onTick) {
//     return Ticker(onTick, debugLabel: 'TickerProviderStateMixinNotAvailable');
//   }
// }
