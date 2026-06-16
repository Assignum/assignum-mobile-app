import 'dart:async';
import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/core/infrastructure/api_client.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/activities/presentation/task_details_page.dart';
import 'package:assignum/activities/presentation/member_task_page.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;
  final bool isCreationFlow;

  const ActivityDetailsPage({super.key, required this.activity, this.isCreationFlow = false});

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  late bool _showTasks;
  String _leaderName = 'Cargando...';
  late Activity _currentActivity;
  StreamSubscription<Activity?>? _activitySub;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _showTasks = !widget.isCreationFlow;
    _initLeaderName();
    _activitySub = ActivityService()
        .getActivityStreamById(widget.activity.id)
        .listen((updated) {
      if (updated != null && mounted) {
        setState(() => _currentActivity = updated);
      }
    });
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }

  void _initLeaderName() {
    if (_currentActivity.uid == IAuthFacade.instance.currentUserId) {
      _leaderName = 'Tú';
      return;
    }
    // Use leaderName if already present (e.g. from creation flow via REST)
    if (_currentActivity.leaderName.isNotEmpty) {
      _leaderName = _currentActivity.leaderName;
      return;
    }
    // Firestore docs don't have leaderName — fetch once from REST API
    ActivityService().getActivity(_currentActivity.id).then((activity) {
      if (!mounted) return;
      setState(() {
        _leaderName = (activity?.leaderName.isNotEmpty == true)
            ? activity!.leaderName
            : 'Sin nombre';
      });
    });
  }

  Future<void> _finalizeActivity(BuildContext context) async {
    final progress = _calculateProgress();
    if (progress == 100) {
      await _doFinalizeActivity(context);
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Finalizar actividad?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('La actividad se encuentra al $progress% de progreso. ¿Estás seguro?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async { Navigator.pop(ctx); await _doFinalizeActivity(context); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _doFinalizeActivity(BuildContext context) async {
    try {
      await ActivityService().finalizeActivity(_currentActivity.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    // Firestore stream will update _currentActivity.finalized automatically
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFFE51D2A), size: 56),
              const SizedBox(height: 16),
              const Text('Actividad finalizada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('"${_currentActivity.name}" ha sido marcada como finalizada.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateProgress() {
    if (_currentActivity.tasks.isEmpty) return 0;
    int verified = _currentActivity.tasks.where((t) => t.status == 'Verificado').length;
    return ((verified / _currentActivity.tasks.length) * 100).toInt();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tareas Divididas\nExitosamente', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              PrimaryButton(text: 'Siguiente', onPressed: () { Navigator.pop(ctx); setState(() => _showTasks = true); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final present = _currentActivity.acceptedEmails;
    final pending = _currentActivity.invitedEmails;

    return Column(
      children: [
        const Text('Lista de Miembros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: present.length + pending.length + 1,
            itemBuilder: (ctx, i) {
              String memberText = '';
              bool isLeader = false;
              if (i == 0) {
                memberText = _currentActivity.uid == IAuthFacade.instance.currentUserId ? 'Tú (Líder)' : '$_leaderName (Líder)';
                isLeader = true;
              } else if (i <= present.length) {
                final m = present[i - 1];
                final name = _currentActivity.memberNames[m] ?? _currentActivity.memberNames[m.replaceAll('.', '_')] ?? m;
                memberText = name;
              } else {
                memberText = '${pending[i - 1 - present.length]} (Pendiente)';
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(memberText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                    if (!isLeader)
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(60, 36), elevation: 0),
                        child: const Text('Ver', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (widget.isCreationFlow) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: _currentActivity.tasks.isEmpty ? 'Agrega tareas primero' : '',
              child: ElevatedButton(
                onPressed: _currentActivity.tasks.isEmpty
                    ? null
                    : () async {
                        try {
                          await ActivityService().assignTasks(_currentActivity.id);
                          // Firestore stream updates _currentActivity automatically
                          _showSuccessDialog();
                        } on ApiException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE51D2A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Dividir Tareas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTasksList() {
    final isLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;
    final displayTasks = _currentActivity.tasks;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Puntos a realizar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () => setState(() => _showTasks = false),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(60, 32), padding: const EdgeInsets.symmetric(horizontal: 16), elevation: 0),
              child: const Text('Miembros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: displayTasks.length,
            itemBuilder: (ctx, i) {
              final task = displayTasks[i];
              String displayName = task.assignedToEmail;
              if (task.assignedToEmail == currentUserEmail) {
                displayName = isLeader ? 'Tú (Líder)' : 'Tú';
              } else if (_currentActivity.acceptedEmails.contains(task.assignedToEmail)) {
                displayName = _currentActivity.memberNames[task.assignedToEmail] ?? task.assignedToEmail;
              } else if (_currentActivity.invitedEmails.contains(task.assignedToEmail)) {
                displayName = '${task.assignedToEmail} (Pendiente de aceptar)';
              } else {
                displayName = '$_leaderName (Líder)';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                          Text('Asignada a: $displayName', style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (isLeader || task.assignedToEmail == currentUserEmail)
                      ElevatedButton(
                        onPressed: () async {
                          if (isLeader) {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsPage(activity: _currentActivity, task: task, assigneeName: displayName)));
                          } else {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => MemberTaskPage(activity: _currentActivity, task: task, assigneeName: displayName)));
                          }
                          // No _refresh() — Firestore stream handles real-time updates
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(60, 36), elevation: 0),
                        child: const Text('Ver', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(titleText: 'Tus Actividades', showProfileAvatar: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text(_currentActivity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text('DL: ${_currentActivity.dueDate.day}/${_currentActivity.dueDate.month}/${_currentActivity.dueDate.year}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Progreso: ', style: TextStyle(fontSize: 16)),
                        Text('${_calculateProgress()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Team Leader: $_leaderName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    if (_currentActivity.finalized) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                            SizedBox(width: 6),
                            Text('Actividad Finalizada', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ] else if (_currentActivity.uid == IAuthFacade.instance.currentUserId) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _finalizeActivity(context),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0),
                          child: const Text('Finalizar actividad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: CardContainer(child: _showTasks ? _buildTasksList() : _buildMembersList())),
            ],
          ),
        ),
      ),
    );
  }
}
