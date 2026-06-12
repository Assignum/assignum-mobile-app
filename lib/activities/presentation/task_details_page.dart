import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/activities/presentation/member_task_page.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class TaskDetailsPage extends StatefulWidget {
  final Activity activity;
  final ActivityTask task;
  final String assigneeName;

  const TaskDetailsPage({
    super.key,
    required this.activity,
    required this.task,
    required this.assigneeName,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late ActivityTask _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  Future<void> _verifyTask(BuildContext context) async {
    try {
      await ActivityService().verifyTask(widget.activity.id, _currentTask.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _currentTask = _currentTask.copyWith(status: 'Verificado'));

    if (!context.mounted) return;
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
              Text('${_currentTask.name} Verificada\nExitosamente', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              PrimaryButton(text: 'Siguiente', onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${widget.activity.dueDate.day.toString().padLeft(2, '0')}/${widget.activity.dueDate.month.toString().padLeft(2, '0')}/${widget.activity.dueDate.year.toString().substring(2)}';

    return Scaffold(
      appBar: const PremiumAppBar(titleText: 'Tus Actividades', showProfileAvatar: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentTask.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Asignada a: ${widget.assigneeName}', style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MemberTaskPage(activity: widget.activity, task: _currentTask, assigneeName: widget.assigneeName),
                        ));
                        // Refresh task status from parent if needed
                        final updated = await ActivityService().getActivity(widget.activity.id);
                        if (updated != null && mounted) {
                          final idx = updated.tasks.indexWhere((t) => t.id == _currentTask.id);
                          if (idx != -1) setState(() => _currentTask = updated.tasks[idx]);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), minimumSize: const Size(60, 36), elevation: 0),
                      child: const Text('Modificar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(30)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: ${_currentTask.status}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Fecha límite: $dateStr', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 12),
                        const Text('Enlace al documento:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          _currentTask.links.isEmpty ? (widget.activity.documentLink.isEmpty ? 'Sin enlace' : widget.activity.documentLink) : _currentTask.links,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        const Text('Comentarios:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_currentTask.comments.isEmpty ? 'Sin comentarios' : _currentTask.comments, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 32),
                        if (_currentTask.status == 'Entregado')
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _verifyTask(context),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51D2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                              child: const Text('Marcar como Verificado', style: TextStyle(fontSize: 16)),
                            ),
                          )
                        else if (_currentTask.status == 'Verificado')
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(24)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text('Tarea verificada', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Text(
                              'El miembro debe marcarla como "Entregado" antes de poder verificarla',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black45, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
