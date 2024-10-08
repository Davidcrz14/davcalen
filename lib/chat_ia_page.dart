import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Importamos la librería para imprimir en consola
import 'dart:developer' as developer;

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

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('gemini_api_key');
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

    setState(() {
      _messages.add({'role': 'user', 'content': _messageController.text});
      _isLoading = true;
    });

    try {
      final response = await generateTextWithGemini(_apiKey!, _messageController.text);

      setState(() {
        _isLoading = false;
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      // Agregamos una salida en consola para ver el error completo
      developer.log('Error al generar texto', error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    _messageController.clear();
  }

  Future<String> generateTextWithGemini(String apiKey, String prompt) async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: jsonEncode({
        'contents': [{'parts': [{'text': prompt}]}],
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
      throw Exception('Error al generar texto: ${response.statusCode}\n${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showApiKeyDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message['content']!),
                  leading: Icon(
                    message['role'] == 'user' ? Icons.person : Icons.android,
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
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
            decoration: const InputDecoration(hintText: "Ingresa tu API Key de Gemini"),
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
