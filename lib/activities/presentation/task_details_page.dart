import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';

class TaskDetailsPage extends StatelessWidget {
  final Activity activity;
  final String taskName;
  final String assignedTo;

  const TaskDetailsPage({
    super.key,
    required this.activity,
    required this.taskName,
    required this.assignedTo,
  });

  void _showSuccessDialog(BuildContext context) {
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
                  '$taskName Verificada\nExitosamente',
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

  @override
  Widget build(BuildContext context) {
    final dateStr = '${activity.dueDate.day.toString().padLeft(2,'0')}/${activity.dueDate.month.toString().padLeft(2,'0')}/${activity.dueDate.year.toString().substring(2)}';
    
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
                        taskName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text('Asignada a: $assignedTo', style: const TextStyle(fontSize: 14)),
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
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('Status: Finalizada (Sin Verificar)', style: TextStyle(fontSize: 16)),
                       const SizedBox(height: 8),
                       Text('Fecha: $dateStr', style: const TextStyle(fontSize: 16)),
                       const SizedBox(height: 8),
                       const Text('Enlace al documento:', style: TextStyle(fontSize: 16)),
                       const SizedBox(height: 40),
                       Center(
                         child: Text(
                           activity.documentLink.isEmpty ? 'https://docs.google.com/document/d/1lN-_eA9eBeD5-M...' : activity.documentLink,
                           textAlign: TextAlign.center,
                           style: const TextStyle(fontSize: 14),
                         ),
                       ),
                       const Spacer(),
                       Center(
                         child: ElevatedButton(
                           onPressed: () => _showSuccessDialog(context),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: const Color(0xFFE51D2A),
                             foregroundColor: Colors.white,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(24),
                             ),
                             padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                           ),
                           child: const Text('Verificado', style: TextStyle(fontSize: 16)),
                         ),
                       )
                     ]
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
