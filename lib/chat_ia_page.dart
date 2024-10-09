import 'dart:convert';
// Importamos la librería para imprimir en consola
import 'dart:developer' as developer;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:davcalen/db/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatIAPage extends StatefulWidget {
  const ChatIAPage({Key? key}) : super(key: key);

  @override
  _ChatIAPageState createState() => _ChatIAPageState();
}

class _ChatIAPageState extends State<ChatIAPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? _apiKey;
  bool _isLoading = false;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadChatMessages();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('gemini_api_key');
    });
  }

  Future<void> _loadChatMessages() async {
    final messages = await _databaseHelper.getChatMessages();
    setState(() {
      _messages.clear();
      _messages.addAll(messages.map((m) => {
            'role': m['role'] as String,
            'content': m['content'] as String,
          }));
    });
  }

  Future<void> _saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    setState(() {
      _apiKey = apiKey;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _apiKey == null) return;

    final newMessage = {'role': 'user', 'content': _messageController.text};
    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
    });
    await _databaseHelper.insertChatMessage({
      ...newMessage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      final response = await generateTextWithGemini(_apiKey!, _messages);

      final assistantMessage = {'role': 'assistant', 'content': response};
      setState(() {
        _isLoading = false;
        _messages.add(assistantMessage);
      });
      await _databaseHelper.insertChatMessage({
        ...assistantMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      developer.log('Error al generar texto', error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    _messageController.clear();
  }

  Future<void> _clearChat() async {
    await _databaseHelper.deleteAllChatMessages();
    setState(() {
      _messages.clear();
    });
  }

  Future<String> generateTextWithGemini(String apiKey, List<Map<String, String>> messages) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

    final conversationHistory = messages.map((m) => {
      'role': m['role'] == 'assistant' ? 'model' : 'user',  // Cambiamos 'assistant' a 'model'
      'parts': [{'text': m['content']}]
    }).toList();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': conversationHistory,
        'generationConfig': {
          'temperature': 0.9,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 2048,
          'stopSequences': []
        },
        'safetySettings': []
      }),
    );

    // Agregamos una salida en consola para ver la respuesta completa
    developer.log('Respuesta de la API: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception(
          'Error al generar texto: ${response.statusCode}\n${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat IA',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 71, 141, 135),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showApiKeyDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.deepPurple,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(
                          message['content']!,
                          style: const TextStyle(color: Colors.white),
                        )
                      : AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              message['content']!,
                              textStyle: const TextStyle(color: Colors.black87),
                              speed: const Duration(milliseconds: 50),
                            ),
                          ],
                          totalRepeatCount: 1,
                          displayFullTextOnTap: true,
                        ),
                  if (!isUser)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () => _copyToClipboard(message['content']!),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      backgroundColor:
          isUser ? Colors.deepPurple.shade300 : Colors.grey.shade300,
      child: Icon(
        isUser ? Icons.person : Icons.android,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _sendMessage,
            backgroundColor: Colors.deepPurple,
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texto copiado al portapapeles')),
    );
  }

  Future<void> _showApiKeyDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Configurar API Key'),
          content: TextField(
            controller: _apiKeyController,
            decoration:
                const InputDecoration(hintText: "Ingresa tu API Key de Gemini"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                _saveApiKey(_apiKeyController.text);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
