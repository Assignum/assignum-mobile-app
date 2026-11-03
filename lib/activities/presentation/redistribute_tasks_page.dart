import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/presentation/fallback_notice.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/activities/domain/workload.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

// ── Tokens ─────────────────────────────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surfaceInset = Color(0xFFF0EDE2);
const _text         = Color(0xFF21201B);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);
const _primaryTint  = Color(0xFFFAE7E2);
const _warn         = Color(0xFFB26B36);
const _warnTint     = Color(0xFFF4E7D6);

/// Redistribuir tareas: el líder elige qué tareas y entre qué estudiantes.
///
/// 1. Selección de tareas (las completadas no aparecen, pero cuentan en la carga) y de
///    estudiantes, viendo la carga previa de cada uno.
/// 2. Revisión: el reparto propuesto por el sistema (ML + carga previa) o uno manual, que
///    el líder puede ajustar tarea por tarea antes de confirmar.
class RedistributeTasksPage extends StatefulWidget {
  final Activity activity;

  /// Tareas marcadas al abrir (p. ej. las que quedaron sin asignar al quitar a alguien).
  final Set<String> initialTaskIds;

  const RedistributeTasksPage({
    super.key,
    required this.activity,
    this.initialTaskIds = const {},
  });

  @override
  State<RedistributeTasksPage> createState() => _RedistributeTasksPageState();
}

enum _Step { select, review }

class _RedistributeTasksPageState extends State<RedistributeTasksPage> {
  late Activity _activity;
  StreamSubscription<Activity?>? _sub;

  late Set<String> _selectedTasks;
  late Set<String> _selectedMembers;
  _Step _step = _Step.select;
  bool _isAutoPlan = false;
  bool _planUsedFallback = false;
  final Map<String, String?> _plan = {};
  bool _busy = false;

  String get _leaderEmail => IAuthFacade.instance.currentUserEmail ?? '';

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    final openIds = _openTasks.map((t) => t.id).toSet();
    _selectedTasks = widget.initialTaskIds.intersection(openIds);
    _selectedMembers = {_leaderEmail, ..._activity.acceptedEmails};
    _sub = ActivityService().getActivityStreamById(_activity.id).listen((a) {
      if (a == null || !mounted) return;
      setState(() {
        _activity = a;
        // Si alguna tarea elegida se completó o desapareció mientras tanto, se descarta
        final open = _openTasks.map((t) => t.id).toSet();
        _selectedTasks.retainAll(open);
        _selectedMembers.retainAll(_group);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── Datos derivados ─────────────────────────────────────────────────

  List<ActivityTask> get _openTasks =>
      _activity.tasks.where((t) => !t.isCompleted).toList();

  int get _completedCount => _activity.tasks.where((t) => t.isCompleted).length;

  List<String> get _group => [
        _leaderEmail,
        ..._activity.acceptedEmails,
        ..._activity.invitedEmails,
      ];

  bool _isPending(String email) => _activity.invitedEmails.contains(email);

  String _name(String email) {
    if (email.isEmpty) return 'Sin asignar';
    if (email == _leaderEmail) return 'Tú (líder)';
    return _activity.memberNames[email] ??
        _activity.memberNames[email.replaceAll('.', '_')] ??
        email;
  }

  String _shortName(String email) {
    if (email.isEmpty) return 'Sin asignar';
    final n = _name(email);
    if (n.contains('@')) return n.split('@').first;
    final parts = n.trim().split(RegExp(r'\s+'));
    return parts.length >= 2 && !n.startsWith('Tú') ? '${parts[0]} ${parts[1][0]}.' : n;
  }

  /// Carga sin contar las tareas que se están redistribuyendo.
  Map<String, MemberLoad> get _baseLoads =>
      computeLoads(_activity.tasks, _group, excludeTaskIds: _selectedTasks);

  int _hours(ActivityTask t) => t.estimatedHours > 0 ? t.estimatedHours : 1;

  ActivityTask? _task(String id) {
    for (final t in _activity.tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ── Acciones ────────────────────────────────────────────────────────

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _autoPlan() async {
    setState(() => _busy = true);
    try {
      final proposal = await ActivityService().previewRedistribution(
        _activity.id,
        taskIds: _selectedTasks.toList(),
        memberEmails: _selectedMembers.toList(),
      );
      if (!mounted) return;
      setState(() {
        _plan
          ..clear()
          ..addAll(proposal.assignments);
        _isAutoPlan = true;
        _planUsedFallback = proposal.usedFallback;
        _step = _Step.review;
      });
    } on ApiException catch (e) {
      _snack('No se pudo calcular el reparto: ${e.message}');
    } catch (_) {
      _snack('No se pudo calcular el reparto. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _manualPlan() {
    setState(() {
      _plan.clear();
      for (final id in _selectedTasks) {
        final current = _task(id)?.assignedToEmail ?? '';
        _plan[id] = _selectedMembers.contains(current) ? current : null;
      }
      _isAutoPlan = false;
      _step = _Step.review;
    });
  }

  Future<void> _confirm() async {
    final missing = _selectedTasks.where((id) => _plan[id] == null).length;
    if (missing > 0) {
      _snack('Elige un responsable para $missing tarea${missing == 1 ? '' : 's'}');
      return;
    }
    setState(() => _busy = true);
    try {
      await ActivityService().applyAssignments(
        _activity.id,
        {for (final id in _selectedTasks) id: _plan[id]},
        assignmentMode: !_isAutoPlan ? 'manual' : (_planUsedFallback ? 'fallback' : 'ml'),
      );
      if (!mounted) return;
      _snack('Tareas asignadas. Se avisó a los estudiantes.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _snack('No se pudo guardar: ${e.message}');
    } catch (_) {
      _snack('No se pudo guardar. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.select && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == _Step.review && !_busy) {
          setState(() => _step = _Step.select);
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _step == _Step.select ? _buildSelectStep() : _buildReviewStep(),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final subtitle = _step == _Step.select
        ? 'Elige tareas y estudiantes'
        : (_isAutoPlan ? 'Reparto sugerido · puedes ajustarlo' : 'Asignación manual');
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, semanticLabel: 'Volver',
                      color: Color(0xFFF6F3EA), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Redistribuir tareas',
                        style: GoogleFonts.hankenGrotesk(
                            color: const Color(0xFFF6F3EA),
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: GoogleFonts.hankenGrotesk(
                            color: const Color(0xFFF6F3EA).withValues(alpha: 0.6),
                            fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Paso 1: selección ───────────────────────────────────────────────

  Widget _buildSelectStep() {
    final open = _openTasks;
    final loads = _baseLoads;
    final allSelected = open.isNotEmpty && _selectedTasks.length == open.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel('TAREAS A REDISTRIBUIR · ${_selectedTasks.length}'),
            if (open.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => allSelected
                    ? _selectedTasks.clear()
                    : _selectedTasks.addAll(open.map((t) => t.id))),
                child: Text(allSelected ? 'Quitar todas' : 'Elegir todas',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (open.isEmpty)
          const _InfoBox(text: 'Todas las tareas ya están entregadas o verificadas.')
        else
          ...open.map((t) => _CheckTile(
                selected: _selectedTasks.contains(t.id),
                onTap: () => setState(() => _selectedTasks.contains(t.id)
                    ? _selectedTasks.remove(t.id)
                    : _selectedTasks.add(t.id)),
                title: t.name,
                subtitle: '${_shortName(t.assignedToEmail)} · ${_hours(t)} h',
                trailing: _StatusPill(status: t.status, unassigned: t.assignedToEmail.isEmpty),
              )),
        if (_completedCount > 0) ...[
          const SizedBox(height: 4),
          _InfoBox(
            icon: Icons.info_outline_rounded,
            text: '$_completedCount tarea${_completedCount == 1 ? '' : 's'} entregada'
                '${_completedCount == 1 ? '' : 's'} o verificada${_completedCount == 1 ? '' : 's'} '
                'no se ${_completedCount == 1 ? 'redistribuye' : 'redistribuyen'}, pero sí cuentan '
                'en la carga de quien las hizo.',
          ),
        ],
        const SizedBox(height: 24),
        _SectionLabel('ENTRE QUIÉNES · ${_selectedMembers.length}'),
        const SizedBox(height: 4),
        Text('Desmarca a quien no deba recibir tareas (p. ej. si no puede avanzar).',
            style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text3)),
        const SizedBox(height: 10),
        ..._group.map((email) {
          final load = loads[email] ?? MemberLoad();
          return _CheckTile(
            selected: _selectedMembers.contains(email),
            onTap: () => setState(() => _selectedMembers.contains(email)
                ? _selectedMembers.remove(email)
                : _selectedMembers.add(email)),
            title: _name(email),
            subtitle: 'Carga previa: ${describeLoad(load)}',
            trailing: _isPending(email)
                ? const _Pill(label: 'Pendiente', bg: _warnTint, fg: _warn)
                : null,
          );
        }),
        if (_selectedMembers.any(_isPending))
          const _InfoBox(
            icon: Icons.warning_amber_rounded,
            text: 'Elegiste a alguien con la invitación pendiente: recibirá tareas aunque aún no acepte.',
          ),
      ],
    );
  }

  // ── Paso 2: revisión / asignación manual ────────────────────────────

  Widget _buildReviewStep() {
    final base = _baseLoads;
    final projected = {for (final e in _selectedMembers) e: base[e]?.totalHours ?? 0};
    for (final id in _selectedTasks) {
      final email = _plan[id];
      final task = _task(id);
      if (email != null && task != null) {
        projected[email] = (projected[email] ?? 0) + _hours(task);
      }
    }
    final members = _group.where(_selectedMembers.contains).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        const _SectionLabel('CARGA RESULTANTE'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: members.map((e) {
              final before = base[e]?.totalHours ?? 0;
              final after = projected[e] ?? before;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_name(e),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 13.5, fontWeight: FontWeight.w600, color: _text)),
                    ),
                    Text(after == before ? '$before h' : '$before h → $after h',
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: after > before ? _primary : _text2)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text('Incluye las horas de tareas que ya tenían, también las completadas.',
            style: GoogleFonts.hankenGrotesk(fontSize: 12, color: _text3)),
        const SizedBox(height: 22),
        if (_isAutoPlan && _planUsedFallback) ...[
          const FallbackAssignmentNotice(
            message: 'El modelo de recomendación no respondió: este reparto solo equilibra '
                'las horas de cada estudiante. Revísalo o inténtalo más tarde.',
          ),
          const SizedBox(height: 16),
        ],
        _SectionLabel(_isAutoPlan ? 'REPARTO SUGERIDO' : 'ELIGE RESPONSABLES'),
        const SizedBox(height: 10),
        ..._selectedTasks.map(_task).whereType<ActivityTask>().map((t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _plan[t.id] == null ? _primary : _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
                  const SizedBox(height: 2),
                  Text('${_hours(t)} h · antes: ${_shortName(t.assignedToEmail)}',
                      style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text3)),
                  const SizedBox(height: 6),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _plan[t.id],
                      hint: Text('Elegir responsable',
                          style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _primary)),
                      borderRadius: BorderRadius.circular(14),
                      items: members
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(_name(e),
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _plan[t.id] = v),
                    ),
                  ),
                ],
              ),
            )),
        if (_selectedTasks.any((id) {
          final t = _task(id);
          return t != null && t.status == 'En Progreso' && _plan[id] != t.assignedToEmail;
        }))
          const _InfoBox(
            icon: Icons.info_outline_rounded,
            text: 'Las tareas que cambian de responsable vuelven a "Pendiente". '
                'Comentarios y archivos se conservan.',
          ),
      ],
    );
  }

  // ── Barra inferior ──────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final canPlan = _selectedTasks.isNotEmpty && _selectedMembers.isNotEmpty && !_busy;

    Widget primary(String label, VoidCallback? onTap) => SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _surfaceInset,
              disabledForegroundColor: _text3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: _busy
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: _primary, strokeWidth: 2))
                : Text(label,
                    style: GoogleFonts.hankenGrotesk(fontSize: 14.5, fontWeight: FontWeight.w700)),
          ),
        );

    Widget secondary(String label, VoidCallback? onTap) => SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: _primaryTint,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(label,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: onTap == null ? _text3 : _primary)),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(color: _bg, border: Border(top: BorderSide(color: _border))),
      child: SafeArea(
        top: false,
        child: _step == _Step.select
            ? Row(
                children: [
                  Expanded(child: secondary('Manual', canPlan ? _manualPlan : null)),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: primary('Repartir automáticamente', canPlan ? _autoPlan : null)),
                ],
              )
            : Row(
                children: [
                  Expanded(
                      child: secondary('Atrás',
                          _busy ? null : () => setState(() => _step = _Step.select))),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: primary('Confirmar asignación', _busy ? null : _confirm)),
                ],
              ),
      ),
    );
  }
}

// ── Subwidgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.hankenGrotesk(
          fontSize: 11, fontWeight: FontWeight.w600, color: _text3, letterSpacing: 1.2));
}

class _CheckTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _CheckTile({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _primaryTint : _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _primary : _border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: selected ? _primary : _text3, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text2)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      );
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool unassigned;
  const _StatusPill({required this.status, required this.unassigned});

  @override
  Widget build(BuildContext context) {
    if (unassigned) return const _Pill(label: 'Sin asignar', bg: _warnTint, fg: _warn);
    return status == 'En Progreso'
        ? const _Pill(label: 'En Progreso', bg: _primaryTint, fg: _primary)
        : const _Pill(label: 'Pendiente', bg: _surfaceInset, fg: _text2);
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: GoogleFonts.hankenGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );
}

class _InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoBox({required this.text, this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _surfaceInset, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: _text2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text2, height: 1.4)),
            ),
          ],
        ),
      );
}
