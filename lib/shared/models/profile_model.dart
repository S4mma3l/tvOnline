import 'package:flutter/material.dart';

class ProfileModel {
  static const List<int> avatarColors = [
    0xFF1E88E5, // azul
    0xFFE53935, // rojo
    0xFF8E24AA, // morado
    0xFF00897B, // verde azulado
    0xFF43A047, // verde
    0xFFFB8C00, // naranja
    0xFF6D4C41, // café
    0xFF546E7A, // gris azulado
  ];

  final String id;
  final String name;
  final int colorIndex;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.colorIndex,
  });

  Color get color => Color(avatarColors[colorIndex % avatarColors.length]);

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
        id: j['id'] as String,
        name: j['name'] as String,
        colorIndex: j['colorIndex'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
      };

  ProfileModel copyWith({String? name, int? colorIndex}) => ProfileModel(
        id: id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
      );
}
