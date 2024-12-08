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
      home: AuthenticationPage(),
    );
  }
}

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController referrerController = TextEditingController();
  late Web3Client ethClient;
  late Credentials credentials;
  late EthereumAddress userAddress;
  late EthereumAddress ownerAddress;
  final String rpcUrl = "http://localhost:8545";
  final EthereumAddress contractAddress =
      EthereumAddress.fromHex("0x40a6fC69572Acbb19eADd2f612fDaE660C3fdf04");
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

    final result = await submitTransaction("registerUser",
        [name, password, EthereumAddress.fromHex(address), referrer]);

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
              decoration: InputDecoration(labelText: "name"),
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
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: referrerController,
              decoration:
                  InputDecoration(labelText: "Referrer Address (Optional)"),
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

class SnailMarketPage extends StatefulWidget {
  @override
  _SnailMarketPageState createState() => _SnailMarketPageState();
}

// Rest of the SnailMarketPage code remains the same...

// Rest of the SnailMarketPage code remains the same...

class _SnailMarketPageState extends State<SnailMarketPage> {
  late Web3Client ethClient;
  late Credentials credentials;
  late EthereumAddress userAddress;

  List<Map<String, dynamic>> snails = [];
  List<Map<String, dynamic>> orders = [];
  BigInt referralReward = BigInt.zero;

  final String rpcUrl = "http://localhost:8545";
  final EthereumAddress contractAddress =
      EthereumAddress.fromHex("0x92d1F5F97B41a8cf784dEA4cd88fD663C7B3056E");

  late DeployedContract contract;

  @override
  void initState() {
    super.initState();
    ethClient = Web3Client(rpcUrl, Client());
    credentials = EthPrivateKey.fromHex(
        "0x6008f0635c53409391e87ffaa944a7f01f0b3a645f84b012e3f42c21cd0b7275"); // Replace with user private key
    userAddress = credentials.address;
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "SnailMarket"),
      contractAddress,
    );
    fetchSnails();
    fetchOrders();
    fetchReferralReward();
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

  void fetchSnails() async {
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
  }

  void fetchOrders() async {
    final result = await callFunction("getOrderHistory", [userAddress]);
    final orderIds = result[0] as List<dynamic>;
    final snailIds = result[1] as List<dynamic>;
    final quantities = result[2] as List<dynamic>;
    final totalPrices = result[3] as List<dynamic>;

    setState(() {
      orders = List.generate(orderIds.length, (index) {
        return {
          'orderId': orderIds[index],
          'snailId': snailIds[index],
          'quantity': quantities[index],
          'totalPrice': totalPrices[index],
        };
      });
    });
  }

  void fetchReferralReward() async {
    final result = await callFunction("getReferralReward", [userAddress]);
    setState(() {
      referralReward = result[0];
    });
  }

  void buySnail(BigInt snailId, BigInt quantity) async {
    final valueInWei =
        snails.firstWhere((snail) => snail['id'] == snailId)['price'] *
            quantity;
    final value = EtherAmount.fromBigInt(EtherUnit.wei, valueInWei);

    final txHash =
        await submitTransaction("buySnails", [snailId, quantity], value: value);
    print("Transaction successful: $txHash");

    fetchOrders(); // Refresh order history
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Snail Market")),
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Snail Market"),
            bottom: TabBar(
              tabs: [
                Tab(text: "Market"),
                Tab(text: "Orders"),
                Tab(text: "Referral"),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Snail Market Tab
              ListView.builder(
                itemCount: snails.length,
                itemBuilder: (context, index) {
                  final snail = snails[index];
                  final priceInEther =
                      EtherAmount.fromBigInt(EtherUnit.wei, snail['price'])
                          .getValueInUnit(EtherUnit.ether)
                          .toStringAsFixed(4);
                  return ListTile(
                    title: Text("${snail['name']}"),
                    subtitle: Text(
                        "Price: $priceInEther ETH | Stock: ${snail['stock']}"),
                    trailing: ElevatedButton(
                      onPressed: () {
                        buySnail(snail['id'], BigInt.one);
                      },
                      child: Text("Buy"),
                    ),
                  );
                },
              ),
              // Order History Tab
              ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text("Order #${order['orderId']}"),
                    subtitle: Text(
                        "Snail ID: ${order['snailId']} | Quantity: ${order['quantity']} | Total: ${order['totalPrice']} ETH"),
                  );
                },
              ),
              // Referral Rewards Tab
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Referral Reward: $referralReward ETH"),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminActionsPage()),
                        );
                      },
                      child: Text("Admin Actions"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminActionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Actions")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Add functionality for adding snails or managing market
          },
          child: Text("Add Snail to Market"),
        ),
      ),
    );
  }
}
