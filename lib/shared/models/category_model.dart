class CategoryModel {
  final String categoryId;
  final String categoryName;
  final int? parentId;

  const CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? 'Sin categoría',
      parentId: json['parent_id'] != null
          ? int.tryParse(json['parent_id'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'category_name': categoryName,
        'parent_id': parentId,
      };
}
