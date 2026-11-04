import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.description,
    super.order,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      icon: (json['icon'] ?? json['Icon'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '')
          .toString(),
      order: (json['order'] ?? json['Order'] ?? 0) as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'order': order,
    };
  }
}
