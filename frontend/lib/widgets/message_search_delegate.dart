import 'package:flutter/material.dart';

class MessageSearchDelegate extends SearchDelegate {
  final List<dynamic> messages;

  MessageSearchDelegate({required this.messages});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = messages.where((m) => 
      m['type'] == 'text' && 
      m['content'].toString().toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final msg = results[i];
        return ListTile(
          title: Text(msg['content']),
          subtitle: Text(msg['User']['username']),
          onTap: () => close(context, msg),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
