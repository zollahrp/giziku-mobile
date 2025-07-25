class ProductModel {
  final String? id; 
  final String title;
  final String description;
  final double price;
  final String storeName;
  final ProductLocation location;
  final String imageUrl;
  final String expiredDate;

  ProductModel({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.storeName,
    required this.location,
    required this.imageUrl,
    required this.expiredDate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      storeName: json['store_name'] ?? '',
      location: ProductLocation.fromJson(json['location']),
      imageUrl: json['image_url'] ?? '',
      expiredDate: json['expired_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'store_name': storeName,
      'location': location.toJson(),
      'image_url': imageUrl,
      'expired_date': expiredDate,
    };
  }
}

class ProductLocation {
  final double latitude;
  final double longitude;
  final String address;

  ProductLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory ProductLocation.fromJson(Map<String, dynamic> json) {
    return ProductLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}