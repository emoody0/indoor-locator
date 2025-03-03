import 'package:flutter/material.dart';
import 'database_service.dart';

class ManageSQLPage extends StatefulWidget {
  const ManageSQLPage({super.key});

  @override
  _ManageSQLPageState createState() => _ManageSQLPageState();
}

class _ManageSQLPageState extends State<ManageSQLPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _userTypeController = TextEditingController();
  final TextEditingController _houseIdController = TextEditingController();
  final TextEditingController _houseNameController = TextEditingController();

  List<Map<String, dynamic>> _tableData = [];
  bool _isLoading = false;
  String _status = 'Disconnected';
  bool _isConnected = false;
  String _selectedTable = 'Users'; // Default table selection
  String? _selectedDeleteId;

  @override
  void initState() {
    super.initState();
    _checkDatabaseConnection();
  }

  /// Check database connection status
  Future<void> _checkDatabaseConnection() async {
    try {
      await DatabaseService.testConnection();
      setState(() {
        _status = 'Connected';
        _isConnected = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Disconnected';
        _isConnected = false;
      });
    }
  }

Future<void> _fetchTableData() async {
  setState(() {
    _isLoading = true;
    _tableData = [];
    _selectedDeleteId = null;
  });

  try {
    final data = await DatabaseService.fetchData(_selectedTable);

    // Convert house_id null values to display correctly
    if (_selectedTable == 'Users') {
      for (var user in data) {
        if (user['house_id'] == null) {
          user['house_id'] = 'No House';
        }
      }
    }

    setState(() {
      _tableData = data;
    });
  } catch (e) {
    // print('[ERROR] Failed to fetch table data: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}


  /// Insert data into Users or Houses table
  Future<void> _insertData() async {
    Map<String, dynamic> data = {};

    if (_selectedTable == 'Users') {
      data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'userType': _userTypeController.text.trim(),
        'house_id': _houseIdController.text.trim().isNotEmpty
            ? int.parse(_houseIdController.text.trim())
            : null,
      };
    } else if (_selectedTable == 'Houses') {
      data = {
        'name': _houseNameController.text.trim(),
      };
    }

    try {
      await DatabaseService.insertData(_selectedTable, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inserted successfully')),
      );
      _fetchTableData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to insert data: $e')),
      );
    }
  }

  /// Delete selected row
  Future<void> _deleteSelectedRow() async {
    if (_selectedDeleteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a row to delete')),
      );
      return;
    }

    try {
      await DatabaseService.deleteData(_selectedTable, "id='$_selectedDeleteId'");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data deleted successfully')),
      );
      _fetchTableData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage SQL Data'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildConnectionIndicator(),
                const SizedBox(height: 20),
                _buildDropdownMenu(),
                const SizedBox(height: 20),
                _buildInputFields(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _insertData,
                  child: const Text('Insert Data'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchTableData,
                  child: const Text('Fetch Table Data'),
                ),
                const SizedBox(height: 20),
                _buildDataTable(),
                const SizedBox(height: 20),
                _buildDeleteSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build connection status indicator
  Widget _buildConnectionIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Status: ', style: TextStyle(fontSize: 24)),
        Text(_status, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Icon(Icons.circle, color: _isConnected ? Colors.green : Colors.red, size: 24),
      ],
    );
  }

  /// Dropdown menu for selecting Users or Houses table
  Widget _buildDropdownMenu() {
    return DropdownButton<String>(
      value: _selectedTable,
      items: <String>['Users', 'Houses'].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedTable = newValue!;
          _fetchTableData();
        });
      },
    );
  }

  /// Input fields for data insertion
  Widget _buildInputFields() {
    return Column(
      children: [
        if (_selectedTable == 'Users') ...[
          _buildTextField(_nameController, 'Name'),
          _buildTextField(_emailController, 'Email'),
          _buildTextField(_userTypeController, 'User Type'),
          _buildTextField(_houseIdController, 'House ID (optional)', isNumber: true),
        ],
        if (_selectedTable == 'Houses') ...[
          _buildTextField(_houseNameController, 'House Name'),
        ],
      ],
    );
  }

  /// Data table display with delete selection
  Widget _buildDataTable() {
    if (_tableData.isEmpty) {
      return const Text('No data available');
    }
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _tableData.first.keys.map((key) => DataColumn(label: Text(key))).toList(),
            rows: _tableData.map(
              (row) => DataRow(
                selected: _selectedDeleteId == row['id'].toString(),
                onSelectChanged: (isSelected) {
                  setState(() {
                    _selectedDeleteId = isSelected! ? row['id'].toString() : null;
                  });
                },
                cells: row.values.map((value) => DataCell(Text(value.toString()))).toList(),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  /// Delete button
  Widget _buildDeleteSection() {
    return ElevatedButton(
      onPressed: _deleteSelectedRow,
      child: const Text('Delete Selected Row'),
    );
  }

  /// Helper for building text fields
  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
