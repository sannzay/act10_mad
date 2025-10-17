import 'package:flutter/material.dart';
import 'database_helper.dart';

final dbHelper = DatabaseHelper.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  List<Map<String, dynamic>> _rows = [];
  String _status = '';

  @override
  void initState() {
    super.initState();
    _refreshRows();
  }

  Future<void> _refreshRows() async {
    final rows = await dbHelper.queryAllRows();
    setState(() {
      _rows = rows;
    });
  }

  void _setStatus(String s) {
    setState(() => _status = s);
    debugPrint(s);
  }

  Future<void> _insert() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim() ?? '');
    if (name.isEmpty || age == null) {
      _setStatus('Please provide a valid name and age to insert.');
      return;
    }
    final id = await dbHelper.insert({
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnAge: age,
    });
    _setStatus('Inserted row id: $id');
    _nameController.clear();
    _ageController.clear();
    await _refreshRows();
  }

  Future<void> _queryAll() async {
    await _refreshRows();
    _setStatus('Queried all rows (${_rows.length})');
  }

  Future<void> _queryById() async {
    final id = int.tryParse(_idController.text.trim() ?? '');
    if (id == null) {
      _setStatus('Please enter a valid ID to query.');
      return;
    }
    final row = await dbHelper.queryById(id);
    if (row == null) {
      _setStatus('No row found with id $id.');
    } else {
      _setStatus('Found: ${row.toString()}');
    }
  }

  Future<void> _update() async {
    final id = int.tryParse(_idController.text.trim() ?? '');
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim() ?? '');
    if (id == null || name.isEmpty || age == null) {
      _setStatus('Please provide valid id, name and age to update.');
      return;
    }
    final rowsAffected = await dbHelper.update({
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnAge: age,
    });
    _setStatus('Updated $rowsAffected row(s)');
    await _refreshRows();
  }

  Future<void> _delete() async {
    final id = int.tryParse(_idController.text.trim() ?? '');
    if (id == null) {
      _setStatus('Please enter a valid ID to delete.');
      return;
    }
    final rowsDeleted = await dbHelper.delete(id);
    _setStatus('Deleted $rowsDeleted row(s) with id $id');
    await _refreshRows();
  }

  Future<void> _deleteAll() async {
    final count = await dbHelper.deleteAll();
    _setStatus('Deleted all rows ($count).');
    await _refreshRows();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('sqflite demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          decoration: const InputDecoration(
                            labelText: 'ID (for query/update/delete)',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _insert, child: const Text('Insert')),
                ElevatedButton(onPressed: _queryAll, child: const Text('Query All')),
                ElevatedButton(onPressed: _queryById, child: const Text('Query by ID')),
                ElevatedButton(onPressed: _update, child: const Text('Update')),
                ElevatedButton(onPressed: _delete, child: const Text('Delete by ID')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    // confirm destructive action
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete all records?'),
                        content: const Text('This will remove all rows from the table.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await _deleteAll();
                    }
                  },
                  child: const Text('Delete All'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Status: $_status', style: const TextStyle(fontSize: 14)),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text('Rows (${_rows.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(width: 1, color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _rows.isEmpty
                    ? const Center(child: Text('No rows yet. Insert some records.'))
                    : ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(row[DatabaseHelper.columnId].toString())),
                            title: Text(row[DatabaseHelper.columnName].toString()),
                            subtitle: Text('Age: ${row[DatabaseHelper.columnAge]}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final id = row[DatabaseHelper.columnId] as int;
                                await dbHelper.delete(id);
                                _setStatus('Deleted row id $id');
                                await _refreshRows();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
