const List<String> specialtiesList = [
  "Cardiologist",
  "Dermatologist",
  "Pediatrician",
  "Neurologist",
  "Psychiatrist",
  "Dentist",
  "Orthopedic",
  "Surgeon",
  "Ophthalmologist",
  "General Practitioner"
];

class Doctor {
  final String? id;
  final String name;
  final String specialty;
  final String imageUrl;
  final double? lat;
  final double? lng;
  final String? address;

  Doctor({
    this.id,
    required this.name,
    required this.specialty,
    required this.imageUrl,
    this.lat,
    this.lng,
    this.address,
  });

  factory Doctor.fromJson(Map<String, dynamic> json, String id) {
    return Doctor(
      id: id,
      name: json['name']?.toString() ?? 'No Name',
      specialty: json['specialty']?.toString() ?? 'No Specialty',
      imageUrl: json['imageUrl']?.toString() ?? 'https://via.placeholder.com/150',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialty': specialty,
      'imageUrl': imageUrl,
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}
