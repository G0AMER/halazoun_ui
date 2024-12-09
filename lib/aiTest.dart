import 'dart:typed_data'; // For handling binary data

import 'package:flutter/material.dart';
import 'package:image/image.dart'
    as img; // Add this package for image manipulation
import 'package:image_picker/image_picker.dart'; // Image picker package for web and mobile
import 'package:tflite/tflite.dart'; // TensorFlow Lite dependency for Flutter

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escargot Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Uint8List? _imageData; // Holds the image bytes
  String _result = 'No classification yet';

  // Initialize the TFLite model
  Future<void> loadModel() async {
    try {
      print("Loading model...");
      await Tflite.loadModel(
        model: 'assets/escargot_classifier.tflite',
      );
      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _result = 'Failed to load model';
      });
    }
  }

  Future<void> classifyImage(Uint8List imageBytes) async {
    // Decode the image to manipulate it
    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image != null) {
      // Resize the image to the required input size (e.g., 224x224 for many models)
      image = img.copyResize(image, width: 224, height: 224);

      // Convert the image to a byte array that TensorFlow Lite can process
      var input = image.getBytes();

      print("Running model on image...");

      // Run the model on the preprocessed image
      var recognitions = await Tflite.runModelOnBinary(
        binary: input,
      );

      // Debugging output for recognitions
      print("Recognition result: $recognitions");

      if (recognitions != null && recognitions.isNotEmpty) {
        setState(() {
          _result = recognitions[0]['label'] ?? 'No classification';
        });
      } else {
        setState(() {
          _result = 'Could not classify the image';
        });
      }
    } else {
      setState(() {
        _result = 'Image decoding failed';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel(); // Load the TFLite model when the app starts
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes(); // Convert file to bytes
        setState(() {
          _imageData = bytes;
          _result = 'Classifying...'; // Indicate classification is in progress
        });
        await classifyImage(bytes); // Classify the selected image
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No image selected')));
      }
    } catch (e) {
      print("Error picking image: $e");
      setState(() {
        _result = 'Failed to pick image';
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close(); // Close the TFLite model when the widget is disposed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escargot Classifier'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageData != null
                ? Image.memory(
                    _imageData!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                : Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            Text(
              _result,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
