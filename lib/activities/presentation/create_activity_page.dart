import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/invite_members_page.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surface2     = Color(0xFFFFFFFF);
const _surfaceInset = Color(0xFFF0EDE2);
const _text         = Color(0xFF21201B);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);

class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  State<CreateActivityPage> createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _docCtrl   = TextEditingController();

  DateTime? _dueDate;
  final List<ActivityTask> _tasks = [];
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _docCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun',
                    'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _removeTask(int i) => setState(() => _tasks.removeAt(i));

  void _showEditTaskSheet(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddTaskSheet(
        initialTask: _tasks[index],
        onAdd: (task) => setState(() => _tasks[index] = task),
      ),
    );
  }

  // ── Submit ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha límite')));
      return;
    }
    setState(() => _saving = true);
    try {
      final activity = await ActivityService().createActivity(
        name: _nameCtrl.text.trim(),
        dueDate: _dueDate!,
        documentLink: _docCtrl.text.trim(),
        tasks: _tasks,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => InviteMembersPage(activity: activity)),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Add task sheet ───────────────────────────────────────────────────

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddTaskSheet(
        onAdd: (task) => setState(() => _tasks.add(task)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    _label('Nombre de la actividad'),
                    const SizedBox(height: 8),
                    _buildNameField(),
                    const SizedBox(height: 20),
                    // Fecha límite
                    _label('Fecha límite'),
                    const SizedBox(height: 8),
                    _buildDateField(),
                    const SizedBox(height: 20),
                    // Enlace
                    _label('Enlace del documento'),
                    const SizedBox(height: 8),
                    _buildDocField(),
                    const SizedBox(height: 28),
                    // Tareas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TAREAS INICIALES',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: _text3, letterSpacing: 1.2,
                            )),
                        GestureDetector(
                          onTap: _showAddTaskSheet,
                          child: Row(
                            children: [
                              const Icon(Icons.add, size: 16, color: _primary),
                              const SizedBox(width: 2),
                              Text('Añadir',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: _primary,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_tasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surfaceInset,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('Sin tareas aún. Pulsa + Añadir.',
                              style: GoogleFonts.hankenGrotesk(
                                  fontSize: 13, color: _text3)),
                        ),
                      )
                    else
                      ..._tasks.asMap().entries.map((e) => _TaskRow(
                            task: e.value,
                            onEdit: () => _showEditTaskSheet(e.key),
                            onRemove: () => _removeTask(e.key),
                          )),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2723), Color(0xFF46413A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Color(0xFFF6F3EA), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Nueva actividad',
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  Text('1 de 2',
                      style: GoogleFonts.hankenGrotesk(
                        color: const Color(0xFFF6F3EA).withValues(alpha: 0.5),
                        fontSize: 13,
                      )),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(_primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fields ───────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: GoogleFonts.hankenGrotesk(
          fontSize: 13.5, fontWeight: FontWeight.w600, color: _text2));

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.label_outline_rounded, size: 18, color: _text3),
          ),
          Expanded(
            child: TextFormField(
              controller: _nameCtrl,
              style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 14),
                hintText: 'Ej. Plan de Marketing Digital',
                hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 14, color: _text3),
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Ingresa el nombre' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: _text3),
            const SizedBox(width: 10),
            Text(
              _dueDate == null
                  ? 'Selecciona una fecha'
                  : _formatDate(_dueDate!),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: _dueDate == null ? _text3 : _text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocField() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.link_rounded, size: 18, color: _text3),
          ),
          Expanded(
            child: TextFormField(
              controller: _docCtrl,
              style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 14),
                hintText: 'docs.google.com/d/...',
                hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 14, color: _text3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ───────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: _bg, border: Border(top: BorderSide(color: _border))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    side: BorderSide(color: _border, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text('Atrás',
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: _text2)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _surfaceInset,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Siguiente',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add task bottom sheet ──────────────────────────────────────────────

class _AddTaskSheet extends StatefulWidget {
  final void Function(ActivityTask task) onAdd;
  final ActivityTask? initialTask;

  const _AddTaskSheet({required this.onAdd, this.initialTask});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _nameCtrl = TextEditingController();

  String _taskType       = 'Backend';
  String _taskComplexity = 'Medium';
  String _priority       = 'Medium';
  double _hours          = 5;

  bool get _isEditing => widget.initialTask != null;

  static const _taskTypes = [
    'Backend', 'Frontend', 'Testing',
    'Database', 'Documentation', 'Management',
  ];
  static const _complexities = ['Low', 'Medium', 'High'];
  static const _priorities   = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    if (t != null) {
      _nameCtrl.text   = t.name;
      _taskType        = t.taskType.isNotEmpty ? t.taskType : 'Backend';
      _taskComplexity  = t.taskComplexity.isNotEmpty ? t.taskComplexity : 'Medium';
      _priority        = t.priority.isNotEmpty ? t.priority : 'Medium';
      _hours           = t.estimatedHours.toDouble().clamp(1, 100);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(ActivityTask(
      name: name,
      taskType: _taskType,
      taskComplexity: _taskComplexity,
      priority: _priority,
      estimatedHours: _hours.round(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 20),
            Text(_isEditing ? 'Editar tarea' : 'Nueva tarea',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
            const SizedBox(height: 14),

            // ── Nombre ────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  hintText: 'Nombre de la tarea',
                  hintStyle:
                      GoogleFonts.hankenGrotesk(fontSize: 14, color: _text3),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Selectores ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _DropRow(
                    icon: Icons.category_outlined,
                    label: 'Tipo de tarea',
                    value: _taskType,
                    items: _taskTypes,
                    onChanged: (v) => setState(() => _taskType = v!),
                  ),
                  _divider(),
                  _DropRow(
                    icon: Icons.layers_outlined,
                    label: 'Complejidad',
                    value: _taskComplexity,
                    items: _complexities,
                    onChanged: (v) => setState(() => _taskComplexity = v!),
                  ),
                  _divider(),
                  _DropRow(
                    icon: Icons.flag_outlined,
                    label: 'Prioridad',
                    value: _priority,
                    items: _priorities,
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  _divider(),
                  // Horas estimadas
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_outlined,
                                size: 18, color: _primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('Horas estimadas',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: _text)),
                            ),
                            Text('${_hours.round()} h',
                                style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: _primary)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _primary,
                            inactiveTrackColor: _border,
                            thumbColor: Colors.white,
                            overlayColor: _primary.withValues(alpha: 0.12),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _hours,
                            min: 1, max: 100, divisions: 99,
                            onChanged: (v) => setState(() => _hours = v),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1 h', style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11.5, color: _text3)),
                              Text('100 h', style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11.5, color: _text3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Botón añadir ──────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  elevation: 0,
                ),
                child: Text(_isEditing ? 'Guardar cambios' : 'Añadir tarea',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: _border, indent: 16, endIndent: 16);
}

class _DropRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _surfaceInset,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _text),
                items: items
                    .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task row ───────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final ActivityTask task;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _TaskRow({
    required this.task,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _surfaceInset,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.check_rounded, size: 16, color: _text3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                if (task.taskType.isNotEmpty)
                  Text('${task.taskType} · ${task.estimatedHours}h',
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 12, color: _text3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_outlined, size: 18, color: _text3),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: _text3),
            ),
          ),
        ],
      ),
    );
  }
}
