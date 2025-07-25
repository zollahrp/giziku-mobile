class Simulation {
  final double budget;
  final int days;
  final int people;

  Simulation({
    required this.budget,
    required this.days,
    required this.people,
  });

  factory Simulation.fromJson(Map<String, dynamic> json) {
    return Simulation(
      budget: json['budget']?.toDouble() ?? 0.0,
      days: json['days'] ?? 0,
      people: json['people'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'days': days,
      'people': people,
    };
  }
}
