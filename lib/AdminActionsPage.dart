import 'package:flutter/material.dart';
import 'package:http/http.dart'; // For Web3 HTTP client
import 'package:web3dart/web3dart.dart';

import 'AuthenticationPage.dart';
import 'abi.dart';

class AdminActionsPage extends StatefulWidget {
  @override
  _AdminActionsPageState createState() => _AdminActionsPageState();
}

class _AdminActionsPageState extends State<AdminActionsPage> {
  List<Map<String, dynamic>> snails = [];

  // Add Snail details
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  late Web3Client ethClient;
  late Credentials credentials;
  late EthereumAddress userAddress;

  BigInt referralReward = BigInt.zero;

  final String rpcUrl = "http://localhost:8545";
  final EthereumAddress contractAddress =
      EthereumAddress.fromHex("0x44B8745F7a03d6E24E63A1c5C58F19c95B4c2815");

  late DeployedContract contract;

  @override
  void initState() {
    super.initState();
    ethClient = Web3Client(rpcUrl, Client());
    credentials = userCresentials; // Replace with user private key
    userAddress = credentials.address;
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "SnailMarket"),
      contractAddress,
    );
    fetchSnails();
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

  // Fetch snails from the smart contract
  void fetchSnails() async {
    final result = await callFunction("getAllSnails", []);

    final ids = result[0] as List<dynamic>;
    final names = result[1] as List<dynamic>;
    final prices = result[2] as List<dynamic>;
    final stocks = result[3] as List<dynamic>;
    print(result);
    List<Map<String, dynamic>> filteredSnails = [];
    for (int i = 0; i < names.length; i++) {
      if (names[i] != null && names[i].toString().isNotEmpty) {
        filteredSnails.add({
          'id': ids[i],
          'name': names[i],
          'price': prices[i],
          'stock': stocks[i],
        });
      }

      setState(() {
        snails = filteredSnails; // Update the state with filtered data
      });
    }
  }

  // Add Snail to the market
  void addSnail() async {
    final name = nameController.text;
    final price = BigInt.tryParse(priceController.text) ?? BigInt.zero;
    final stock = BigInt.tryParse(stockController.text) ?? BigInt.zero;
    final category = categoryController.text;

    if (name.isEmpty || category.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invalid input'),
          content: Text('Please provide valid details for all fields.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final result = await callFunction("getUserDetails", [userAddress]);
      bool isAdmin = result[3];
      if (isAdmin) {
        await submitTransaction("addSnail", [name, price, stock, category]);
        fetchSnails();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Invalid role'),
            content: Text('You must be an admin to perform this action.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error adding snail: $e");
    }
  }

  BigInt convertEtherToWei(String etherValue) {
    try {
      // Convert the string to a BigInt by parsing the string and scaling it by 18 decimal places
      final etherAmount = EtherAmount.fromUnitAndValue(
        EtherUnit.ether,
        BigInt.parse((double.parse(etherValue)).toString()),
      );
      return etherAmount.getInWei;
    } catch (e) {
      print("Error converting Ether to Wei: $e");
      return BigInt.zero;
    }
  }

  void showUpdateSnailDialog(BuildContext context, Map<String, dynamic> snail) {
    final TextEditingController nameController =
        TextEditingController(text: snail['name']);
    final TextEditingController priceController = TextEditingController(
      text: EtherAmount.fromUnitAndValue(EtherUnit.wei, snail['price'])
          .getValueInUnit(EtherUnit.ether)
          .toString(),
    );
    final TextEditingController stockController =
        TextEditingController(text: snail['stock'].toString());
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Snail"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Snail Name"),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: "Price in Ether"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: InputDecoration(labelText: "Stock"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: "Category"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                print(1);
                final priceInEther = (priceController.text);
                print(1);
                final price = convertEtherToWei(priceInEther);
                print(1);
                final stock =
                    BigInt.tryParse(stockController.text) ?? BigInt.zero;
                print(1);
                final category = categoryController.text;
                print(1);

                if (name.isEmpty ||
                    price <= BigInt.zero ||
                    stock <= BigInt.zero ||
                    category.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Invalid Input'),
                      content:
                          Text('All fields must be filled with valid values.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                try {
                  await submitTransaction(
                    "updateSnail",
                    [snail['id'], name, price, stock, category],
                  );
                  fetchSnails();
                  Navigator.pop(context);
                } catch (e) {
                  print("Error updating snail: $e");
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteSnail(BigInt snailId) async {
    try {
      await submitTransaction("deleteSnail", [snailId]);
      fetchSnails();
    } catch (e) {
      print("Error deleting snail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Actions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Snail Name"),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: InputDecoration(labelText: "Stock"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: "Category"),
            ),
            ElevatedButton(
              onPressed: addSnail,
              child: Text("Add Snail to Market"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: snails.length,
                itemBuilder: (context, index) {
                  final snail = snails[index];
                  return ListTile(
                    title: Text(snail['name']),
                    subtitle: Text(
                        "Price: ${EtherAmount.fromUnitAndValue(EtherUnit.wei, snail['price']).getValueInUnit(EtherUnit.ether)} ETH | Stock: ${snail['stock']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              showUpdateSnailDialog(context, snail);
                            }),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => deleteSnail(snail['id']),
                        ),
                      ],
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
