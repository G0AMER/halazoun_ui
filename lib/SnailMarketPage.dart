import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart'; // For Web3 HTTP client
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import 'AdminActionsPage.dart';
import 'AuthenticationPage.dart';
import 'abi.dart';
import 'main.dart';

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
      loadOrdersFromLocal();
      print(snails);
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
    try {
      // Find the snail details in the app's local `snails` list
      final snail = snails.firstWhere((snail) => snail['id'] == snailId);
      final pricePerSnail = BigInt.parse(snail['price'].toString());
      final totalPrice = pricePerSnail * quantity;

      // Calculate value to be sent in the transaction
      final value = EtherAmount.fromBigInt(EtherUnit.wei, totalPrice);

      // Submit the transaction to the blockchain
      final txHash = await submitTransaction("buySnails", [snailId, quantity],
          value: value);
      print("Transaction successful: $txHash");

      // Update the local stock for the snail
      setState(() {
        snail['stock'] = snail['stock'] - quantity;
      });

      // Create a new order entry locally
      final newOrder = {
        'userCred': credentials.address.toString(),
        'orderId': DateTime.now().millisecondsSinceEpoch, // Generate a local ID
        'snailId': snailId.toString(),
        'snailName': snail['name'],
        'quantity': quantity.toString(),
        'totalPrice': totalPrice.toString(),
        'timestamp': DateTime.now().toIso8601String(), // Save as an integer
      };

      // Update the local orders list
      setState(() {
        orders.add(newOrder);
      });

      // Save the updated orders list to SharedPreferences
      await saveOrdersToLocal();

      print("Order added successfully and saved locally: $newOrder");
    } catch (e) {
      print("Error in buySnail: $e");
    }
  }

  Future<void> saveOrdersToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert orders list to JSON string
      final ordersJson = jsonEncode(orders);
      await prefs.setString('orders', ordersJson);
      print("Orders saved to SharedPreferences.");
    } catch (e) {
      print("Error saving orders: $e");
    }
  }

  Future<void> loadOrdersFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load the JSON string from SharedPreferences
      final ordersJson = prefs.getString('orders');
      if (ordersJson != null) {
        // Decode the JSON string back to a list
        final loadedOrders = jsonDecode(ordersJson) as List<dynamic>;
        print(loadedOrders);
        // Filter orders to include only those with matching `userCred`
        final userOrders = loadedOrders
            .cast<Map<String, dynamic>>()
            .where(
                (order) => order['userCred'] == credentials.address.toString())
            .toList();

        setState(() {
          orders = userOrders;
        });

        print("Filtered orders loaded from SharedPreferences.");
      } else {
        print("No orders found in SharedPreferences.");
      }
    } catch (e) {
      print("Error loading orders: $e");
    }
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

  void _logout() {
    // Clear user session or any necessary data
    // For example, if you are using SharedPreferences to store user info:
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('userAddress'); // Remove any stored user information
      prefs.remove('isAdmin');
    });

    // Optionally navigate to a login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthenticationPage()),
    );
  }

  String userName = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Snail Market"),
            bottom: TabBar(
              tabs: [
                Tab(text: "Market"),
                Tab(text: "Orders"),
                Tab(text: "Profile"),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  // Perform logout functionality here
                  // For example, clear user session or navigate to login screen
                  _logout();
                },
              ),
            ],
          ),
          body: TabBarView(
            children: [
              // Snail Market Tab
              ListView.builder(
                itemCount: snails.length,
                itemBuilder: (context, index) {
                  final snail = snails[index];
                  final priceInEther = EtherAmount.fromBigInt(EtherUnit.wei,
                          BigInt.parse(snail['price'].toString()))
                      .getValueInUnit(EtherUnit.ether)
                      .toStringAsFixed(4);

                  // Convert BigInt stock to int
                  final stock = BigInt.parse(snail['stock'].toString()).toInt();

                  // Variable to store the selected quantity for this snail
                  int selectedQuantity = 1;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${snail['name']}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0),
                              ),
                              Text("Price: $priceInEther ETH"),
                              Text("Stock: $stock"),

                              // Quantity Selection with + and - Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text("Quantity: "),
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      setState(() {
                                        if (selectedQuantity > 1) {
                                          selectedQuantity--;
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    "$selectedQuantity",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      setState(() {
                                        if (selectedQuantity < stock) {
                                          selectedQuantity++;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),

                              SizedBox(height: 8.0),

                              // Buy Button
                              ElevatedButton(
                                onPressed: () {
                                  if (selectedQuantity > stock) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          "Selected quantity exceeds available stock!"),
                                    ));
                                  } else {
                                    buySnail(
                                        BigInt.parse(snail['id'].toString()),
                                        BigInt.from(selectedQuantity));
                                  }
                                },
                                child: Text("Buy"),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Order History Tab
              // Order History Tab
              ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];

                  // Ensure all required fields exist in the order
                  final totalPriceInEther = EtherAmount.fromBigInt(
                          EtherUnit.wei,
                          BigInt.parse(order['totalPrice'].toString()))
                      .getValueInUnit(EtherUnit.ether)
                      .toStringAsFixed(4);
                  /*final snailPriceInEther = EtherAmount.fromBigInt(
                          EtherUnit.wei,
                          BigInt.parse(order['snailPrice'].toString()))
                      .getValueInUnit(EtherUnit.ether)
                      .toStringAsFixed(4);*/
                  print(111);
                  print("Timestamp value: ${order['timestamp']}");
                  final orderDate = order['timestamp'].toString();
                  print(111);
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
                          Text(
                              "Snail Name: ${order['snailName'] ?? 'Unknown'}"),
                          Text("Snail ID: ${order['snailId']}"),
                          //Text("Snail Price: $snailPriceInEther ETH"),
                          Text("Quantity: ${order['quantity']}"),
                          Text("Total Price: $totalPriceInEther ETH"),
                          /*Text(
                              "Remaining Stock: ${order['snailStock'] ?? 'Unknown'}"),*/
                          SizedBox(height: 8.0),
                          Text("Order Date: ${orderDate.toString()}"),
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
                    // User Profile Information

                    SizedBox(height: 16.0),
                    Text(
                      "Name: $userName", // Display the user's name
                      style: TextStyle(
                          fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      "Role: ${isAdmin ? 'Admin' : 'User'}",
                      // Determine and display the user's role
                      style: TextStyle(
                        fontSize: 18.0,
                        color: isAdmin ? Colors.blue : Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      "Address: $userAddress",
                      style: TextStyle(fontSize: 16.0),
                    ),

                    SizedBox(height: 16.0),

                    // Admin Actions Button
                    if (isAdmin)
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final result = await callFunction(
                                "getUserDetails", [userAddress]);
                            print(result);
                            isAdmin = result[3]; // Update the admin role flag
                            userName = result[
                                0]; // Assuming the user's name is at index 0
                            print("Name: $userName, Admin: $isAdmin");

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
                          } catch (e) {
                            print("Error checking admin role: $e");
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
