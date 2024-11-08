import 'package:flutter/material.dart';
import 'dart:math';
class Complaint {
  final String senter;
  final String title;
  final String description;
  final String date;
  String? status;
  bool isFlagged;
  // Map<String,String>? comments;
  final Color bgColor;
  final String id;
  bool chosen;

  Complaint({
    required this.senter,
    required this.title,
    required this.description,
    required this.date,
    required this.id,
    required this.isFlagged,
    // required this.comments,
    this.chosen = false,
    required this.bgColor,
    this.status = 'Mới',
  });
@override
 String toString() {
    return 'Complaint(id: $id, title: $title, description: $description, status: $status)';
  }
  /// Factory method để tạo Event từ tài liệu Firestore
  factory Complaint.fromFirestore(Map<String, dynamic> data, String documentId) {
    try {
       final List<Color> colorPalette = [
    const Color(0xffd69ca5),
    const Color(0xff94c8d4),
    const Color(0xffd696c0),
    const Color(0xffa6e9ed),
    const Color(0xff9ad29a),
    const Color(0xffcecccb)
  ];
  

      return Complaint(
        id: documentId,
        senter:data['senter']?['stringValue']??'',
        title: data['title']?['stringValue'] ?? '',
        description: data['description']?['stringValue'].replaceAll(r'\n', '\n') ?? '',
        isFlagged: data['isFlagged']?['booleanValue'] ?? false,
        status: data['status']?['stringValue'] ?? 'Mới',
        bgColor: colorPalette[Random().nextInt(colorPalette.length)],
        date: data['date']?['stringValue']??'',
        // comments: data['comments']??{},
      );
    } catch (e) {
      return Complaint(
        id: documentId,
        senter:'',
        title: 'Error',
        description: '',
        isFlagged:false,
        status:  'Mới',
        bgColor: Colors.red,
        date: '',
        // comments: data['comments']??{},
        
      );
    }
  }

  
  Map<String, dynamic> toFirestore() {
    return {
      'title': {'stringValue': title},
      'senter': {'stringValue':senter},
      'description': {'stringValue':description},
      'status': {'stringValue':status},
      'date': {'stringValue':date},
      'isFlagged':{'booleanValue':isFlagged}
      
    };
  }
}


