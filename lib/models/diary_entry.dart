import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;
  final List<String> mediaUrls;
  final int emotionalRating; // 1-5 scale: 1=Very Happy, 2=Happy, 3=Neutral, 4=Sad, 5=Very Sad
  final DateTime createdAt;
  final String userId;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? weather;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.tags,
    required this.mediaUrls,
    this.emotionalRating = 3, // Default to neutral
    required this.createdAt,
    required this.userId,
    this.location,
    this.weather,
  });

  // Copy with method for creating modified copies
  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? date,
    List<String>? tags,
    List<String>? mediaUrls,
    int? emotionalRating,
    DateTime? createdAt,
    String? userId,
    Map<String, dynamic>? location,
    Map<String, dynamic>? weather,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      emotionalRating: emotionalRating ?? this.emotionalRating,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      weather: weather ?? this.weather,
    );
  }

  factory DiaryEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data() ?? {};
    return DiaryEntry(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      mediaUrls: (data['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      emotionalRating: data['emotionalRating']?.toInt() ?? 3,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId']?.toString() ?? '',
      location: data['location'] as Map<String, dynamic>?,
      weather: data['weather'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'tags': tags,
      'mediaUrls': mediaUrls,
      'emotionalRating': emotionalRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'location': location,
      'weather': weather,
    };
  }
}