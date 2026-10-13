class TaskModel {
  final int? id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final DateTime dueDate;
  final bool isCompleted;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDate,
    this.isCompleted = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['is_completed'];
    final bool completed = rawCompleted == true || rawCompleted.toString() == '1';

    return TaskModel(
      id: int.tryParse(json['id']?.toString() ?? ''),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'Homework').toString(),
      priority: (json['priority'] ?? 'Medium').toString(),
      dueDate: DateTime.tryParse((json['due_date'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      isCompleted: completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'due_date': dueDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }
}
