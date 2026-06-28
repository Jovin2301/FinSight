String categoryEmoji(String category) {
  final lower = category.toLowerCase();

  if (lower.contains('food')) return '🍔';
  if (lower.contains('transport')) return '🚌';
  if (lower.contains('shop')) return '🛍️';
  if (lower.contains('bill') || lower.contains('util')) return '💡';
  if (lower.contains('entertainment')) return '🎬';
  if (lower.contains('health')) return '❤️';
  return '💰';
}
