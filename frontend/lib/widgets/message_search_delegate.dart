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
          title: _buildHighlightedText(msg['content'], query),
          subtitle: Text(msg['User']['username']),
          onTap: () => close(context, msg),
        );
      },
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text);
    
    final matches = query.toLowerCase();
    final parts = text.split(RegExp(query, caseSensitive: false));
    final searchMatches = RegExp(query, caseSensitive: false).allMatches(text).toList();
    
    List<TextSpan> spans = [];
    
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i < searchMatches.length) {
        spans.add(TextSpan(
          text: searchMatches[i].group(0),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ));
      }
    }
    
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white), // Match default theme
        children: spans,
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
