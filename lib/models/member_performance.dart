class MemberPerformance {
  final String userId;
  final String firstName;
  final String lastName;
  final double completionRate;
  final double onTimeRate;
  final int totalTasks;
  final int completedTasks;
  final int overdueTasks;

  MemberPerformance({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.completionRate,
    required this.onTimeRate,
    required this.totalTasks,
    required this.completedTasks,
    required this.overdueTasks,
  });

  String get fullName => '$firstName $lastName';
  
  // Performance score combines completion rate and on-time delivery
  double get performanceScore => (completionRate * 0.7) + (onTimeRate * 0.3);
}
