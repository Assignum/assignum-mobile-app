import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';
import 'package:assignum/activities/presentation/activity_details_page.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class ActivitiesListPage extends StatelessWidget {
  const ActivitiesListPage({super.key});

  int _calculateProgress(Activity act) {
    if (act.tasks.isEmpty) return 0;
    return ((act.tasks.where((t) => t.status == 'Verificado').length / act.tasks.length) * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(titleText: 'Tus Actividades', showProfileAvatar: true),
      body: SafeArea(
        child: StreamBuilder<List<Activity>>(
          stream: ActivityService().getActivitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.black26),
                    const SizedBox(height: 12),
                    const Text('No se pudo conectar', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            }
            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return const Center(child: Text('No hay actividades aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: activities.length,
              itemBuilder: (ctx, i) {
                final act = activities[i];
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
                            Row(children: [
                              const Text('Progreso: ', style: TextStyle(fontSize: 14)),
                              Text('${_calculateProgress(act)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ]),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ActivityDetailsPage(activity: act, isCreationFlow: false),
                            )),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE51D2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              minimumSize: const Size(60, 36),
                              elevation: 0,
                            ),
                            child: const Text('Ver', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.black54),
                            onPressed: () => ActivityService().deleteActivity(act.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
