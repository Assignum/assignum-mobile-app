import 'package:flutter/material.dart';
import 'package:assignum/models/activity.dart';
import 'package:assignum/services/activity_service.dart';
import 'package:assignum/pages/activity_details_page.dart';

class ActivitiesListPage extends StatefulWidget {
  const ActivitiesListPage({super.key});

  @override
  State<ActivitiesListPage> createState() => _ActivitiesListPageState();
}

class _ActivitiesListPageState extends State<ActivitiesListPage> {
  final _service = ActivityService();
  List<Activity> _activities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final acts = await _service.getActivities();
    if (mounted) {
      setState(() {
        _activities = acts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus Actividades', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.grey[600],
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
               backgroundColor: Colors.grey[300],
               radius: 16,
            ),
          )
        ],
      ),
      body: SafeArea(
        child: _loading 
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty 
             ? const Center(child: Text('No hay actividades aún', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
             : ListView.builder(
                 padding: const EdgeInsets.all(24),
                 itemCount: _activities.length,
                 itemBuilder: (ctx, i) {
                   final act = _activities[i];
                   return Container(
                     margin: const EdgeInsets.only(bottom: 16),
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                     decoration: BoxDecoration(
                       color: Colors.black.withOpacity(0.08),
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
                               const Row(
                                 children: [
                                    Text('Progreso: ', style: TextStyle(fontSize: 14)),
                                    Text('0%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                 ]
                               )
                             ]
                           ),
                         ),
                         ElevatedButton(
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsPage(activity: act, isCreationFlow: false)));
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
                         )
                       ]
                     )
                   );
                 }
               )
      )
    );
  }
}
