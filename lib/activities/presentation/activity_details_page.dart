import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/presentation/fallback_notice.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/task_details_page.dart';
import 'package:assignum/activities/presentation/invite_members_page.dart';
import 'package:assignum/activities/presentation/redistribute_tasks_page.dart';
import 'package:assignum/activities/presentation/create_activity_page.dart' show AddTaskSheet;
import 'package:assignum/activities/domain/workload.dart';
import 'package:assignum/activities/presentation/member_task_page.dart';
import 'package:assignum/core/infrastructure/api_client.dart';

// ── Tokens de color ────────────────────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surface2     = Color(0xFFFFFFFF);
const _surfaceInset = Color(0xFFF0EDE2);
const _text         = Color(0xFF21201B);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);
const _primaryTint  = Color(0xFFFAE7E2);

const _avatarPalette = [
  Color(0xFFDC2F26), Color(0xFF5C7B97), Color(0xFFB26B36),
  Color(0xFF6C8A57), Color(0xFF7B6B9A), Color(0xFF4A8A8A),
];

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;
  final bool isCreationFlow;

  const ActivityDetailsPage({
    super.key,
    required this.activity,
    this.isCreationFlow = false,
  });

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  late bool _showTasks;
  /// Flujo de creación hasta que se dividen las tareas; después la pantalla pasa a la
  /// vista normal (aviso sin ML, Redistribuir, Editar, Finalizar) sin tener que reabrirla.
  late bool _creating;
  String _leaderName = 'Cargando...';
  late Activity _currentActivity;
  StreamSubscription<Activity?>? _activitySub;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _creating = widget.isCreationFlow;
    _showTasks = !_creating;
    _initLeaderName();
    _activitySub = ActivityService()
        .getActivityStreamById(widget.activity.id)
        .listen((updated) {
      if (updated == null || !mounted) return;
      final leaderChanged = updated.uid != _currentActivity.uid;
      setState(() => _currentActivity = updated);
      // Si se cedió el liderazgo, el nombre del líder guardado ya no corresponde
      if (leaderChanged) _refreshLeaderName();
    }, onError: (_) => _onAccessLost());
  }

  /// Firestore deja de entregar la actividad cuando el usuario ya no pertenece a ella (salió,
  /// lo quitaron o se eliminó): se cierra la pantalla en vez de quedarse con datos viejos.
  void _onAccessLost() {
    if (!mounted) return;
    if (!_leaving) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya no tienes acceso a esta actividad')));
    }
    // Cierra lo que haya encima (p. ej. el detalle de una tarea) y luego esta pantalla
    final nav = Navigator.of(context);
    final route = ModalRoute.of(context);
    nav.popUntil((r) => r == route || r.isFirst);
    if (route != null && route.isCurrent && !route.isFirst) nav.pop();
  }

  /// true mientras el propio usuario está saliendo (para no mostrar "ya no tienes acceso").
  bool _leaving = false;

  void _refreshLeaderName() {
    ActivityService().getActivity(_currentActivity.id).then((a) {
      if (!mounted || a == null || a.leaderName.isEmpty) return;
      setState(() => _leaderName = a.leaderName);
    });
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }

  void _initLeaderName() {
    // Always resolve the real name regardless of whether current user is leader
    if (_currentActivity.leaderName.isNotEmpty) {
      _leaderName = _currentActivity.leaderName;
      return;
    }
    ActivityService().getActivity(_currentActivity.id).then((a) {
      if (!mounted) return;
      setState(() => _leaderName =
          (a?.leaderName.isNotEmpty == true) ? a!.leaderName : 'Sin nombre');
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  int _calculateProgress() {
    if (_currentActivity.tasks.isEmpty) return 0;
    return ((_currentActivity.tasks
                    .where((t) => t.status == 'Verificado')
                    .length /
                _currentActivity.tasks.length) *
            100)
        .toInt();
  }

  String get _activityStatus {
    if (_currentActivity.finalized) return 'Completada';
    if (_calculateProgress() > 0) return 'En curso';
    return 'Pendiente';
  }

  int get _memberCount => _currentActivity.acceptedEmails.length + 1;

  String _formatDate(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun',
                    'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _shortName(String name) {
    if (name.isEmpty) return 'Sin asignar';
    if (name.contains('@')) return name.split('@').first;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0]} ${parts[1][0]}.';
    return parts.isNotEmpty ? parts[0] : name;
  }

  String _initials(String name) {
    name = _lettersOnly(name);
    if (name.isEmpty) return '?';
    if (name.contains('@')) return name[0].toUpperCase();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  // ── Finalize logic ──────────────────────────────────────────────────

  Future<void> _finalizeActivity(BuildContext context) async {
    final progress = _calculateProgress();
    if (progress == 100) {
      await _doFinalizeActivity(context);
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _surface2,
        title: Text('¿Finalizar actividad?',
            style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: _text)),
        content: Text(
            'La actividad está al $progress% de progreso. ¿Estás seguro?',
            style: GoogleFonts.hankenGrotesk(color: _text2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.hankenGrotesk(color: _text2, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doFinalizeActivity(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: Text('Finalizar',
                style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _doFinalizeActivity(BuildContext context) async {
    try {
      await ActivityService().finalizeActivity(_currentActivity.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surface2,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EFDC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF6C8A57), size: 32),
              ),
              const SizedBox(height: 16),
              Text('Actividad finalizada',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 8),
              Text('"${_currentActivity.name}" ha sido marcada como finalizada.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text2)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('Aceptar',
                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAssignAnimation() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignAnimationDialog(
        assignFuture: ActivityService().assignTasks(_currentActivity.id),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      setState(() => _creating = false);
      _showDivideSuccessDialog();
    } else if (ok == false) {
      _snack('Error al asignar tareas');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _apiError(Object e) => e is ApiException ? e.message : 'Revisa tu conexión';

  bool get _isLeader => _currentActivity.uid == IAuthFacade.instance.currentUserId;

  /// El líder puede gestionar el grupo mientras la actividad no esté finalizada.
  bool get _canManage => _isLeader && !_currentActivity.finalized;

  // ── Gestión del grupo (después de crearlo) ──────────────────────────

  Future<void> _openInviteMembers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InviteMembersPage(
            activity: _currentActivity, isCreationFlow: false),
      ),
    );
    // El stream de Firestore actualiza la lista de miembros por sí solo.
  }

  Future<void> _openRedistribute({Set<String> initialTaskIds = const {}}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RedistributeTasksPage(
            activity: _currentActivity, initialTaskIds: initialTaskIds),
      ),
    );
  }

  Map<String, MemberLoad> get _loads => computeLoads(_currentActivity.tasks, [
        IAuthFacade.instance.currentUserEmail ?? '',
        ..._currentActivity.acceptedEmails,
        ..._currentActivity.invitedEmails,
      ]);

  /// Tras quitar a alguien, sus tareas abiertas quedan sin asignar: ofrecer repartirlas.
  Future<void> _offerRedistribute(List<String> taskIds) async {
    if (taskIds.isEmpty || !mounted) return;
    final n = taskIds.length;
    final go = await _confirmDialog(
      title: '$n tarea${n == 1 ? '' : 's'} sin asignar',
      message: '¿Quieres repartir ${n == 1 ? 'esa tarea' : 'esas tareas'} ahora entre el resto del grupo?',
      confirmLabel: 'Redistribuir',
      cancelLabel: 'Más tarde',
    );
    if (go == true && mounted) await _openRedistribute(initialTaskIds: taskIds.toSet());
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: _surface2,
          title: Text(title,
              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: _text)),
          content: Text(message, style: GoogleFonts.hankenGrotesk(color: _text2)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelLabel,
                  style: GoogleFonts.hankenGrotesk(color: _text2, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
              ),
              child: Text(confirmLabel,
                  style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  void _showMemberActions(String email, {required bool pending}) {
    final name = pending ? email : _memberName(email);
    final load = _loads[email] ?? MemberLoad();
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 2),
              Text(pending ? 'Invitación pendiente · ${describeLoad(load)}' : describeLoad(load),
                  style: GoogleFonts.hankenGrotesk(fontSize: 13, color: _text3)),
              const SizedBox(height: 12),
              if (pending) ...[
                _SheetAction(
                  icon: Icons.send_outlined,
                  label: 'Reenviar invitación',
                  onTap: () { Navigator.pop(ctx); _resendInvitation(email); },
                ),
                _SheetAction(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelar invitación',
                  destructive: true,
                  onTap: () { Navigator.pop(ctx); _cancelInvitation(email); },
                ),
              ] else ...[
                _SheetAction(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Hacer líder',
                  onTap: () { Navigator.pop(ctx); _transferLeadership(email); },
                ),
                _SheetAction(
                  icon: Icons.person_remove_outlined,
                  label: 'Quitar del grupo',
                  destructive: true,
                  onTap: () { Navigator.pop(ctx); _removeMember(email, load); },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendInvitation(String email) async {
    try {
      await ActivityService().resendInvitation(_currentActivity.id, email);
      _snack('Invitación reenviada a $email');
    } catch (e) {
      _snack('No se pudo reenviar: ${_apiError(e)}');
    }
  }

  Future<void> _cancelInvitation(String email) async {
    final ok = await _confirmDialog(
      title: '¿Cancelar invitación?',
      message: '$email ya no podrá unirse a "${_currentActivity.name}".',
      confirmLabel: 'Cancelar invitación',
      cancelLabel: 'Volver',
    );
    if (ok != true) return;
    try {
      final unassigned = await ActivityService().cancelInvitation(_currentActivity.id, email);
      _snack('Invitación cancelada');
      await _offerRedistribute(unassigned);
    } catch (e) {
      _snack('No se pudo cancelar: ${_apiError(e)}');
    }
  }

  Future<void> _transferLeadership(String email) async {
    final name = _memberName(email);
    final ok = await _confirmDialog(
      title: '¿Hacer líder a $name?',
      message: 'Podrá invitar, asignar y verificar tareas y finalizar la actividad. '
          'Tú pasarás a ser miembro y conservarás tus tareas.',
      confirmLabel: 'Hacer líder',
    );
    if (ok != true) return;
    try {
      await ActivityService().transferLeadership(_currentActivity.id, email);
      _snack('$name ahora es líder de la actividad');
    } catch (e) {
      _snack('No se pudo ceder el liderazgo: ${_apiError(e)}');
    }
  }

  Future<void> _leaveActivity() async {
    final myTasks = _currentActivity.tasks
        .where((t) => t.assignedToEmail == IAuthFacade.instance.currentUserEmail && !t.isCompleted)
        .length;
    final tasksNote = myTasks > 0
        ? ' Tus $myTasks tarea${myTasks == 1 ? '' : 's'} sin terminar quedarán sin asignar.'
        : '';
    final ok = await _confirmDialog(
      title: '¿Salir de la actividad?',
      message: 'Dejarás de ver "${_currentActivity.name}".$tasksNote Se avisará al líder.',
      confirmLabel: 'Salir',
    );
    if (ok != true || !mounted) return;
    final name = _currentActivity.name;
    final messenger = ScaffoldMessenger.of(context);
    _leaving = true;
    try {
      await ActivityService().leaveActivity(_currentActivity.id);
      messenger.showSnackBar(SnackBar(content: Text('Saliste de "$name"')));
      // Puede que la pantalla ya se haya cerrado sola al perder el acceso
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _leaving = false;
      if (mounted) _snack('No se pudo salir: ${_apiError(e)}');
    }
  }

  Future<void> _showEditActivity() async {
    final nameCtrl = TextEditingController(text: _currentActivity.name);
    final linkCtrl = TextEditingController(text: _currentActivity.documentLink);
    var dueDate = _currentActivity.dueDate;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editar actividad',
                  style: GoogleFonts.hankenGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la actividad'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: _text2),
                title: Text('Fecha límite: ${_formatDate(dueDate)} ${dueDate.year}',
                    style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text)),
                trailing: Text('Cambiar',
                    style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700, color: _primary)),
                onTap: () async {
                  final today = DateTime.now();
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate.isBefore(today) ? today : dueDate,
                    firstDate: DateTime(today.year, today.month, today.day),
                    lastDate: DateTime(today.year + 2),
                  );
                  if (picked != null) setSheet(() => dueDate = picked);
                },
              ),
              const SizedBox(height: 4),
              TextField(
                controller: linkCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Enlace del documento (opcional)'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa el nombre')));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('Guardar cambios',
                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;

    final name = nameCtrl.text.trim();
    final link = linkCtrl.text.trim();
    final dateChanged = !DateUtils.isSameDay(dueDate, _currentActivity.dueDate);
    try {
      await ActivityService().updateActivity(
        _currentActivity.id,
        name: name != _currentActivity.name ? name : null,
        dueDate: dateChanged ? dueDate : null,
        documentLink: link != _currentActivity.documentLink ? link : null,
      );
      _snack(dateChanged
          ? 'Actividad actualizada. Se avisó a los miembros del cambio de fecha.'
          : 'Actividad actualizada');
    } catch (e) {
      _snack('No se pudo guardar: ${_apiError(e)}');
    }
  }

  Future<void> _removeMember(String email, MemberLoad load) async {
    final name = _memberName(email);
    final tasksNote = load.activeTasks > 0
        ? ' Sus ${load.activeTasks} tarea${load.activeTasks == 1 ? '' : 's'} sin terminar '
            'quedarán sin asignar.'
        : '';
    final ok = await _confirmDialog(
      title: '¿Quitar a $name?',
      message: 'Dejará de ver la actividad.$tasksNote Las tareas que ya entregó se conservan a su nombre.',
      confirmLabel: 'Quitar',
    );
    if (ok != true) return;
    try {
      final unassigned = await ActivityService().removeMember(_currentActivity.id, email);
      _snack('$name ya no está en el grupo');
      await _offerRedistribute(unassigned);
    } catch (e) {
      _snack('No se pudo quitar: ${_apiError(e)}');
    }
  }

  // ── Agregar tareas después de crear la actividad ────────────────────

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AddTaskSheet(onAdd: _addTask),
    );
  }

  Future<void> _addTask(ActivityTask task) async {
    try {
      final created = await ActivityService().addTasks(_currentActivity.id, [task]);
      if (!mounted) return;
      final assignNow = await _confirmDialog(
        title: 'Tarea agregada',
        message: '"${task.name}" está sin asignar. ¿Quieres asignarla ahora?',
        confirmLabel: 'Asignar',
        cancelLabel: 'Más tarde',
      );
      if (assignNow == true && mounted) {
        await _openRedistribute(initialTaskIds: created.map((t) => t.id).toSet());
      }
    } catch (e) {
      _snack('No se pudo agregar la tarea: ${_apiError(e)}');
    }
  }

  void _showDivideSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surface2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: _primaryTint, borderRadius: BorderRadius.circular(999)),
                child: const Icon(Icons.task_alt_rounded, color: _primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Tareas divididas exitosamente',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); setState(() => _showTasks = true); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('Ver tareas',
                      style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dark extended header ─────────────────────────────────────────────

  Widget _buildHeader() {
    final progress = _calculateProgress();
    final status = _activityStatus;

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HeaderIconBtn(icon: Icons.arrow_back_rounded, label: 'Volver', onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  if (_canManage && !_creating)
                    _HeaderIconBtn(icon: Icons.edit_outlined, label: 'Editar actividad', onTap: _showEditActivity),
                ],
              ),
              const SizedBox(height: 16),
              _HeaderStatusBadge(status: status),
              const SizedBox(height: 10),
              Text(
                _currentActivity.name,
                style: GoogleFonts.hankenGrotesk(
                  color: const Color(0xFFF6F3EA),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetaItem(icon: Icons.calendar_today_outlined, label: _formatDate(_currentActivity.dueDate)),
                  const SizedBox(width: 20),
                  _MetaItem(icon: Icons.people_outline_rounded, label: '$_memberCount ${_memberCount == 1 ? 'miembro' : 'miembros'}'),
                  const SizedBox(width: 20),
                  _MetaItem(icon: Icons.track_changes_rounded, label: '$progress%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Members list ─────────────────────────────────────────────────────

  String _memberName(String email) =>
      _currentActivity.memberNames[email] ??
      _currentActivity.memberNames[email.replaceAll('.', '_')] ??
      email;

  Widget _buildMembersList() {
    final isLeader = _isLeader;
    final accepted = _currentActivity.acceptedEmails;
    final pending = _currentActivity.invitedEmails;
    final loads = isLeader ? _loads : const <String, MemberLoad>{};

    String? loadText(String email) =>
        isLeader ? describeLoad(loads[email] ?? MemberLoad()) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leader
        _MemberTile(
          name: isLeader ? 'Tú' : _leaderName,
          isLeader: true,
          isPending: false,
          index: 0,
          subtitle: loadText(IAuthFacade.instance.currentUserEmail ?? ''),
        ),
        const SizedBox(height: 8),
        // Accepted
        ...accepted.asMap().entries.map((e) {
          final email = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MemberTile(
              name: _memberName(email),
              isLeader: false,
              isPending: false,
              index: e.key + 1,
              subtitle: loadText(email),
              onTap: _canManage ? () => _showMemberActions(email, pending: false) : null,
            ),
          );
        }),
        // Pending invites
        ...pending.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberTile(
                name: e.value,
                isLeader: false,
                isPending: true,
                index: accepted.length + e.key + 1,
                subtitle: loadText(e.value),
                onTap: _canManage ? () => _showMemberActions(e.value, pending: true) : null,
              ),
            )),
        // Invitar más estudiantes (líder, actividad abierta)
        if (_canManage) ...[
          const SizedBox(height: 8),
          _OutlineActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Invitar estudiantes',
            onTap: _openInviteMembers,
          ),
          if (accepted.isNotEmpty || pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Toca a un integrante para reenviar o cancelar su invitación, cederle el liderazgo o quitarlo del grupo.',
                  style: GoogleFonts.hankenGrotesk(fontSize: 12, color: _text3)),
            ),
        ],
        // Un miembro (no líder) puede salir por su cuenta
        if (!isLeader &&
            !_currentActivity.finalized &&
            accepted.contains(IAuthFacade.instance.currentUserEmail)) ...[
          const SizedBox(height: 8),
          _OutlineActionButton(
            icon: Icons.logout_rounded,
            label: 'Salir de la actividad',
            onTap: _leaveActivity,
          ),
        ],
        // Dividir tareas (only in creation flow)
        if (_creating) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _currentActivity.tasks.isEmpty
                  ? null
                  : () => _showAssignAnimation(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _surfaceInset,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                elevation: 0,
              ),
              child: Text('Dividir tareas',
                  style: GoogleFonts.hankenGrotesk(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ],
    );
  }

  // ── Tasks list ───────────────────────────────────────────────────────

  /// Nombre a mostrar para el responsable de una tarea.
  String _assigneeDisplayName(String email) {
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;
    if (email.isEmpty) return 'Sin asignar';
    if (email == currentUserEmail) {
      // Leader name is already resolved in _leaderName (real name, not 'Tú')
      if (_isLeader) return '(Líder) $_leaderName';
      return _currentActivity.memberNames[email] ??
          _currentActivity.memberNames[email.replaceAll('.', '_')] ??
          IAuthFacade.instance.currentUserDisplayName ??
          email;
    }
    if (_currentActivity.acceptedEmails.contains(email)) return _memberName(email);
    // Pending invite — show email
    if (_currentActivity.invitedEmails.contains(email)) return email;
    // Ya no está en el grupo pero conservamos su nombre (tareas que entregó antes de salir)
    if (_currentActivity.memberNames.containsKey(email)) {
      return '${_memberName(email)} (ya no está)';
    }
    // Not a member nor pending — must be the leader
    return '(Líder) $_leaderName';
  }

  Widget _buildTasksHeader(int unassignedCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          if (_currentActivity.assignedWithoutMl) ...[
            FallbackAssignmentNotice(onRedistribute: () => _openRedistribute()),
            const SizedBox(height: 10),
          ],
          if (unassignedCount > 0)
            GestureDetector(
              onTap: () => _openRedistribute(
                initialTaskIds: _currentActivity.tasks
                    .where((t) => t.assignedToEmail.isEmpty && !t.isCompleted)
                    .map((t) => t.id)
                    .toSet(),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E7D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_late_outlined, color: Color(0xFFB26B36), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          '$unassignedCount tarea${unassignedCount == 1 ? '' : 's'} sin asignar',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: const Color(0xFFB26B36))),
                    ),
                    Text('Asignar',
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5, fontWeight: FontWeight.w700, color: _primary)),
                    const Icon(Icons.chevron_right_rounded, color: _primary, size: 20),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _OutlineActionButton(
                  icon: Icons.add_rounded,
                  label: 'Agregar tarea',
                  onTap: _showAddTask,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OutlineActionButton(
                  icon: Icons.shuffle_rounded,
                  label: 'Redistribuir',
                  onTap: _currentActivity.tasks.any((t) => !t.isCompleted)
                      ? () => _openRedistribute()
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    final isLeader = _isLeader;
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;
    final tasks = _currentActivity.tasks;
    final showHeader = _canManage && !_creating;

    if (tasks.isEmpty) {
      return ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        children: [
          if (showHeader) _buildTasksHeader(0),
          const SizedBox(height: 40),
          Center(
            child: Text('Sin tareas aún',
                style: GoogleFonts.hankenGrotesk(color: _text3, fontSize: 14)),
          ),
        ],
      );
    }

    final unassignedCount =
        tasks.where((t) => t.assignedToEmail.isEmpty && !t.isCompleted).length;

    return ListView.builder(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16),
      itemCount: tasks.length + (showHeader ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (showHeader && index == 0) return _buildTasksHeader(unassignedCount);
        final task = tasks[showHeader ? index - 1 : index];
        final canTap = isLeader || task.assignedToEmail == currentUserEmail;

        final displayName = _assigneeDisplayName(task.assignedToEmail);
        const leftSuffix = ' (ya no está)';
        final shortDisplay = displayName == 'Sin asignar' ||
                displayName.startsWith('(Líder)')
            ? displayName
            : displayName.endsWith(leftSuffix)
                ? '${_shortName(displayName.substring(0, displayName.length - leftSuffix.length))}$leftSuffix'
                : _shortName(displayName);

        return _TaskCard(
          task: task,
          displayName: shortDisplay,
          avatarInitials: _initials(displayName),
          onTap: canTap
              ? () async {
                  if (isLeader) {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TaskDetailsPage(
                          activity: _currentActivity, task: task, assigneeName: displayName),
                    ));
                  } else {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MemberTaskPage(
                          activity: _currentActivity, task: task, assigneeName: displayName),
                    ));
                  }
                }
              : null,
        );
      },
    );
  }

  // ── Bottom finalize button ───────────────────────────────────────────

  Widget _buildFinalizeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      color: _bg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _finalizeActivity(context),
            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            label: Text('Finalizar actividad',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    final showFinalize = isLeader && !_currentActivity.finalized && !_creating;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          _buildHeader(),
          // Segmented control
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SegmentedControl(
              showTasks: _showTasks,
              onSelect: (v) => setState(() => _showTasks = v),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _showTasks
                  ? _buildTasksList()
                  : SingleChildScrollView(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 16),
                      child: _buildMembersList(),
                    ),
            ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: showFinalize ? _buildFinalizeBar() : null,
    );
  }
}

/// Quita prefijos como "(Líder)" para que las iniciales salgan del nombre real.
String _lettersOnly(String name) =>
    name.replaceAll(RegExp(r'\(.*?\)'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

// ── Subwidgets ─────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String label;
  const _HeaderIconBtn({required this.icon, required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: const Color(0xFFF6F3EA), size: 20, semanticLabel: label),
        ),
      );
}

class _HeaderStatusBadge extends StatelessWidget {
  final String status;
  const _HeaderStatusBadge({required this.status});

  Color get _badgeBg => switch (status) {
        'En curso'   => const Color(0xFF3D1918),
        'Pendiente'  => const Color(0xFF3D2D1A),
        'Completada' => const Color(0xFF1D2B18),
        _            => const Color(0xFF2F2D27),
      };

  Color get _badgeText => switch (status) {
        'En curso'   => const Color(0xFFFF9B91),
        'Pendiente'  => const Color(0xFFE8A87C),
        'Completada' => const Color(0xFF9FCC7E),
        _            => const Color(0xFFA8A599),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _badgeBg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: _badgeText, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(status,
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _badgeText)),
          ],
        ),
      );
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF9A8E7E)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, color: const Color(0xFFBBB5A8))),
        ],
      );
}

class _SegmentedControl extends StatelessWidget {
  final bool showTasks;
  final ValueChanged<bool> onSelect;
  const _SegmentedControl({required this.showTasks, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surfaceInset, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            _Segment(label: 'Miembros', active: !showTasks, onTap: () => onSelect(false)),
            _Segment(label: 'Tareas',   active: showTasks,  onTap: () => onSelect(true)),
          ],
        ),
      );
}

class _Segment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? _surface2 : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: active
                  ? [BoxShadow(
                      color: const Color(0xFF3C321E).withValues(alpha: 0.08),
                      blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _text : _text3,
                )),
          ),
        ),
      );
}

class _TaskCard extends StatelessWidget {
  final ActivityTask task;
  final String displayName;
  final String avatarInitials;
  final VoidCallback? onTap;

  const _TaskCard({
    required this.task,
    required this.displayName,
    required this.avatarInitials,
    required this.onTap,
  });

  bool get _isVerified => task.status == 'Verificado';

  Color get _avatarBg => switch (task.status) {
        'Verificado'  => const Color(0xFFE7EFDC),
        'Entregado'   => const Color(0xFFE4EAF1),
        'En Progreso' => const Color(0xFFFAE7E2),
        _             => const Color(0xFFF4E7D6),
      };

  Color get _avatarFg => switch (task.status) {
        'Verificado'  => const Color(0xFF6C8A57),
        'Entregado'   => const Color(0xFF5C7B97),
        'En Progreso' => const Color(0xFFDC2F26),
        _             => const Color(0xFFB26B36),
      };

  String get _badgeLabel => task.status;

  Color get _badgeBg => switch (task.status) {
        'Verificado'  => const Color(0xFFE7EFDC),
        'Entregado'   => const Color(0xFFE4EAF1),
        'En Progreso' => const Color(0xFFFAE7E2),
        _             => const Color(0xFFF4E7D6),
      };

  Color get _badgeText => switch (task.status) {
        'Verificado'  => const Color(0xFF6C8A57),
        'Entregado'   => const Color(0xFF5C7B97),
        'En Progreso' => const Color(0xFFDC2F26),
        _             => const Color(0xFFB26B36),
      };

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3C321E).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon / avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _avatarBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _isVerified
                    ? Icon(Icons.check_rounded, color: _avatarFg, size: 22)
                    : Text(avatarInitials,
                        style: GoogleFonts.hankenGrotesk(
                            color: _avatarFg, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.name,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.5, fontWeight: FontWeight.w700, color: _text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: _text3),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(displayName,
                              style: GoogleFonts.hankenGrotesk(fontSize: 12.5, color: _text3),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _badgeBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: _badgeText, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(_badgeLabel,
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 11.5, fontWeight: FontWeight.w600, color: _badgeText)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final String name;
  final bool isLeader;
  final bool isPending;
  final int index;
  final String? subtitle;
  final VoidCallback? onTap;
  const _MemberTile({
    required this.name,
    required this.isLeader,
    required this.isPending,
    required this.index,
    this.subtitle,
    this.onTap,
  });

  String _initials() {
    final name = _lettersOnly(this.name);
    if (name.isEmpty) return '?';
    if (name.contains('@')) return name[0].toUpperCase();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarPalette[index % _avatarPalette.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(_initials(),
                style: GoogleFonts.hankenGrotesk(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _text),
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!,
                      style: GoogleFonts.hankenGrotesk(fontSize: 12, color: _text3),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isLeader)
            _Pill(label: 'Líder', bg: _primaryTint, fg: _primary),
          if (isPending)
            _Pill(label: 'Pendiente', bg: const Color(0xFFF4E7D6), fg: const Color(0xFFB26B36)),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.more_vert_rounded, size: 18, color: _text3),
          ],
        ],
      ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? _primary : _text;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label,
          style: GoogleFonts.hankenGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _OutlineActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity, height: 46,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: onTap == null ? _text3 : _primary),
          label: Text(label,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: onTap == null ? _text3 : _primary)),
          style: OutlinedButton.styleFrom(
            backgroundColor: onTap == null ? _surfaceInset : _primaryTint,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
      );
}

// ── Assign animation dialog ────────────────────────────────────────────────────

class _AssignAnimationDialog extends StatefulWidget {
  final Future<void> assignFuture;
  const _AssignAnimationDialog({required this.assignFuture});

  @override
  State<_AssignAnimationDialog> createState() => _AssignAnimationDialogState();
}

class _AssignAnimationDialogState extends State<_AssignAnimationDialog>
    with SingleTickerProviderStateMixin {

  static const _steps = [
    ('Recopilando datos de los estudiantes...', Icons.people_outline_rounded),
    ('Analizando habilidades del equipo...', Icons.psychology_outlined),
    ('Identificando al mejor candidato...', Icons.manage_search_rounded),
    ('Asignando de manera equitativa...', Icons.auto_awesome_outlined),
    ('¡Todo listo!', Icons.check_circle_outline_rounded),
  ];

  int _step = 0;
  bool _apiDone = false;
  late AnimationController _spinCtrl;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startSteps();
    widget.assignFuture.then((_) {
      _apiDone = true;
      _tryFinish();
    }).catchError((_) {
      if (mounted) Navigator.of(context).pop(false);
    });
  }

  void _startSteps() {
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1300), (t) {
      if (!mounted) { t.cancel(); return; }
      // Pausar en el último paso animado hasta que la API termine
      if (_step >= _steps.length - 2) {
        t.cancel();
        _tryFinish();
        return;
      }
      setState(() => _step++);
    });
  }

  void _tryFinish() {
    if (!_apiDone || !mounted) return;
    setState(() => _step = _steps.length - 1);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = _step == _steps.length - 1;
    final (label, icon) = _steps[_step];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF4),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C321E).withValues(alpha: 0.12),
              blurRadius: 32, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner / checkmark
            SizedBox(
              width: 80, height: 80,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: isDone
                    ? Container(
                        key: const ValueKey('done'),
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDDF0E4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Color(0xFF4A8C6A), size: 40),
                      )
                    : Stack(
                        key: const ValueKey('spin'),
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _spinCtrl,
                            child: CustomPaint(
                              size: const Size(80, 80),
                              painter: _ArcPainter(),
                            ),
                          ),
                          Container(
                            width: 56, height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAE7E2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: _primary, size: 26),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // Steps completados
            ...List.generate(_step, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF4A8C6A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _steps[i].$1,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF9A978C),
                        decoration: TextDecoration.lineThrough,
                        decorationColor: const Color(0xFF9A978C),
                      ),
                    ),
                  ),
                ],
              ),
            )),

            // Paso actual
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Row(
                key: ValueKey(_step),
                children: [
                  if (!isDone) ...[
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFF4A8C6A)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDone
                            ? const Color(0xFF4A8C6A)
                            : const Color(0xFF21201B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0x00DC2F26), Color(0xFFDC2F26)],
      ).createShader(rect);
    canvas.drawArc(rect, 0, 5.5, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter _) => false;
}
