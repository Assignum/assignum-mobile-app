import 'package:flutter/material.dart';
import 'package:assignum/models/activity.dart';
import 'package:assignum/widgets/ui.dart';

class MemberTaskPage extends StatefulWidget {
  final Activity activity;
  final String taskName;
  final String assignedTo;

  const MemberTaskPage({
    super.key,
    required this.activity,
    required this.taskName,
    required this.assignedTo,
  });

  @override
  State<MemberTaskPage> createState() => _MemberTaskPageState();
}

class _MemberTaskPageState extends State<MemberTaskPage> {
  void _showSuccessDialog() {
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
                  '${widget.taskName} Finalizada\ncorrectamente',
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

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
    );
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
                        widget.taskName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text('Asignada a: ${widget.assignedTo}', style: const TextStyle(fontSize: 14)),
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
                   child: SingleChildScrollView(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildFieldTitle('Status'),
                         Container(
                           height: 45,
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           decoration: BoxDecoration(
                             color: Colors.black.withOpacity(0.08),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const SizedBox(), 
                               const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 28),
                             ],
                           )
                         ),
                         _buildFieldTitle('Comentarios'),
                         _buildTextField(),
                         _buildFieldTitle('Archivos'),
                         _buildTextField(),
                         _buildFieldTitle('Enlaces'),
                         _buildTextField(),
                         const SizedBox(height: 32),
                         Center(
                           child: ElevatedButton(
                             onPressed: _showSuccessDialog,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFFE51D2A),
                               foregroundColor: Colors.white,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(24),
                               ),
                               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                               elevation: 0,
                             ),
                             child: const Text('Finalizar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                           ),
                         )
                       ]
                     )
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
