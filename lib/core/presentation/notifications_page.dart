import 'package:flutter/material.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ActivityService _service = ActivityService();
  List<Map<String, dynamic>> _invitations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final invitations = await _service.getPendingInvitations();
    if (mounted) {
      setState(() {
        _invitations = invitations;
        _loading = false;
      });
    }
  }

  Future<void> _accept(String activityId) async {
    setState(() => _loading = true);
    await _service.acceptInvitation(activityId);
    await _load();
  }

  Future<void> _decline(String activityId) async {
    setState(() => _loading = true);
    await _service.declineInvitation(activityId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(titleText: 'Notificaciones'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Invitaciones Pendientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _invitations.isEmpty
                        ? const Center(child: Text('No hay invitaciones ahora.'))
                        : ListView.builder(
                            itemCount: _invitations.length,
                            itemBuilder: (ctx, i) {
                              final inv = _invitations[i];
                              final activityId = inv['activityId'] as String? ?? '';
                              final activityName = inv['activityName'] as String? ?? 'Actividad';
                              final leaderName = inv['leaderName'] as String? ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Has sido invitado a "$activityName"',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (leaderName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Por: $leaderName', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _accept(activityId),
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
                                            onPressed: () => _decline(activityId),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.black87,
                                              side: const BorderSide(color: Colors.black12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                            child: const Text('Rechazar'),
                                          ),
                                        ),
                                      ],
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
      ),
    );
  }
}
