import 'dart:ui';

enum Categories {
  vegetables,
  meat,
  fruit,
  carbs,
  dairy,
  sweets,
  spices,
  convenience,
  hygiene,
  other,
}

class Category {
  final String name;
  final Color color;

  const Category(this.name, this.color);
}
