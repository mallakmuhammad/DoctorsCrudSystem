import 'package:flutter/material.dart';
// Import -- Provides all the pre-built UI components

//Firebase Setup
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

//Linking Doctor Provider and Doctor List Pages 
import 'doctor_provider.dart';
import 'doctor_list_page.dart';
void main() async {
  // Flutter Entry Point

  WidgetsFlutterBinding.ensureInitialized();
  //Ensures that Flutter is fully set up before initializing Firebase.

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //Waiting for the firebase to setup and intialized,
  //Prevents the app from trying to use Firebase services before they’re ready.
  //Firebase.initializeApp-- initializes the connection between the app and the Firebase backend.
  //DefaultFirebaseOptions-- Dart class with static configuration settings for Firebase.
  //currentPlatform-- Each platform has different Firebase credentials. This line automatically chooses the right one.

  runApp(
    ChangeNotifierProvider(
      create: (_) => DoctorProvider(),
      child: const MyApp(),
    ),
  );
}
// Crucial for setting up state management in Flutter app using the "Provider package"
// runApp-- launches the Flutter app.
// ChangeNotifierProvider-- Provides a data model that can notify listeners.
//create: (_) => DoctorProvider()--	Creates and shares the DoctorProvider.


//Defining "My App" custom widget phase
class MyApp extends StatelessWidget {

//Constructing "My App" widget
  const MyApp({super.key});

  @override //Catching errors

  //Describing the UI that the widget will render
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doctors Database',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DoctorListPage(),

    );
  }
}


