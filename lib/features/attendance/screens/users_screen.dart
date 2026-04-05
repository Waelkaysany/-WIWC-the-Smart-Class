import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';
import '../../../../models/user_model.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final users = await db.getAllUsers();
      setState(() {
        _users = users;
      });
    } catch (e) {
      debugPrint("Error loading users: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddUserDialog() {
    final uidController = TextEditingController();
    final nameController = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final lastUid = ref.watch(StreamProvider<String?>((ref) {
            return ref.watch(databaseServiceProvider).lastScannedUidStream;
          })).value;

          if (lastUid != null && uidController.text.isEmpty) {
            uidController.text = lastUid;
          }

          return StatefulBuilder(
            builder: (context, setStateDialog) => AlertDialog(
              title: const Text('Add New User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lastUid != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Last scanned: $lastUid',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  TextField(
                    controller: uidController,
                    decoration: const InputDecoration(
                      labelText: 'RFID UID (Hex)',
                      hintText: 'e.g. A1 B2 C3 D4',
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  DropdownButton<String>(
                    value: role,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      setStateDialog(() => role = val!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (uidController.text.isNotEmpty && nameController.text.isNotEmpty) {
                      await ref.read(databaseServiceProvider).registerNewUser(
                        uidController.text,
                        nameController.text,
                        role,
                      );
                      Navigator.pop(context);
                      _loadUsers();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(user.name),
                      subtitle: Text('UID: ${user.uid} | Role: ${user.role}'),
                      trailing: Text(user.status),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
