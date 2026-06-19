import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/activity_details_page.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

// ── Tokens de color (modo claro) ──────────────────────────────────────
const _bg           = Color(0xFFF4F2EA);
const _surface      = Color(0xFFFBFAF4);
const _surfaceInset = Color(0xFFF0EDE2);
const _text         = Color(0xFF21201B);
const _text2        = Color(0xFF6E6B61);
const _text3        = Color(0xFF9A978C);
const _border       = Color(0xFFE7E2D5);
const _primary      = Color(0xFFDC2F26);
const _primaryTint  = Color(0xFFFAE7E2);

const _avatarPalette = [
  Color(0xFFDC2F26),
  Color(0xFF5C7B97),
  Color(0xFFB26B36),
  Color(0xFF6C8A57),
  Color(0xFF7B6B9A),
  Color(0xFF4A8A8A),
];

class ActivitiesListPage extends StatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  State<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  String _filter = 'Todas';

  int _calculateProgress(Activity act) {
    if (act.tasks.isEmpty) return 0;
    return ((act.tasks.where((t) => t.status == 'Verificado').length /
                act.tasks.length) *
            100)
        .toInt();
  }

  String _getStatus(Activity act) {
    if (act.finalized) return 'Completada';
    final hasActive = act.tasks.any((t) =>
        t.status == 'En Progreso' ||
        t.status == 'Entregado' ||
        t.status == 'Verificado');
    if (hasActive) return 'En curso';
    return 'Pendiente';
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: PremiumAppBar(
        titleText: 'Actividades',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.search_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Activity>>(
        stream: ActivityService().getActivitiesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: _text3),
                  const SizedBox(height: 12),
                  Text('No se pudo conectar',
                      style: GoogleFonts.hankenGrotesk(
                          color: _text2, fontSize: 15)),
                ],
              ),
            );
          }

          final all = snapshot.data ?? [];

          if (all.isEmpty) {
            return Center(
              child: Text(
                'No hay actividades aún',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _text2),
              ),
            );
          }

          final filtered = _filter == 'Todas'
              ? all
              : all.where((a) => _getStatus(a) == _filter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Chips de filtro ──────────────────────────────────
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _FilterChip(
                      label: 'Todas · ${all.length}',
                      active: _filter == 'Todas',
                      onTap: () => setState(() => _filter = 'Todas'),
                    ),
                    _FilterChip(
                      label: 'En curso',
                      active: _filter == 'En curso',
                      onTap: () => setState(() => _filter = 'En curso'),
                    ),
                    _FilterChip(
                      label: 'Completadas',
                      active: _filter == 'Completada',
                      onTap: () => setState(() => _filter = 'Completada'),
                    ),
                    _FilterChip(
                      label: 'Pendiente',
                      active: _filter == 'Pendiente',
                      onTap: () => setState(() => _filter = 'Pendiente'),
                    ),
                  ],
                ),
              ),
              // ── Lista ────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Sin actividades en este estado',
                          style: GoogleFonts.hankenGrotesk(
                              fontSize: 14, color: _text3),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final act = filtered[i];
                          return _ActivityCard(
                            activity: act,
                            progress: _calculateProgress(act),
                            status: _getStatus(act),
                            formattedDate: _formatDate(act.dueDate),
                            initials: _getInitials(act.name),
                            avatarColor:
                                _avatarPalette[i % _avatarPalette.length],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailsPage(
                                    activity: act, isCreationFlow: false),
                              ),
                            ),
                            onDelete: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                backgroundColor: const Color(0xFFFBFAF4),
                                title: Text('Eliminar actividad',
                                    style: GoogleFonts.hankenGrotesk(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF21201B))),
                                content: Text(
                                    '¿Estás seguro de que quieres eliminar "${act.name}"?',
                                    style: GoogleFonts.hankenGrotesk(
                                        color: const Color(0xFF6E6B61))),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('Cancelar',
                                        style: GoogleFonts.hankenGrotesk(
                                            color: const Color(0xFF6E6B61),
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ActivityService().deleteActivity(act.id);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2F26),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999)),
                                      elevation: 0,
                                    ),
                                    child: Text('Eliminar',
                                        style: GoogleFonts.hankenGrotesk(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _primaryTint : _surface,
          border: Border.all(
            color: active
                ? _primary.withValues(alpha: 0.35)
                : _border,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? _primary : _text2,
          ),
        ),
      ),
    );
  }
}

// ── Activity card ──────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final int progress;
  final String status;
  final String formattedDate;
  final String initials;
  final Color avatarColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ActivityCard({
    required this.activity,
    required this.progress,
    required this.status,
    required this.formattedDate,
    required this.initials,
    required this.avatarColor,
    required this.onTap,
    required this.onDelete,
  });

  Color get _statusText => switch (status) {
        'En curso'   => const Color(0xFFDC2F26),
        'Pendiente'  => const Color(0xFFB26B36),
        'Completada' => const Color(0xFF6C8A57),
        _            => _text2,
      };

  Color get _statusTint => switch (status) {
        'En curso'   => const Color(0xFFFAE7E2),
        'Pendiente'  => const Color(0xFFF4E7D6),
        'Completada' => const Color(0xFFE7EFDC),
        _            => _surfaceInset,
      };

  Color get _barColor => switch (status) {
        'En curso'   => const Color(0xFFDC2F26),
        'Pendiente'  => const Color(0xFFB26B36),
        'Completada' => const Color(0xFF6C8A57),
        _            => _text3,
      };

  int get _memberCount => activity.acceptedEmails.length + 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3C321E).withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: avatarColor,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.hankenGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Contenido ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + badge de estado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _text,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _statusText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _statusText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: _text3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Miembros
                  Text(
                    '$_memberCount miembro${_memberCount == 1 ? '' : 's'}',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 13, color: _text3),
                  ),
                  const SizedBox(height: 10),
                  // % completado + fecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$progress% completado',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _text2,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: _text3),
                          const SizedBox(width: 3),
                          Text(
                            formattedDate,
                            style: GoogleFonts.hankenGrotesk(
                                fontSize: 12.5, color: _text3),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 9,
                      backgroundColor: _surfaceInset,
                      valueColor: AlwaysStoppedAnimation(_barColor),
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
