import 'package:flutter/material.dart';

class Folder {
  final int? id;
  final String name;
  final Color color;

  Folder({this.id, required this.name, required this.color});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color.value,
  };

  factory Folder.fromMap(Map<String, dynamic> map) => Folder(
    id: map['id'] as int?,
    name: map['name'] as String,
    color: Color(map['color'] as int),
  );
}
