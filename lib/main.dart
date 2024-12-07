import 'package:flutter/material.dart';
import 'package:http/http.dart'; // For Web3 HTTP client
import 'package:web3dart/web3dart.dart';

import 'abi.dart';

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
      home: SnailMarketApp(),
    );
  }
}

class SnailMarketApp extends StatefulWidget {
  @override
  _SnailMarketAppState createState() => _SnailMarketAppState();
}

class _SnailMarketAppState extends State<SnailMarketApp> {
  late Web3Client ethClient;
  late Credentials credentials;
  late EthereumAddress ownerAddress;

  final String rpcUrl = "http://localhost:8545";
  final String privateKey =
      "0x50702c8302aecf919bc59c0036a4b507ab205ba9ed4a65aa8be9b04632035c06"; // Replace with your private key
  final EthereumAddress contractAddress =
      EthereumAddress.fromHex("0x5Fdb4C78E3506d461d7C9B927477aD3379D164f3");

  late DeployedContract contract;

  List<Map<String, dynamic>> snails = [];

  @override
  void initState() {
    super.initState();
    initializeClient();
    fetchAllSnails();
  }

  void initializeClient() {
    ethClient = Web3Client(rpcUrl, Client());
    credentials = EthPrivateKey.fromHex(privateKey);
    ownerAddress = credentials.address;
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "SnailMarket"),
      contractAddress,
    );
  }

  Future<List<dynamic>> callFunction(
      String functionName, List<dynamic> args) async {
    final function = contract.function(functionName);
    return await ethClient.call(
      contract: contract,
      function: function,
      params: args,
    );
  }

  Future<String> submitTransaction(String functionName, List<dynamic> args,
      {EtherAmount? value}) async {
    final function = contract.function(functionName);
    final transaction = Transaction.callContract(
      contract: contract,
      function: function,
      parameters: args,
      value: value,
    );

    return await ethClient.sendTransaction(
      credentials,
      transaction,
      chainId: 1337,
      // Replace with your blockchain's chain ID if needed
    );
  }

  void fetchAllSnails() async {
    try {
      final result = await callFunction("getAllSnails", []);
      final ids = result[0] as List<dynamic>;
      final names = result[1] as List<dynamic>;
      final prices = result[2] as List<dynamic>;
      final stocks = result[3] as List<dynamic>;

      setState(() {
        snails = List.generate(ids.length, (index) {
          return {
            'id': ids[index],
            'name': names[index],
            'price': prices[index],
            'stock': stocks[index],
          };
        });
      });
    } catch (e) {
      print("Error fetching snails: $e");
    }
  }

  void addSnail(String name, BigInt price, BigInt stock) async {
    try {
      final txHash = await submitTransaction("addSnail", [name, price, stock]);
      print("Transaction successful: $txHash");
      fetchAllSnails(); // Refresh the list
    } catch (e) {
      print("Error adding snail: $e");
    }
  }

  void buySnail(BigInt snailId, BigInt quantity, BigInt valueInWei) async {
    try {
      final value = EtherAmount.fromBigInt(EtherUnit.wei, valueInWei);
      final txHash = await submitTransaction("buySnails", [snailId, quantity],
          value: value);
      print("Transaction successful: $txHash");
      fetchAllSnails(); // Refresh the list
    } catch (e) {
      print("Error buying snails: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController stockController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text("Snail Market")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Snail Section
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Snail Name"),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Snail Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: InputDecoration(labelText: "Snail Stock"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final price =
                    BigInt.tryParse(priceController.text) ?? BigInt.zero;
                final stock =
                    BigInt.tryParse(stockController.text) ?? BigInt.zero;

                if (name.isEmpty ||
                    price == BigInt.zero ||
                    stock == BigInt.zero) {
                  print("Invalid inputs");
                  return;
                }
                addSnail(name, price, stock);
              },
              child: Text("Add Snail"),
            ),
            Divider(),
            // Snail List Section
            Expanded(
              child: ListView.builder(
                itemCount: snails.length,
                itemBuilder: (context, index) {
                  final snail = snails[index];

                  // Convert price from Wei to Ether
                  final priceInEther =
                      EtherAmount.fromBigInt(EtherUnit.wei, snail['price'])
                          .getValueInUnit(EtherUnit.ether)
                          .toStringAsFixed(
                              4); // Limit to 4 decimal places for readability

                  return Card(
                    child: ListTile(
                      title: Text("${snail['name']}"),
                      subtitle: Text(
                          "Price: $priceInEther ETH | Stock: ${snail['stock']}"),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final valueInWei = snail['price'] as BigInt;
                          buySnail(snail['id'], BigInt.one, valueInWei);
                        },
                        child: Text("Buy"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
