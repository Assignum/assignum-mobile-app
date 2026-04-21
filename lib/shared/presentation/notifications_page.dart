import 'package:flutter/material.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/domain/activity.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ActivityService _service = ActivityService();
  List<Activity> _invitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final acts = await _service.getPendingInvitations();
    if (mounted) {
      setState(() {
        _invitations = acts;
        _loading = false;
      });
    }
  }

  Future<void> _accept(String id) async {
     setState(() => _loading = true);
     await _service.acceptInvitation(id);
     await _load();
  }

  Future<void> _decline(String id) async {
     setState(() => _loading = true);
     await _service.declineInvitation(id);
     await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.grey[600],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text('Invitaciones Pendientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading 
                  ? const Center(child: CircularProgressIndicator())
                  : _invitations.isEmpty
                     ? const Center(child: Text('No hay invitaciones ahora.'))
                     : ListView.builder(
                        itemCount: _invitations.length,
                        itemBuilder: (ctx, i) {
                          final act = _invitations[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Has sido invitado a "${act.name}"',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _accept(act.id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE51D2A),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text('Aceptar'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _decline(act.id),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: const BorderSide(color: Colors.black12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                        child: const Text('Rechazar'),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
