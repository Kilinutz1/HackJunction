class Event {
  final String id;
  final String type; // "proud", "memory", "else"
  final String? pictureUrl; // Can be a local path or a cloud URL (nullable)
  final String description;
  final DateTime date;
  final bool isFavorite;

  Event({
    required this.id,
    required this.type,
    this.pictureUrl,
    required this.description,
    required this.date,
    this.isFavorite = false,
  });

  // Converts your object into a JSON dictionary to save to the database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'pictureUrl': pictureUrl,
      'description': description,
      'date': date.toIso8601String(), // Always save dates as standard text strings
      'isFavorite': isFavorite,
    };
  }

  // Converts the JSON dictionary from the database back into a Flutter object
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      type: json['type'],
      pictureUrl: json['pictureUrl'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}