import 'package:flutter/material.dart';
import 'package:http/http.dart'; // For Web3 HTTP client
import 'package:web3dart/web3dart.dart';

import 'SnailMarketPage.dart';
import 'abi.dart';
import 'main.dart';

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

late Credentials userCresentials;

class _AuthenticationPageState extends State<AuthenticationPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController referrerController = TextEditingController();
  late Web3Client ethClient;
  late Credentials credentials;
  late EthereumAddress userAddress;
  late EthereumAddress ownerAddress;
  final String rpcUrl = "http://localhost:8545";
  final EthereumAddress contractAddress =
      EthereumAddress.fromHex("0x44B8745F7a03d6E24E63A1c5C58F19c95B4c2815");
  late DeployedContract contract;
  final String privateKey =
      "0x6008f0635c53409391e87ffaa944a7f01f0b3a645f84b012e3f42c21cd0b7275";

  @override
  void initState() {
    super.initState();
    ethClient = Web3Client(rpcUrl, Client());
    credentials = EthPrivateKey.fromHex(privateKey);
    ownerAddress = credentials.address;
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "SnailMarket"),
      contractAddress,
    );
  }

  Future<void> loginUser() async {
    final name = nameController.text;
    final password = passwordController.text;

    if (name.isEmpty || password.isEmpty) {
      showError("Please fill in both fields.");
      return;
    }

    final result = await callFunction("authenticateUser", [name, password]);
    print(result);
    userAddress = EthereumAddress.fromHex(result[1].toString());
    print(1);
    final userDetails = await callFunction("getUserDetails", [userAddress]);
    print(userDetails);
    isAdmin = userDetails[3];
    userCresentials = EthPrivateKey.fromHex(userDetails[2]);
    print(userCresentials);
    print(isAdmin);
    if (result[0]) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SnailMarketPage()),
      );
    } else {
      showError("Invalid login credentials.");
    }
  }

  Future<void> registerUser() async {
    final name = nameController.text;
    final address = addressController.text;
    final password = passwordController.text;
    final referrerAddress = referrerController.text;

    if (name.isEmpty || address.isEmpty || password.isEmpty) {
      showError("Please fill in all fields.");
      return;
    }

    userAddress = EthereumAddress.fromHex(address);
    final referrer = referrerAddress.isNotEmpty
        ? EthereumAddress.fromHex(referrerAddress)
        : EthereumAddress.fromHex("0x0000000000000000000000000000000000000000");
    credentials = EthPrivateKey.fromHex(privateKeyController.text);
    final result = await submitTransaction("registerUser", [
      name,
      password,
      EthereumAddress.fromHex(address),
      privateKeyController.text,
      referrer,
      false
    ]);

    showSuccess("Registration successful");
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
    );
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Authentication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: loginUser,
              child: Text("Login"),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: "Ethereum Address"),
            ),
            TextField(
              controller: privateKeyController,
              decoration: InputDecoration(labelText: "Private Key"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: registerUser,
              child: Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
