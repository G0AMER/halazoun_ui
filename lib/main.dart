import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snail Market',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SnailMarketPage(),
    );
  }
}

String ipAdr = "127.0.0.1";

class SnailMarketPage extends StatefulWidget {
  @override
  _SnailMarketPageState createState() => _SnailMarketPageState();
}

class _SnailMarketPageState extends State<SnailMarketPage> {
  // Declare variables for storing data
  List<Map<String, dynamic>> snails = [];

  @override
  void initState() {
    super.initState();
    fetchSnails(); // Fetch snails data on page load
  }

  // Fetch snails data from Flask server
  Future<void> fetchSnails() async {
    Uri uri = Uri.parse('http://$ipAdr:5000/snails');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // Parse the response body
      List<dynamic> data = json.decode(response.body);
      setState(() {
        snails = data.map((snail) {
          return {
            'name': snail['name'],
            'price': snail['price'],
            'stock': snail['stock'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load snails');
    }
  }

  // Buy snails from the Flask server (initiates smart contract transaction)
  Future<void> buySnails(int snailId, int quantity, double price) async {
    final response = await http.post(
      Uri.parse('http://$ipAdr:5000/buy'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'snail_id': snailId,
        'quantity': quantity,
        'value': price,
      }),
    );

    if (response.statusCode == 200) {
      // Handle successful purchase
      print('Snail purchase successful!');
    } else {
      throw Exception('Failed to buy snails');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snail Market'),
      ),
      body: ListView.builder(
        itemCount: snails.length,
        itemBuilder: (context, index) {
          final snail = snails[index];
          return Card(
            child: ListTile(
              title: Text(snail['name']),
              subtitle: Text(
                  'Price: ${snail['price']} ETH\nStock: ${snail['stock']}'),
              trailing: IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () async {
                  // Prompt for quantity (could be a dialog, for now, default to 1)
                  int quantity = 1;
                  await buySnails(index, quantity, snail['price']);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
