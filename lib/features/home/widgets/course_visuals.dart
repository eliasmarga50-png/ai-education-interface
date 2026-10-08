import 'package:flutter/material.dart';

/// Icon and color used for a course category on Home.
IconData courseCategoryIcon(String category) {
  switch (category) {
    case 'Programming':
      return Icons.code;
    case 'Design':
      return Icons.design_services_outlined;
    case 'AI':
      return Icons.psychology_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}

Color courseCategoryColor(String category) {
  switch (category) {
    case 'Programming':
      return const Color(0xFF4F46E5);
    case 'Design':
      return const Color(0xFFDB2777);
    case 'AI':
      return const Color(0xFF0284C7);
    default:
      return const Color(0xFF4F46E5);
  }
}