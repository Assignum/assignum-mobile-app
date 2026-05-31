import 'package:flutter/material.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/presentation/activity_details_page.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class InviteMembersPage extends StatefulWidget {
  final Activity activity;
  const InviteMembersPage({super.key, required this.activity});

  @override
  State<InviteMembersPage> createState() => _InviteMembersPageState();
}

class _InviteMembersPageState extends State<InviteMembersPage> {
  final _emailCtrl = TextEditingController();
  final List<String> _emails = [];
  bool _saving = false;

  void _addEmail() {
    final text = _emailCtrl.text.trim();
    if (text.isNotEmpty && text.contains('@')) {
      setState(() {
        if (!_emails.contains(text)) {
          _emails.add(text);
        }
        _emailCtrl.clear();
      });
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Ingresa un correo electrónico válido')),
       );
    }
  }

  void _removeEmail(int index) {
    setState(() => _emails.removeAt(index));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Compañeros Invitados\nExitosamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Siguiente',
                  onPressed: () {
                     Navigator.pop(ctx); 
                     
                     final updatedAct = Activity(
                        id: widget.activity.id,
                        uid: widget.activity.uid,
                        name: widget.activity.name,
                        dueDate: widget.activity.dueDate,
                        documentLink: widget.activity.documentLink,
                        tasks: widget.activity.tasks,
                        invitedEmails: _emails.toList(),
                     );
                     
                     Navigator.pushReplacement(
                       context, 
                       MaterialPageRoute(builder: (_) => ActivityDetailsPage(activity: updatedAct, isCreationFlow: true))
                     );
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_emails.isEmpty) {
      Navigator.pushReplacement(
         context, 
         MaterialPageRoute(builder: (_) => ActivityDetailsPage(activity: widget.activity, isCreationFlow: true))
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ActivityService().updateInvitedEmails(widget.activity.id, _emails);
      if (mounted) {
         _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
      appBar: const PremiumAppBar(
        titleText: 'Crear Actividad',
        showProfileAvatar: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Invita a tus compañeros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Correo electronico',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: _customDecoration().copyWith(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, weight: 800),
                          onPressed: _addEmail,
                        ),
                      ),
                      onFieldSubmitted: (_) => _addEmail(),
                    ),
                    const SizedBox(height: 12),
                    if (_emails.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _emails.asMap().entries.map((entry) {
                          return Chip(
                            label: Text(entry.value),
                            onDeleted: () => _removeEmail(entry.key),
                            deleteIconColor: Colors.redAccent,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 100),

                    PrimaryButton(
                      text: _saving ? 'Enviando...' : 'Siguiente',
                      onPressed: _saving ? null : _submit,
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
