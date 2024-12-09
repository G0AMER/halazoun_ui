import 'package:flutter/material.dart';
import 'package:http/http.dart'; // For Web3 HTTP client
import 'package:web3dart/web3dart.dart';

import 'abi.dart';

void main() {
  runApp(MyApp());
}

bool isAdmin = false;

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

  Future<void> fetchSnails() async {
    final result = await callFunction("getAllSnails", []);
    print(result);
    final ids = result[0] as List<dynamic>;
    final names = result[1] as List<dynamic>;
    final prices = result[2] as List<dynamic>;
    final stocks = result[3] as List<dynamic>;

    String convertWeiToEther(BigInt weiValue) {
      final etherValue = EtherAmount.fromBigInt(EtherUnit.wei, weiValue)
          .getValueInUnit(EtherUnit.ether);
      return etherValue.toString();
    }

    setState(() {
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
      }
      snails = filteredSnails;
    });
  }

  void fetchOrders() async {
    try {
      // Fetch the order history from the user details (assuming userAddress is defined)
      final userDetails = await callFunction("getUserDetails", [userAddress]);
      print(userDetails);
      final orderHistory =
          userDetails[5] as List<dynamic>; // Assuming index 5 is orderHistory
      print(orderHistory);
      // Fetch each order's details
      List<Map<String, dynamic>> fetchedOrders = [];
      for (int i = 0; i < orderHistory.length; i++) {
        print(orderHistory[i]);
        final orderDetails =
            await callFunction("getOrderWithSnailDetails", [orderHistory[i]]);
        print(orderDetails);
        fetchedOrders.add({
          'orderId': orderDetails[0],
          'snailId': orderDetails[1],
          'quantity': orderDetails[2],
          'totalPrice':
              BigInt.from(orderDetails[3] as num).toString(), // Price in wei
          'timestamp': orderDetails[4],
          'snailName': orderDetails[5],
          'snailPrice':
              BigInt.from(orderDetails[6] as num).toString(), // Price in wei
          'snailStock': orderDetails[7],
          'snailCategory': orderDetails[8],
        });
      }

      // Update the state with the fetched orders
      setState(() {
        orders = fetchedOrders;
      });
    } catch (e) {
      print("Error fetching orders: $e");
      // Handle errors (e.g., user not registered or network issues)
    }
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
                          .getValueInUnit(EtherUnit.ether);
                  //.toStringAsFixed(4);
                  return ListTile(
                    title: Text("${snail['name']}"),
                    subtitle: Text(
                        "Price: ${priceInEther} ETH | Stock: ${snail['stock']}"),
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
              // Order History Tab
              ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final totalPriceInEther = EtherAmount.fromBigInt(
                          EtherUnit.wei, BigInt.parse(order['totalPrice']))
                      .getValueInUnit(EtherUnit.ether)
                      .toStringAsFixed(4);
                  final snailPriceInEther = EtherAmount.fromBigInt(
                          EtherUnit.wei, BigInt.parse(order['snailPrice']))
                      .getValueInUnit(EtherUnit.ether)
                      .toStringAsFixed(4);
                  final orderDate = DateTime.fromMillisecondsSinceEpoch(
                      order['timestamp'] * 1000);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order ID: ${order['orderId']}",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          SizedBox(height: 8.0),
                          Text("Snail Name: ${order['snailName']}"),
                          Text("Snail Category: ${order['snailCategory']}"),
                          Text("Snail ID: ${order['snailId']}"),
                          Text("Snail Price: $snailPriceInEther ETH"),
                          Text("Quantity: ${order['quantity']}"),
                          Text("Total Price: $totalPriceInEther ETH"),
                          Text("Remaining Stock: ${order['snailStock']}"),
                          SizedBox(height: 8.0),
                          Text("Order Date: ${orderDate.toLocal()}"),
                        ],
                      ),
                    ),
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
                      onPressed: () async {
                        final result =
                            await callFunction("getUserDetails", [userAddress]);
                        print(result);
                        isAdmin = result[3];
                        print(isAdmin);
                        if (isAdmin) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AdminActionsPage()),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Invalid role'),
                              content: Text(
                                  'You should be an admin to make this step.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        }
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
