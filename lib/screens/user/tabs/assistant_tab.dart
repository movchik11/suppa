import 'package:flutter/material.dart';
import 'package:supa/screens/user/create_order_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isBot': true,
      'text': 'aiHello'.tr(),
      'options': ['optDiagnose', 'optTips'],
    },
  ];

  final Map<String, List<String>> _symptoms = {
    'optDiagnose': ['diagNoises', 'diagLeaks', 'diagLights', 'diagSteering'],
    'diagNoises': ['noiseSquealing', 'noiseKnocking', 'noiseHissing'],
    'diagLeaks': ['leakOil', 'leakCoolant', 'leakWater'],
    'diagLights': ['lightCheckEngine', 'lightBattery', 'lightOil', 'lightAbs'],
  };

  final Map<String, String> _results = {
    'noiseSquealing': 'resSquealing'.tr(),
    'noiseKnocking': 'resKnocking'.tr(),
    'leakOil': 'resOilLeak'.tr(),
    'lightCheckEngine': 'resCheckEngine'.tr(),
  };

  List<String> _selectionPath = [];
  String? _suggestedService;

  void _handleOption(String option) {
    if (option == 'optStartOver') {
      setState(() {
        _selectionPath.clear();
        _suggestedService = null;
        _messages.clear();
        _messages.add({
          'isBot': true,
          'text': 'aiHello'.tr(),
          'options': ['optDiagnose', 'optTips'],
        });
      });
      return;
    }

    if (option == 'optBookInspection') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateOrderScreen(
            preFillDescription: null,
            suggestedServiceTitle: 'optBookInspection'.tr(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectionPath.add(option.tr());
      _messages.add({'isBot': false, 'text': option.tr()});

      final nextOptions = _symptoms[option];
      final result = _results[option];

      if (result != null) {
        _suggestedService = option.tr();
        _messages.add({'isBot': true, 'text': result, 'isResult': true});
      } else if (nextOptions != null) {
        _messages.add({
          'isBot': true,
          'text': 'aiSpecific'.tr(args: [option.tr()]),
          'options': nextOptions,
        });
      } else if (option == 'optTips') {
        _messages.add({
          'isBot': true,
          'text': 'aiTips'.tr(),
          'options': ['optBookInspection', 'optStartOver'],
        });
      } else {
        _messages.add({
          'isBot': true,
          'text': 'aiUnderstand'.tr(),
          'options': ['optBookInspection', 'optStartOver'],
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _buildChatBubble(msg, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isDark) {
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
                        ? Colors.orange.withAlpha(isDark ? 80 : 51)
                        : Theme.of(
                            context,
                          ).primaryColor.withAlpha(isDark ? 60 : 25))
                  : (isDark
                        ? Colors.blue.withAlpha(80)
                        : Theme.of(context).cardColor),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isBot ? 0 : 20),
                bottomRight: Radius.circular(isBot ? 20 : 0),
              ),
              border: Border.all(
                color: isBot
                    ? (isResult
                              ? Colors.orange
                              : Theme.of(context).primaryColor)
                          .withAlpha(isDark ? 100 : 51)
                    : (isDark ? Colors.blue : Theme.of(context).dividerColor)
                          .withAlpha(100),
              ),
            ),
            child: Text(
              msg['text'],
              style: TextStyle(
                fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
                color: isDark
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
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
                  label: Text(opt.tr()),
                  onPressed: () => _handleOption(opt),
                  backgroundColor: isDark
                      ? Colors.white.withAlpha(30)
                      : Theme.of(context).primaryColor.withAlpha(25),
                  labelStyle: TextStyle(
                    color: isDark
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white38
                        : Theme.of(context).primaryColor.withAlpha(50),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
                    builder: (context) =>
                        CreateOrderScreen(preFillDescription: null),
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
              child: Text('bookSuggested'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
