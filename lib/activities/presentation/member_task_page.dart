import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/domain/auth_facade.dart';

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
const _primaryTint  = Color(0xFFFAE7E2);

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

class _PendingFile {
  final File file;
  final String name;
  _PendingFile({required this.file, required this.name});
}

class _MemberTaskPageState extends State<MemberTaskPage> {
  late String _status;
  final _commentsCtrl = TextEditingController();
  late List<String> _files;          // URLs ya guardadas en Firestore
  late List<String> _links;
  final List<_PendingFile> _pending = []; // Archivos locales sin subir aún
  bool _saving = false;
  late bool _isLeader;

  bool get _isReadOnly => widget.task.status == 'Verificado' && !_isLeader;

  static const _memberStatuses = ['Pendiente', 'En Progreso', 'Entregado'];

  @override
  void initState() {
    super.initState();
    _isLeader = widget.activity.uid == IAuthFacade.instance.currentUserId;
    _status = widget.task.status;
    if (!_memberStatuses.contains(_status) && _status != 'Verificado') {
      _status = 'Pendiente';
    }
    _commentsCtrl.text = widget.task.comments;
    _files = _toList(widget.task.files);
    _links = _toList(widget.task.links);
  }

  @override
  void dispose() {
    _commentsCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  List<String> _toList(String value) => value.trim().isEmpty
      ? []
      : value.split('\n').where((s) => s.trim().isNotEmpty).toList();

  String _toText(List<String> list) => list.join('\n');

  int get _activityProgress {
    if (widget.activity.tasks.isEmpty) return 0;
    return ((widget.activity.tasks.where((t) => t.status == 'Verificado').length /
                widget.activity.tasks.length) *
            100)
        .toInt();
  }

  String _formatDate(DateTime d) {
    const months = ['ene','feb','mar','abr','may','jun',
                    'jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _saveTask() async {
    setState(() => _saving = true);
    try {
      // Subir archivos pendientes a Cloudinary
      for (final p in _pending) {
        final url = await ActivityService().uploadTaskFile(
          widget.activity.id,
          widget.task.id,
          p.file,
          p.name,
        );
        _files.add(url);
      }
      _pending.clear();

      await ActivityService().updateTaskDirectly(
        widget.activity.id,
        widget.task.id,
        status: _status,
        comments: _commentsCtrl.text,
        files: _toText(_files),
        links: _toText(_links),
      );
      if (mounted) {
        setState(() => _saving = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: _primary),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
              Text('Avance guardado',
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _text)),
              const SizedBox(height: 8),
              Text('Tu progreso ha sido actualizado.',
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

  // ── File upload ──────────────────────────────────────────────────────

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    // Solo se guarda localmente — la subida ocurre al presionar Guardar
    setState(() => _pending.add(
        _PendingFile(file: File(picked.path!), name: picked.name)));
  }

  // ── Add attachment sheet ─────────────────────────────────────────────

  void _showAddAttachment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AddAttachmentSheet(
        onPickFile: () {
          // Cerrar el sheet primero y esperar a que termine la animación
          // antes de abrir el picker del sistema (evita timing issue en Android)
          Navigator.pop(ctx);
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) _pickAndUploadFile();
          });
        },
        onAddLink: (url) => setState(() => _links.add(url)),
      ),
    );
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mi tarea',
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(widget.task.name,
                        style: GoogleFonts.hankenGrotesk(
                          color: const Color(0xFFF6F3EA).withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _activityProgress;
    final dueDate = widget.activity.dueDate;

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
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 72, height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress / 100,
                  strokeWidth: 6,
                  backgroundColor: _surfaceInset,
                  valueColor: const AlwaysStoppedAnimation(_primary),
                  strokeCap: StrokeCap.round,
                ),
                Text('$progress%',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _text)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_status == 'Verificado' ? 'Verificado' : _status,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
                const SizedBox(height: 2),
                Text('Entrega: ${_formatDate(dueDate)}',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5, color: _text3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    final hasItems = _files.isNotEmpty || _links.isNotEmpty || _pending.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Archivos ya guardados (URLs de Cloudinary)
        ..._files.asMap().entries.map((e) => _AttachmentRow(
              url: e.value,
              isImage: ActivityService.isImageUrl(e.value),
              title: ActivityService.filenameFromUrl(e.value),
              onRemove: _isReadOnly
                  ? null
                  : () => setState(() => _files.removeAt(e.key)),
            )),
        // Links
        ..._links.asMap().entries.map((e) => _AttachmentRow(
              url: e.value,
              isImage: false,
              title: e.value
                  .replaceFirst('https://', '')
                  .replaceFirst('http://', ''),
              isLink: true,
              onRemove: _isReadOnly
                  ? null
                  : () => setState(() => _links.removeAt(e.key)),
            )),
        // Archivos pendientes (locales, aún no subidos)
        ..._pending.asMap().entries.map((e) => _PendingFileRow(
              pending: e.value,
              onRemove: () => setState(() => _pending.removeAt(e.key)),
            )),
        // Empty hint
        if (!hasItems && !_isReadOnly)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceInset,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text('Sin archivos ni enlaces adjuntos',
                  style: GoogleFonts.hankenGrotesk(fontSize: 13, color: _text3)),
            ),
          ),
        if (!_isReadOnly) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _showAddAttachment,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.attach_file_rounded, size: 18, color: _text2),
                  const SizedBox(width: 8),
                  Text('Añadir archivo o enlace',
                      style: GoogleFonts.hankenGrotesk(
                          fontSize: 14, fontWeight: FontWeight.w600, color: _text2)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComment() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _commentsCtrl,
        enabled: !_isReadOnly,
        maxLines: 4,
        style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          hintText: 'Escribe un comentario para el líder...',
          hintStyle: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text3),
        ),
      ),
    );
  }

  Widget _eyebrow(String label) => Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: _text3, letterSpacing: 1.2,
        ),
      );

  Widget _buildBottomBar() {
    if (_isReadOnly) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: BoxDecoration(
          color: _bg, border: Border(top: BorderSide(color: _border))),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: Color(0xFF6C8A57)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tarea verificada por líder, no se puede modificar',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.5, fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C8A57),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: _bg, border: Border(top: BorderSide(color: _border))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text('Guardar avance',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

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
                  // Progress card
                  _buildProgressCard(),
                  const SizedBox(height: 24),
                  // Status selector (hidden when verified)
                  if (!_isReadOnly) ...[
                    _eyebrow('ESTADO DE LA TAREA'),
                    const SizedBox(height: 10),
                    _StatusSelector(
                      selected: _memberStatuses.contains(_status)
                          ? _status
                          : 'Pendiente',
                      onSelect: (v) => setState(() => _status = v),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Attachments
                  _eyebrow('ADJUNTAR TRABAJO'),
                  const SizedBox(height: 10),
                  _buildAttachments(),
                  const SizedBox(height: 24),
                  // Comment
                  _eyebrow('COMENTARIO PARA EL LÍDER'),
                  const SizedBox(height: 10),
                  _buildComment(),
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

// ── Status segmented control ───────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _StatusSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = ['Pendiente', 'En Progreso', 'Entregado'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceInset, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: options.map((opt) {
          final active = selected == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
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
                child: Text(
                  opt == 'En Progreso' ? 'En curso' : opt,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _text : _text3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Pending file row (local, aún no subido) ───────────────────────────

class _PendingFileRow extends StatelessWidget {
  final _PendingFile pending;
  final VoidCallback onRemove;

  const _PendingFileRow({required this.pending, required this.onRemove});

  bool get _isImage {
    final ext = pending.name.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDC2F26).withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          // Preview local para imágenes
          if (_isImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.file(
                pending.file,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upload_outlined, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pending.name,
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 13.5, fontWeight: FontWeight.w600,
                              color: _text),
                          overflow: TextOverflow.ellipsis),
                      Text('Pendiente de guardar',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 12, color: _primary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: _text3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attachment row ─────────────────────────────────────────────────────

class _AttachmentRow extends StatelessWidget {
  final String url;
  final String title;
  final bool isImage;
  final bool isLink;
  final VoidCallback? onRemove;

  const _AttachmentRow({
    required this.url,
    required this.title,
    required this.isImage,
    this.isLink = false,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Si es imagen, muestra la miniatura arriba
          if (isImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Image.network(
                url,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 140,
                        color: _surfaceInset,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: _primary, strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: _surfaceInset,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: _text3, size: 32),
                  ),
                ),
              ),
            ),
          // Fila inferior con nombre y botón de eliminar
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
                            : _primaryTint,
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
                            : _primary,
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
                              color: _text),
                          overflow: TextOverflow.ellipsis),
                      Text(
                        isLink ? 'Enlace' : isImage ? 'Imagen' : 'Archivo',
                        style: GoogleFonts.hankenGrotesk(
                            fontSize: 12, color: _text3),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: _text3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add attachment bottom sheet ────────────────────────────────────────
// Muestra dos opciones: subir archivo (picker) o añadir enlace (texto).

class _AddAttachmentSheet extends StatefulWidget {
  final VoidCallback onPickFile;
  final void Function(String url) onAddLink;

  const _AddAttachmentSheet({
    required this.onPickFile,
    required this.onAddLink,
  });

  @override
  State<_AddAttachmentSheet> createState() => _AddAttachmentSheetState();
}

class _AddAttachmentSheetState extends State<_AddAttachmentSheet> {
  bool _showLinkInput = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 20),
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
          Text('Añadir adjunto',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _text)),
          const SizedBox(height: 16),

          if (!_showLinkInput) ...[
            // Opción 1: subir archivo
            _OptionTile(
              icon: Icons.upload_file_rounded,
              iconBg: const Color(0xFFFAE7E2),
              iconColor: _primary,
              title: 'Subir archivo',
              subtitle: 'PDF, imagen, Word…',
              onTap: widget.onPickFile,
            ),
            const SizedBox(height: 10),
            // Opción 2: enlace
            _OptionTile(
              icon: Icons.link_rounded,
              iconBg: const Color(0xFFE4EAF1),
              iconColor: const Color(0xFF5C7B97),
              title: 'Añadir enlace',
              subtitle: 'Google Drive, YouTube, etc.',
              onTap: () => setState(() => _showLinkInput = true),
            ),
          ] else ...[
            // Input enlace
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: TextInputType.url,
                style: GoogleFonts.hankenGrotesk(fontSize: 14, color: _text),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  hintText: 'https://...',
                  hintStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 14, color: _text3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final val = _ctrl.text.trim();
                  if (val.isNotEmpty) {
                    widget.onAddLink(val);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                  elevation: 0,
                ),
                child: Text('Añadir enlace',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: iconBg,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.hankenGrotesk(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                Text(subtitle, style: GoogleFonts.hankenGrotesk(
                    fontSize: 12, color: _text3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: _text3),
        ],
      ),
    ),
  );
}

