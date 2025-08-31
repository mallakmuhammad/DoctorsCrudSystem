// 📁 doctor_list_page.dart
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker_web/image_picker_web.dart';
import 'doctor_provider.dart';
import 'doctor_model.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<DoctorProvider>(context, listen: false).fetchDoctors(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.doctors.length,
                  itemBuilder: (context, index) {
                    final doc = provider.doctors[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(doc.imageUrl),
                          radius: 30,
                        ),
                        title: Text(
                          doc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          doc.specialty,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.deepOrange,
                              ),
                              onPressed:
                                  () => _showDoctorForm(context, doctor: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => provider.deleteDoctor(doc.id!),
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

  void _showDoctorForm(BuildContext context, {Doctor? doctor}) {
    final nameController = TextEditingController(text: doctor?.name ?? '');
    final specialtyController = TextEditingController(
      text: doctor?.specialty ?? '',
    );
    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    doctor == null ? '➕ Add New Doctor' : '✏️ Edit Doctor',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: specialtyController,
                          decoration: const InputDecoration(
                            labelText: 'Specialty',
                            prefixIcon: Icon(Icons.medical_services),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload),
                          label: Text(
                            selectedImageBytes == null
                                ? 'Choose Image'
                                : 'Image Selected',
                          ),
                          onPressed: () async {
                            final bytesFromPicker =
                                await ImagePickerWeb.getImageAsBytes();
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
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            specialtyController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields'),
                            ),
                          );
                          return;
                        }
                        try {
                          String imageUrl = doctor?.imageUrl ?? '';
                          if (selectedImageBytes != null) {
                            imageUrl = await uploadToCloudinary(
                              selectedImageBytes!,
                            );
                          }

                          final newDoctor = Doctor(
                            id: doctor?.id,
                            name: nameController.text,
                            specialty: specialtyController.text,
                            imageUrl: imageUrl,
                          );

                          if (doctor == null) {
                            await Provider.of<DoctorProvider>(
                              context,
                              listen: false,
                            ).addDoctor(newDoctor);
                          } else {
                            await Provider.of<DoctorProvider>(
                              context,
                              listen: false,
                            ).updateDoctor(newDoctor);
                          }

                          Navigator.pop(context);
                        } catch (e) {
                          print('🔥 Upload error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error saving doctor.'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<String> uploadToCloudinary(Uint8List imageBytes) async {
    const cloudName = 'dofcskb0c';
    const uploadPreset = 'Malak191332';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              imageBytes,
              filename: 'doctor.jpg',
            ),
          );

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
