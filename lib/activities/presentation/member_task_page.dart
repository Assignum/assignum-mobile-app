import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class MemberTaskPage extends StatefulWidget {
  final Activity activity;
  final ActivityTask task;
  final String assigneeName;

  const MemberTaskPage({
    super.key,
    required this.activity,
    required this.task,
    required this.assigneeName,
  });

  @override
  State<MemberTaskPage> createState() => _MemberTaskPageState();
}

class _MemberTaskPageState extends State<MemberTaskPage> {
  late String _status;
  final _commentsCtrl = TextEditingController();
  final _filesCtrl = TextEditingController();
  final _linksCtrl = TextEditingController();
  bool _saving = false;

  late List<String> _statusOptions;
  late bool _isLeader;

  @override
  void initState() {
    super.initState();
    _isLeader = widget.activity.uid == IAuthFacade.instance.currentUserId;
    _statusOptions = ['Pendiente', 'En progreso', 'Finalizado'];
    if (_isLeader || widget.task.status == 'Verificado') {
      _statusOptions.add('Verificado');
    }
    _status = widget.task.status;
    if (!_statusOptions.contains(_status)) {
      _status = 'Pendiente';
    }
    _commentsCtrl.text = widget.task.comments;
    _filesCtrl.text = widget.task.files;
    _linksCtrl.text = widget.task.links;
  }

  @override
  void dispose() {
    _commentsCtrl.dispose();
    _filesCtrl.dispose();
    _linksCtrl.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.task.name} Actualizada\ncorrectamente',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Siguiente',
                  onPressed: () {
                    Navigator.pop(ctx); 
                    Navigator.pop(context); 
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveTask() async {
    setState(() => _saving = true);
    
    final updatedTask = widget.task.copyWith(
      status: _status,
      comments: _commentsCtrl.text,
      files: _filesCtrl.text,
      links: _linksCtrl.text,
    );

    final idx = widget.activity.tasks.indexWhere((t) => t.name == widget.task.name);
    if (idx != -1) {
      widget.activity.tasks[idx] = updatedTask;
      await ActivityService().updateActivity(widget.activity);
    }
    
    if (mounted) {
      setState(() => _saving = false);
      _showSuccessDialog();
    }
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, {int maxLines = 1, bool enabled = true}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        enabled: enabled,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isReadOnly = !_isLeader && _status == 'Verificado';

    return Scaffold(
      appBar: const PremiumAppBar(
        titleText: 'Tus Actividades',
        showProfileAvatar: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.12),
                   borderRadius: BorderRadius.circular(30),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                        widget.task.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text('Asignada a: ${widget.assigneeName}', style: const TextStyle(fontSize: 14)),
                   ]
                 )
               ),
               const SizedBox(height: 24),
               Expanded(
                 child: Container(
                   padding: const EdgeInsets.all(24),
                   decoration: BoxDecoration(
                     color: Colors.black.withOpacity(0.08),
                     borderRadius: BorderRadius.circular(30),
                   ),
                   child: SingleChildScrollView(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildFieldTitle('Status'),
                         Container(
                           height: 45,
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           decoration: BoxDecoration(
                             color: Colors.black.withOpacity(0.08),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: DropdownButtonHideUnderline(
                             child: DropdownButton<String>(
                               value: _status,
                               isExpanded: true,
                               icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 28),
                               items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                               onChanged: isReadOnly ? null : (v) {
                                 if (v != null) setState(() => _status = v);
                               },
                             ),
                           ),
                         ),
                         _buildFieldTitle('Comentarios'),
                         _buildTextField(_commentsCtrl, maxLines: 3, enabled: !isReadOnly),
                         _buildFieldTitle('Archivos'),
                         _buildTextField(_filesCtrl, enabled: !isReadOnly),
                         _buildFieldTitle('Enlaces'),
                         _buildTextField(_linksCtrl, enabled: !isReadOnly),
                         const SizedBox(height: 32),
                         if (isReadOnly)
                           const Center(
                             child: Text(
                               'Esta tarea ya fue verificada por el Team Leader y no puede ser modificada.',
                               textAlign: TextAlign.center,
                               style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 14),
                             ),
                           )
                         else
                           Center(
                             child: ElevatedButton(
                               onPressed: _saving ? null : _saveTask,
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFFE51D2A),
                                 foregroundColor: Colors.white,
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(24),
                                 ),
                                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                 elevation: 0,
                               ),
                               child: Text(_saving ? 'Guardando...' : 'Finalizar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                             ),
                           )
                       ]
                     )
                   )
                 )
               )
            ]
          )
        )
      )
    );
  }
}
