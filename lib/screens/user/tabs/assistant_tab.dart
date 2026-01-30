import 'package:flutter/material.dart';
import 'package:supa/screens/user/create_order_screen.dart';

class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text':
          'Hello! I am your AI Auto Assistant. Is something wrong with your car?',
      'options': ['Yes, help me diagnose', 'Just looking for tips'],
    },
  ];

  final Map<String, List<String>> _symptoms = {
    'Yes, help me diagnose': [
      'Engine Noises',
      'Fluid Leaks',
      'Warning Lights',
      'Steering/Brakes',
    ],
    'Engine Noises': ['Squealing', 'Knocking', 'Hissing'],
    'Fluid Leaks': ['Oil (Black/Brown)', 'Coolant (Green/Pink)', 'Water'],
    'Warning Lights': ['Check Engine', 'Battery', 'Oil Pressure', 'ABS'],
  };

  final Map<String, String> _results = {
    'Squealing':
        'Likely a worn fan belt or serpentine belt. Recommended: Belt Inspection.',
    'Knocking':
        'Could be engine bearings or low oil. CAUTION: Stop driving and check oil immediately.',
    'Oil (Black/Brown)':
        'An oil leak is detected. Frequent causes: Gaskets or Seals. Recommended: Oil Leak Repair.',
    'Check Engine':
        'Generic fault detected. Our experts can scan the OBD code for you. Recommended: Computer Diagnostics.',
  };

  void _handleOption(String option) {
    if (option == 'Start Over') {
      setState(() {
        _messages.clear();
        _messages.add({
          'isBot': true,
          'text':
              'Hello! I am your AI Auto Assistant. Is something wrong with your car?',
          'options': ['Yes, help me diagnose', 'Just looking for tips'],
        });
      });
      return;
    }

    if (option == 'Book Inspection') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateOrderScreen(
            preFillDescription: 'General Inspection requested via Assistant',
          ),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({'isBot': false, 'text': option});

      final nextOptions = _symptoms[option];
      final result = _results[option];

      if (result != null) {
        _messages.add({'isBot': true, 'text': result, 'isResult': true});
      } else if (nextOptions != null) {
        _messages.add({
          'isBot': true,
          'text': 'Can you be more specific about "$option"?',
          'options': nextOptions,
        });
      } else if (option == 'Just looking for tips') {
        _messages.add({
          'isBot': true,
          'text':
              'Keep an eye on tire pressure, check fluids every 2 weeks, and never ignore squeaking brakes! Would you like a professional inspection?',
          'options': ['Book Inspection', 'Start Over'],
        });
      } else {
        _messages.add({
          'isBot': true,
          'text': 'I understand. Would you like to book a general inspection?',
          'options': ['Book Inspection', 'Start Over'],
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildChatBubble(msg);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    final isBot = msg['isBot'] as bool;
    final isResult = msg['isResult'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isBot
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isBot
                  ? (isResult
                        ? Colors.orange.withAlpha(51)
                        : Colors.blue.withAlpha(25))
                  : Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isBot ? 0 : 20),
                bottomRight: Radius.circular(isBot ? 20 : 0),
              ),
              border: Border.all(
                color: isBot
                    ? (isResult ? Colors.orange : Colors.blue).withAlpha(51)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              msg['text'],
              style: TextStyle(
                fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isBot && msg['options'] != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (msg['options'] as List<String>).map((opt) {
                return ActionChip(
                  label: Text(opt),
                  onPressed: () => _handleOption(opt),
                  backgroundColor: Colors.blue.withAlpha(25),
                  labelStyle: const TextStyle(color: Colors.blue, fontSize: 12),
                );
              }).toList(),
            ),
          ],
          if (isResult) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateOrderScreen(
                      preFillDescription: 'Diagnosis: ${msg['text']}',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 45),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Book Suggested Service'),
            ),
          ],
        ],
      ),
    );
  }
}
