import 'package:flutter/material.dart';
import '../config.dart'; // Import config file
import 'package:g14_indoor_locator/server/database_service.dart';

class EditUserPage extends StatefulWidget {
  final String id; // User ID
  final String name;
  final String email;
  final String house; // This is the house name from DB
  final String userType; // Admin or User

  const EditUserPage({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.house,
    required this.userType,
  });

  @override
  _EditUserPageState createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late String userType;
  late TextEditingController nameController;
  late TextEditingController emailController;
  String? selectedHouseId; // Store house ID
  bool isSaved = false;
  bool hasChanges = false;

  List<Map<String, String>> houseOptions = []; // Store house ID and name

  @override
  void initState() {
    super.initState();
    userType = widget.userType;
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);

    _loadHouseOptions(); // Load house options from MariaDB
  }

  Future<void> _loadHouseOptions() async {
    try {
      final houses = await DatabaseService.fetchHouses(); // Fetch houses from MariaDB
      setState(() {
        houseOptions = houses.map((house) => {
          'id': house['id'].toString(), // Store house ID as String
          'name': house['name'].toString() // Store house name
        }).toList();

        // Convert house name to corresponding ID
        final matchedHouse = houseOptions.firstWhere(
          (house) => house['name'] == widget.house, // Match house name
          orElse: () => {'id': '', 'name': ''}
        );

        selectedHouseId = matchedHouse['id']!.isNotEmpty ? matchedHouse['id'] : null; // Store the house ID
      });
    } catch (e) {
      print("[ERROR] Failed to load house options: $e");
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return emailRegex.hasMatch(email);
  }

  bool isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return name.isNotEmpty && nameRegex.hasMatch(name);
  }

  void trackChanges() {
    setState(() {
      hasChanges = userType != widget.userType ||
          nameController.text != widget.name ||
          emailController.text != widget.email ||
          selectedHouseId != widget.house;
    });
  }

  Future<void> _validateAndSave() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty || selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Convert selectedHouseId (String) to int
    int? houseId = int.tryParse(selectedHouseId!);
    if (houseId == null) {
      print("[ERROR] Invalid house ID: $selectedHouseId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid house selection.')),
      );
      return;
    }

    try {
      await DatabaseService.updateUser(widget.id, {
        'name': name,
        'email': email,
        'userType': userType,
        'house_id': houseId, // Store correct house ID
      });

      setState(() {
        isSaved = true;
        hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print("[ERROR] Failed to update user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!isSaved && hasChanges) {
          return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Unsaved Changes'),
                    content: const Text('Are you sure? Your current changes will be lost.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop(false); // Stay on page
                        },
                      ),
                      TextButton(
                        child: const Text('Yes'),
                        onPressed: () {
                          Navigator.of(context).pop(true); // Confirm exit
                        },
                      ),
                    ],
                  );
                },
              ) ??
              false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit User'),
          backgroundColor: AppColors.colorScheme.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('User Type', style: TextStyle(fontSize: 18)),
              Row(
                children: [
                  Radio<String>(
                    value: 'Admin',
                    groupValue: userType,
                    onChanged: (String? value) {
                      setState(() {
                        userType = value!;
                        trackChanges();
                      });
                    },
                  ),
                  const Text('Admin'),
                  Radio<String>(
                    value: 'User',
                    groupValue: userType,
                    onChanged: (String? value) {
                      setState(() {
                        userType = value!;
                        trackChanges();
                      });
                    },
                  ),
                  const Text('User'),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                onChanged: (value) => trackChanges(),
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                onChanged: (value) => trackChanges(),
                decoration: const InputDecoration(labelText: 'Email (must be gmail.com)', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              const Text('House', style: TextStyle(fontSize: 18)),
              DropdownButton<String>(
                value: selectedHouseId,
                hint: const Text('Select House'),
                items: houseOptions.map<DropdownMenuItem<String>>((house) {
                  return DropdownMenuItem<String>(
                    value: house['id'], // Store house ID
                    child: Text(house['name']!), // Show house name
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedHouseId = newValue; // Store selected house ID
                    trackChanges();
                  });
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: hasChanges ? _validateAndSave : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
