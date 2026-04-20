import 'package:flutter/material.dart';
import 'package:assignum/models/activity.dart';
import 'package:assignum/widgets/ui.dart';
import 'package:assignum/pages/task_details_page.dart';

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;
  final bool isCreationFlow;
  
  const ActivityDetailsPage({super.key, required this.activity, this.isCreationFlow = false});

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  late bool _showTasks;

  @override
  void initState() {
    super.initState();
    // Si NO estamos creando (o sea, si entramos desde "Tus Actividades"), de frente mostramos las Tareas.
    // Si estamos creando, iniciamos en los miembros para que podamos presionar el botón de "Dividir Tareas" primero.
    _showTasks = !widget.isCreationFlow;
  }

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
                const Text(
                  'Tareas Divididas\nExitosamente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Siguiente',
                  onPressed: () {
                    Navigator.pop(ctx); 
                    setState(() {
                      _showTasks = true;
                    });
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersList() {
    return Column(
      children: [
        const Text('Lista de Miembros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.activity.invitedEmails.length + 1, 
            itemBuilder: (ctx, i) {
               String member = i == 0 ? 'Tú (Líder)' : widget.activity.invitedEmails[i - 1].split('@').first;
               return Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 padding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.08),
                   borderRadius: BorderRadius.circular(30),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Text(
                         member, 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     ElevatedButton(
                        onPressed: () {},
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
        ),
        if (widget.isCreationFlow) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.activity.tasks.isEmpty ? null : _showSuccessDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE51D2A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text('Dividir Tareas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ]
      ]
    );
  }

  Widget _buildTasksList() {
    // Collect all members to evenly distribute tasks
    final allMembers = ['Tú (Líder)', ...widget.activity.invitedEmails.map((e) => e.split('@').first)];
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             const Text('Puntos a realizar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             ElevatedButton(
               onPressed: () => setState(() => _showTasks = false),
               style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFE51D2A),
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                 minimumSize: const Size(60, 32),
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                 elevation: 0,
               ),
               child: const Text('Miembros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
             )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: widget.activity.tasks.length, 
            itemBuilder: (ctx, i) {
               String taskName = widget.activity.tasks[i];
               String assignedTo = allMembers[i % allMembers.length];
               return Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 padding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.08),
                   borderRadius: BorderRadius.circular(30),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(
                             taskName, 
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                             overflow: TextOverflow.ellipsis,
                           ),
                           Text(
                             'Asignada a: $assignedTo',
                             style: const TextStyle(fontSize: 13, color: Colors.black87),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ]
                       )
                     ),
                     ElevatedButton(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsPage(
                              activity: widget.activity,
                              taskName: taskName,
                              assignedTo: assignedTo,
                           )));
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
        ),
      ]
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
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.12),
                   borderRadius: BorderRadius.circular(30),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.center,
                   children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              widget.activity.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('DL: ${widget.activity.dueDate.day}/${widget.activity.dueDate.month}/${widget.activity.dueDate.year}', style: const TextStyle(fontSize: 14)),
                        ]
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Text('Progreso: ', style: TextStyle(fontSize: 16)),
                           Text('0%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Team Leader: Tú', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                   ]
                 )
               ),
               const SizedBox(height: 24),
               Expanded(
                 child: CardContainer(
                   child: _showTasks ? _buildTasksList() : _buildMembersList(),
                 )
               )
            ]
          )
        )
      )
    );
  }
}
