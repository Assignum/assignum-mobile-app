import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/member_task_page.dart';

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

const _avatarPalette = [
  Color(0xFF4A8A8A), Color(0xFF5C7B97), Color(0xFF6C8A57),
  Color(0xFFDC2F26), Color(0xFF7B6B9A), Color(0xFFB26B36),
];

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

  // ── Helpers ─────────────────────────────────────────────────────────

  List<String> get _fileList => _currentTask.files.trim().isEmpty
      ? []
      : _currentTask.files
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();

  List<String> get _linkList => _currentTask.links.trim().isEmpty
      ? []
      : _currentTask.links
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();

  bool get _canApprove => _currentTask.status == 'Entregado';
  bool get _isVerified => _currentTask.status == 'Verificado';
  bool get _isLeader => widget.activity.uid == IAuthFacade.instance.currentUserId;

  String _statusLabel(String status) => status;

  Color _statusBadgeBg(String status) => switch (status) {
        'Verificado'  => const Color(0xFFE7EFDC),
        'Entregado'   => const Color(0xFFE4EAF1),
        'En Progreso' => const Color(0xFFFAE7E2),
        _             => const Color(0xFFF4E7D6), // Pendiente
      };

  Color _statusBadgeText(String status) => switch (status) {
        'Verificado'  => const Color(0xFF6C8A57),
        'Entregado'   => const Color(0xFF5C7B97),
        'En Progreso' => const Color(0xFFDC2F26),
        _             => const Color(0xFFB26B36), // Pendiente
      };

  IconData _statusBadgeIcon(String status) => switch (status) {
        'Verificado'  => Icons.check_circle_outline_rounded,
        'Entregado'   => Icons.upload_outlined,
        'En Progreso' => Icons.play_circle_outline_rounded,
        _             => Icons.radio_button_unchecked_rounded,
      };

  Color _avatarColor(String name) {
    if (name.isEmpty) return _avatarPalette[0];
    return _avatarPalette[name.codeUnitAt(0) % _avatarPalette.length];
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    if (name.contains('@')) return name[0].toUpperCase();
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String _assigneeSubtitle(String status) => switch (status) {
        'Verificado'  => 'Trabajo verificado',
        'Entregado'   => 'Entregó el trabajo',
        'En Progreso' => 'En progreso',
        _             => 'Aún no entregado',
      };

  // ── Approve task ────────────────────────────────────────────────────

  Future<void> _approveTask(BuildContext context) async {
    try {
      await ActivityService().verifyTaskDirectly(
          widget.activity.id, _currentTask.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _primary),
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
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF6C8A57), size: 32),
              ),
              const SizedBox(height: 16),
              Text('Tarea aprobada',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 8),
              Text('"${_currentTask.name}" ha sido marcada como verificada.',
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
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

  // ── Navigate to edit ─────────────────────────────────────────────────

  Future<void> _openModify(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberTaskPage(
          activity: widget.activity,
          task: _currentTask,
          assigneeName: widget.assigneeName,
        ),
      ),
    );
    final updated = await ActivityService()
        .getActivityFromFirestore(widget.activity.id);
    if (updated != null && mounted) {
      final idx = updated.tasks.indexWhere((t) => t.id == _currentTask.id);
      if (idx != -1) setState(() => _currentTask = updated.tasks[idx]);
    }
  }

  // ── Build sections ───────────────────────────────────────────────────

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verificar entrega',
                      style: GoogleFonts.hankenGrotesk(
                        color: const Color(0xFFF6F3EA),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('Vista de líder',
                      style: GoogleFonts.hankenGrotesk(
                        color: const Color(0xFFF6F3EA).withValues(alpha: 0.6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard() {
    final status = _currentTask.status;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C321E).withValues(alpha: 0.07),
            blurRadius: 14, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TAREA',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _text3, letterSpacing: 1.2,
                  )),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBadgeBg(status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusBadgeIcon(status),
                        size: 13, color: _statusBadgeText(status)),
                    const SizedBox(width: 4),
                    Text(_statusLabel(status),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11.5, fontWeight: FontWeight.w600,
                          color: _statusBadgeText(status),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Task name
          Text(_currentTask.name,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: _text, height: 1.2,
              )),
          const SizedBox(height: 14),
          Divider(color: _border, height: 1),
          const SizedBox(height: 14),
          // Assignee row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _avatarColor(widget.assigneeName),
                child: Text(
                  _initials(widget.assigneeName),
                  style: GoogleFonts.hankenGrotesk(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.assigneeName,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                  Text(_assigneeSubtitle(status),
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 12.5, color: _text3)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEntregables() {
    final files = _fileList;
    final links = _linkList;
    if (files.isEmpty && links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ENTREGABLES',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: _text3, letterSpacing: 1.2,
            )),
        const SizedBox(height: 10),
        ...files.map((f) => _EntregableRow(
              url: f.trim(),
              isImage: ActivityService.isImageUrl(f.trim()),
              title: ActivityService.filenameFromUrl(f.trim()),
            )),
        ...links.map((l) => _EntregableRow(
              url: l.trim(),
              isImage: false,
              isLink: true,
              title: _shortenUrl(l.trim()),
            )),
      ],
    );
  }

  Widget _buildComentario() {
    final comment = _currentTask.comments.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COMENTARIO DEL MIEMBRO',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: _text3, letterSpacing: 1.2,
            )),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceInset,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            comment.isEmpty ? 'Sin comentarios.' : '"$comment"',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14, color: comment.isEmpty ? _text3 : _text2,
              fontStyle: comment.isEmpty ? FontStyle.normal : FontStyle.italic,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: (_isVerified && !_isLeader)
            // Verified + not leader — read-only message
            ? Row(
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: Color(0xFF6C8A57)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tarea verificada por líder, no se puede modificar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6C8A57),
                      ),
                    ),
                  ),
                ],
              )
            // Leader (any status) or non-leader + not verified — show Modificar + Aprobar
            : Row(
                children: [
                  // Modificar (outlined)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _openModify(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _text,
                          side: BorderSide(color: _border, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text('Modificar',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: _text2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Aprobar (filled)
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _canApprove
                            ? () => _approveTask(context)
                            : null,
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                        label: Text('Aprobar',
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          disabledBackgroundColor: _surfaceInset,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Helpers para entregables ─────────────────────────────────────────

  String _shortenUrl(String url) {
    return url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .replaceFirst('www.', '');
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskCard(),
                  if (_fileList.isNotEmpty || _linkList.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildEntregables(),
                  ],
                  const SizedBox(height: 24),
                  _buildComentario(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
        ),
      ),
    );
  }
}

// ── Entregable row widget ──────────────────────────────────────────────

class _EntregableRow extends StatelessWidget {
  final String url;
  final String title;
  final bool isImage;
  final bool isLink;

  const _EntregableRow({
    required this.url,
    required this.title,
    required this.isImage,
    this.isLink = false,
  });

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7E2D5)),
        ),
        child: Column(
          children: [
            // Vista previa de imagen
            if (isImage)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  url,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 160,
                          color: const Color(0xFFF0EDE2),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFDC2F26), strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: const Color(0xFFF0EDE2),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Color(0xFF9A978C), size: 32),
                    ),
                  ),
                ),
              ),
            // Fila inferior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: isLink
                          ? const Color(0xFFE4EAF1)
                          : isImage
                              ? const Color(0xFFDDF0E4)
                              : const Color(0xFFFAE7E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isLink
                          ? Icons.link_rounded
                          : isImage
                              ? Icons.image_outlined
                              : Icons.description_outlined,
                      color: isLink
                          ? const Color(0xFF5C7B97)
                          : isImage
                              ? const Color(0xFF4A8C6A)
                              : const Color(0xFFDC2F26),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF21201B),
                            ),
                            overflow: TextOverflow.ellipsis),
                        Text(
                          isLink
                              ? 'Toca para abrir'
                              : isImage
                                  ? 'Toca para ver en pantalla completa'
                                  : 'Toca para descargar',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: const Color(0xFF9A978C)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isImage
                        ? Icons.open_in_full_rounded
                        : Icons.open_in_new_rounded,
                    color: const Color(0xFF9A978C),
                    size: 18,
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
