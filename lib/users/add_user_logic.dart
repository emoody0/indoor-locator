import 'package:flutter/material.dart';
import 'package:g14_indoor_locator/server/database_service.dart';

class AddUserLogic {
  final BuildContext context;
  final Function(List<Map<String, dynamic>>) updateHouseOptions;
  final Function(int?) updateSelectedHouse;

  AddUserLogic({
    required this.context,
    required this.updateHouseOptions,
    required this.updateSelectedHouse,
  });

  /// Load house options from the database
  Future<void> loadHouseOptions() async {
    try {
      final houses = await DatabaseService.fetchHouses();
      final houseList = houses.map((house) => {
        'id': house['id'],
        'name': house['name'].toString(),
      }).toList();

      updateHouseOptions(houseList);

      if (houseList.isNotEmpty) {
        updateSelectedHouse(houseList.first['id']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load house options: $e')),
      );
    }
  }

  /// Validate and add user
  Future<void> validateAndSaveUser({
    required String name,
    required String email,
    required String userType,
    required int? selectedHouseId,
    required Function() onSuccess,
  }) async {
    if (name.isEmpty || email.isEmpty || selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    try {
      await DatabaseService.insertUser({
        'name': name,
        'email': email,
        'userType': userType,
        'house_id': selectedHouseId,
      });

      onSuccess(); // Callback on successful save

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully!')),
      );

      Navigator.pop(context); // Close the page after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: $e')),
      );
    }
  }
}
