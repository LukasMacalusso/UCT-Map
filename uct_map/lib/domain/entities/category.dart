/// Categoría utilizada por salas y estructuras.
class Category {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.order = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      icon: (json['icon'] ?? json['Icon'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      order: (json['order'] ?? json['Order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'description': description,
    'order': order,
  };
}
