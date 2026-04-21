import 'package:flutter/material.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:assignum/activities/presentation/invite_members_page.dart';

class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _docLinkCtrl = TextEditingController();
  final _taskCtrl = TextEditingController();

  DateTime? _dueDate;
  final List<String> _tasks = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _docLinkCtrl.dispose();
    _taskCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _addTask() {
    final text = _taskCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tasks.add(text);
        _taskCtrl.clear();
      });
    }
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de entrega')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
       final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
       final docRef = FirebaseFirestore.instance.collection('activities').doc();
       final activity = Activity(
         id: docRef.id,
         uid: uid,
         name: _nameCtrl.text.trim(),
         dueDate: _dueDate!,
         documentLink: _docLinkCtrl.text.trim(),
         tasks: _tasks,
       );
       await ActivityService().createActivity(activity);
       if (mounted) {
         Navigator.pushReplacement(
           context, 
           MaterialPageRoute(builder: (_) => InviteMembersPage(activity: activity))
         );
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Actividad guardada. ¡Invita a los participantes!')),
         );
       }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
      }
    }
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  InputDecoration _customDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Actividad', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.grey[600],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Edita Tu actividad',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldTitle('Nombre'),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _customDecoration(),
                        validator: (v) => v!.trim().isEmpty ? 'Ingresa el nombre' : null,
                      ),
                      const SizedBox(height: 16),

                      _buildFieldTitle('Fecha de entrega'),
                      InkWell(
                        onTap: _pickDueDate,
                        borderRadius: BorderRadius.circular(20),
                        child: InputDecorator(
                          decoration: _customDecoration(),
                          child: Text(
                            _dueDate == null
                                ? 'Seleccione fecha'
                                : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                            style: TextStyle(
                              color: _dueDate == null ? Colors.black54 : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildFieldTitle('Enlace de documento'),
                      TextFormField(
                        controller: _docLinkCtrl,
                        decoration: _customDecoration(),
                      ),
                      const SizedBox(height: 16),

                      _buildFieldTitle('Tareas a realizar'),
                      TextFormField(
                        controller: _taskCtrl,
                        decoration: _customDecoration().copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white, weight: 800),
                            onPressed: _addTask,
                          ),
                        ),
                        onFieldSubmitted: (_) => _addTask(),
                      ),
                      const SizedBox(height: 8),
                      if (_tasks.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: _tasks.asMap().entries.map((entry) {
                            return Chip(
                              label: Text(entry.value),
                              onDeleted: () => _removeTask(entry.key),
                              deleteIconColor: Colors.redAccent,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: _saving ? 'Guardando...' : 'Siguiente',
                        onPressed: _saving ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
