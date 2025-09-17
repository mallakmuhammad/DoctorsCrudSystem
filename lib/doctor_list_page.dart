// 📁 lib/doctor_list_page.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';
import 'doctor_provider.dart';
import 'doctor_model.dart';

// Address Packages
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  String selectedFilter = "All"; // select filter default

  @override
  void initState() {
    super.initState(); // Load Doctors page once the page is opened.

    Future.microtask(
      () => Provider.of<DoctorProvider>(context, listen: false).fetchDoctors(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);

    final filteredDoctors = selectedFilter == "All"
        ? provider.doctors
        : provider.doctors.where((doc) => doc.specialty == selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🩺 Doctor Directory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.cyan],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedFilter,
                items: ["All", ...specialtiesList]
                    .map((spec) => DropdownMenuItem(value: spec, child: Text(spec)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Filter by Specialty',
                  prefixIcon: Icon(Icons.filter_list),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showDoctorForm(context);
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredDoctors.isEmpty
                    ? const Center(
                        child: Text(
                          "No Doctors Found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDoctors[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.9),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(backgroundImage: NetworkImage(doc.imageUrl), radius: 30),
                              title: Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Text(doc.specialty + (doc.address != null ? '\n${doc.address}' : ''), style: TextStyle(color: Colors.grey.shade600)),
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.deepOrange),
                                    onPressed: () => _showDoctorForm(context, doctor: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => Provider.of<DoctorProvider>(context, listen: false).deleteDoctor(doc.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------- Form (address editable + Find on Map + Pick on Map) ---------------------
  void _showDoctorForm(BuildContext context, {Doctor? doctor}) {
    final nameController = TextEditingController(text: doctor?.name ?? '');
    final addressController = TextEditingController(text: doctor?.address ?? '');

    // local lat/lng (not shown to user fields)
    double? selectedLat = doctor?.lat;
    double? selectedLng = doctor?.lng;

    String? selectedSpecialty = doctor?.specialty;
    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(doctor == null ? '➕ Add New Doctor' : '✏️ Edit Doctor', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 8),

                // Specialty
                DropdownButtonFormField<String>(
                  value: (selectedSpecialty != null && specialtiesList.contains(selectedSpecialty)) ? selectedSpecialty : null,
                  items: specialtiesList.map((spec) => DropdownMenuItem(value: spec, child: Text(spec))).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSpecialty = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Specialty', prefixIcon: Icon(Icons.medical_services)),
                ),
                const SizedBox(height: 8),

                // Address (editable)
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Clinic Address (optional)',
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Find on map (geocode)
                        IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Find on map',
                          onPressed: () async {
                            final addressText = addressController.text.trim();
                            if (addressText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an address first')));
                              return;
                            }
                            final coords = await geocodeAddress(addressText);
                            if (coords != null) {
                              selectedLat = coords.latitude;
                              selectedLng = coords.longitude;
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location found ✅')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address not found ❌')));
                            }
                          },
                        ),
                        // open map picker
                        IconButton(
                          icon: const Icon(Icons.map),
                          tooltip: 'Pick on map',
                          onPressed: () async {
                            final picked = await _showMapPicker(context, initialLat: selectedLat, initialLng: selectedLng);
                            if (picked != null) {
                              selectedLat = picked.latitude;
                              selectedLng = picked.longitude;
                              final address = await reverseGeocode(picked.latitude, picked.longitude);
                              setState(() {
                                addressController.text = address ?? addressController.text;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // small helper text to show if lat/lng are set (optional)
                if (selectedLat != null && selectedLng != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('Location set • Lat: ${selectedLat!.toStringAsFixed(5)}, Lng: ${selectedLng!.toStringAsFixed(5)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ),

                const SizedBox(height: 8),

                // Image Picker (web)
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: Text(selectedImageBytes == null ? 'Choose Image' : 'Image Selected'),
                  onPressed: () async {
                    final bytesFromPicker = await ImagePickerWeb.getImageAsBytes();
                    if (bytesFromPicker != null) {
                      setState(() {
                        selectedImageBytes = bytesFromPicker;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save'),
              onPressed: () async {
                // Validation
                if (nameController.text.isEmpty || selectedSpecialty == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }

                try {
                  final provider = Provider.of<DoctorProvider>(context, listen: false);

                  // Duplicate check (name + specialty)
                  final exists = provider.doctors.any((doc) =>
                      doc.name.toLowerCase().trim() == nameController.text.toLowerCase().trim() && doc.specialty == selectedSpecialty);

                  if (exists && doctor == null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Duplicate Doctor"),
                        content: const Text("This doctor already exists!"),
                        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))],
                      ),
                    );
                    return;
                  }

                  // upload image if selected
                  String imageUrl = doctor?.imageUrl ?? '';
                  if (selectedImageBytes != null) {
                    imageUrl = await uploadToCloudinary(selectedImageBytes!);
                  }
                  if (imageUrl.isEmpty) imageUrl = 'https://via.placeholder.com/150';

                  final newDoctor = Doctor(
                    id: doctor?.id,
                    name: nameController.text.trim(),
                    specialty: selectedSpecialty!,
                    imageUrl: imageUrl,
                    lat: selectedLat,
                    lng: selectedLng,
                    address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                  );

                  if (doctor == null) {
                    await provider.addDoctor(newDoctor);
                  } else {
                    await provider.updateDoctor(newDoctor);
                  }

                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  // ignore: avoid_print
                  print('🔥 Save error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving doctor.')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------- Map picker dialog ---------------------
  Future<LatLng?> _showMapPicker(BuildContext ctx, {double? initialLat, double? initialLng}) {
  final initial = LatLng(initialLat ?? 30.0444, initialLng ?? 31.2357); // Cairo default
  LatLng picked = initial;

  return showDialog<LatLng>(
    context: ctx,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pick location'),
            content: SizedBox(
              width: 700,
              height: 480,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: initial,
                  initialZoom: 13,
                  onTap: (tapPos, latlng) {
                    setState(() {
                      picked = latlng;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: picked,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, picked), child: const Text('Select')),
            ],
          );
        },
      );
    },
  );
}


  // --------------------- Reverse geocode (optional) ---------------------
  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1');
      final resp = await http.get(url, headers: {'User-Agent': 'DoctorsCRUDApp/1.0 (your@email.com)'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return data['display_name'] as String?;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Reverse geocode error: $e');
    }
    return null;
  }

  // --------------------- Geocode (address -> LatLng) ---------------------
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1');
      final resp = await http.get(url, headers: {'User-Agent': 'DoctorsCRUDApp/1.0 (your@email.com)'});
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Geocode error: $e');
    }
    return null;
  }

  // --------------------- Cloudinary upload (unchanged) ---------------------
  Future<String> uploadToCloudinary(Uint8List imageBytes) async {
    const cloudName = 'dofcskb0c';
    const uploadPreset = 'Malak191332';

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'doctor.jpg'));

    final response = await request.send();
    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = json.decode(res.body);
      return data['secure_url'];
    } else {
      throw Exception('Cloudinary upload failed');
    }
  }
}
