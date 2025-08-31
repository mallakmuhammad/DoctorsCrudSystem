import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'doctor_provider.dart';

class DoctorListPage extends StatelessWidget {
  const DoctorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Doctors')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
            },
            child: const Text('Add Doctor'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.doctors.length,
              itemBuilder: (context, index) {
                final doc = provider.doctors[index];
                return ListTile(
                  leading: Image.network(
                    doc.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(doc.name),
                  subtitle: Text(doc.specialty),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          provider.deleteDoctor(doc.id!);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
