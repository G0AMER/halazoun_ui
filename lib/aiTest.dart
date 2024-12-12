import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _imageData;
  String? _result;

  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((e) async {
      final file = input.files!.first;
      final reader = html.FileReader();

      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        setState(() {
          _imageData = reader.result as Uint8List;
        });
      });
    });
  }

  Future<void> _classifyImage() async {
    if (_imageData == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:5000/predict'),
    );

    request.files.add(http.MultipartFile.fromBytes('file', _imageData!,
        filename: 'image.png'));
    final response = await request.send();
    print(response);
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);
      setState(() {
        var labels = [
          "Helix Aspersa Maxima Gros Gris",
          "Helix Aspersa Petit Gris",
          "escargo Morguet",
          "Helix aperta"
        ];
        _result = "You're searching for: ${labels[result['label']]}";
        print(result['label']);
      });
    } else {
      setState(() {
        _result = "Error: Unable to classify image.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snail Type Recognition'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_imageData != null)
                SizedBox(
                  width: screenWidth * 0.8,
                  // Adjust image width to 80% of screen width
                  height: screenHeight * 0.4,
                  // Adjust image height to 40% of screen height
                  child: Image.memory(
                    _imageData!,
                    fit: BoxFit.contain, // Ensure the image fits well
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Select an Image"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _classifyImage,
                child: const Text("What type of snail is this?"),
              ),
              if (_result != null) ...[
                const SizedBox(height: 20),
                Text(
                  _result!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
