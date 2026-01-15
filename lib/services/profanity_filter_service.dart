import 'dart:convert';
import 'package:flutter/services.dart';

class ProfanityFilterService {
  List<String> _forbiddenWords = [];

  ProfanityFilterService() {
    _loadFilter();
  }

  Future<void> _loadFilter() async {
    final String response = await rootBundle.loadString('assets/lang/profanity_filter.json');
    final data = await json.decode(response);
    _forbiddenWords = List<String>.from(data['forbidden_words']);
  }

  bool isProfane(String text) {
    if (_forbiddenWords.isEmpty) {
      return false; // Filter not loaded yet
    }

    final lowercasedText = text.toLowerCase();
    for (final word in _forbiddenWords) {
      if (lowercasedText.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
