import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Всего сообщений: ${chatProvider.messages.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Баланс: ${chatProvider.balance}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Text(
            'Использование по моделям:',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...chatProvider.messages
              .fold<Map<String, Map<String, dynamic>>>(
                {},
                (map, msg) {
                  if (msg.modelId != null) {
                    if (!map.containsKey(msg.modelId)) {
                      map[msg.modelId!] = {
                        'count': 0,
                        'tokens': 0,
                        'cost': 0.0,
                      };
                    }
                    map[msg.modelId]!['count'] =
                        map[msg.modelId]!['count']! + 1;
                    if (msg.tokens != null) {
                      map[msg.modelId]!['tokens'] =
                          map[msg.modelId]!['tokens']! + msg.tokens!;
                    }
                    if (msg.cost != null) {
                      map[msg.modelId]!['cost'] =
                          map[msg.modelId]!['cost']! + msg.cost!;
                    }
                  }
                  return map;
                },
              )
              .entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Сообщений: ${entry.value['count']}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        if (entry.value['tokens'] > 0) ...[
                          Text(
                            'Токенов: ${entry.value['tokens']}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          Consumer<ChatProvider>(
                            builder: (context, chatProvider, child) {
                              final isVsetgpt = chatProvider.isVsetgpt;
                              return Text(
                                isVsetgpt
                                    ? 'Стоимость: ${entry.value['cost'] < 1e-8 ? '0.0' : entry.value['cost'].toStringAsFixed(8)}₽'
                                    : 'Стоимость: \$${entry.value['cost'] < 1e-8 ? '0.0' : entry.value['cost'].toStringAsFixed(8)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  )),
        ],
      ),
    );
  }
}
