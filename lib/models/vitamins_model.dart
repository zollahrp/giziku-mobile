class VitaminsModel {
  final String vitaminA;
  final String vitaminC;
  final String iron;

  VitaminsModel({
    required this.vitaminA,
    required this.vitaminC,
    required this.iron,
  });

  factory VitaminsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return VitaminsModel(
      vitaminA: json['vitaminA'] ?? '',
      vitaminC: json['vitaminC'] ?? '',
      iron: json['iron'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'iron': iron,
    };
  }
}