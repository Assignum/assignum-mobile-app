import 'dart:async';
import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/activity_details_page.dart';
import 'package:assignum/core/infrastructure/socket_service.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class ActivitiesListPage extends StatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  State<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  final _service = ActivityService();
  List<Activity> _activities = [];
  bool _loading = true;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load(showSpinner: true);
    SocketService().addActivityListener('activities_list', (_) => _load());
    // Poll every 12s as fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    SocketService().removeListener('activities_list');
    super.dispose();
  }

  // showSpinner=true solo en la carga inicial; las recargas silenciosas no bloquean la UI
  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() { _loading = true; _errorMessage = null; });
    try {
      final acts = await _service.getActivities();
      if (mounted) setState(() { _activities = acts; _loading = false; _errorMessage = null; });
    } catch (_) {
      if (mounted && _activities.isEmpty) {
        setState(() { _loading = false; _errorMessage = 'No se pudo conectar. Desliza hacia abajo para reintentar.'; });
      }
    }
  }

  int _calculateProgress(Activity act) {
    if (act.tasks.isEmpty) return 0;
    int verified = act.tasks.where((t) => t.status == 'Verificado').length;
    return ((verified / act.tasks.length) * 100).toInt();
  }

  Future<void> _delete(String id) async {
    await _service.deleteActivity(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        titleText: 'Tus Actividades',
        showProfileAvatar: true,
      ),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _errorMessage != null
               ? SingleChildScrollView(
                   physics: const AlwaysScrollableScrollPhysics(),
                   child: SizedBox(height: 300, child: Center(child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black26),
                       const SizedBox(height: 12),
                       Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                     ],
                   ))),
                 )
               : _activities.isEmpty
               ? const SingleChildScrollView(
                   physics: AlwaysScrollableScrollPhysics(),
                   child: SizedBox(height: 300, child: Center(child: Text('No hay actividades aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                 )
               : ListView.builder(
                   physics: const AlwaysScrollableScrollPhysics(),
                   padding: const EdgeInsets.all(24),
                   itemCount: _activities.length,
                   itemBuilder: (ctx, i) {
                   final act = _activities[i];
                   return Container(
                     margin: const EdgeInsets.only(bottom: 16),
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                     decoration: BoxDecoration(
                       color: Colors.black.withValues(alpha: 0.08),
                       borderRadius: BorderRadius.circular(24),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(act.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                               const SizedBox(height: 4),
                               Row(
                                 children: [
                                    const Text('Progreso: ', style: TextStyle(fontSize: 14)),
                                    Text('${_calculateProgress(act)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]
                               )
                             ]
                           ),
                         ),
                         Row(
                           children: [
                             ElevatedButton(
                                onPressed: () {
                                   Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsPage(activity: act, isCreationFlow: false)))
                                      .then((_) => _load());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE51D2A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: const Size(60, 36),
                                  elevation: 0,
                                ),
                                child: const Text('Ver', style: TextStyle(fontWeight: FontWeight.bold)),
                             ),
                             IconButton(
                               icon: const Icon(Icons.delete_outline, color: Colors.black54),
                               onPressed: () => _delete(act.id),
                             ),
                           ],
                         )
                       ]
                     )
                   );
                 }
               ),
            ),
      )
    );
  }
}
