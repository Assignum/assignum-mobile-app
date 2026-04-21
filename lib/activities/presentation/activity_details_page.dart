import 'package:flutter/material.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/activities/presentation/task_details_page.dart';
import 'package:assignum/activities/presentation/member_task_page.dart';
import 'package:assignum/activities/domain/auth_facade.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/infrastructure/activity_service.dart';

class ActivityDetailsPage extends StatefulWidget {
  final Activity activity;
  final bool isCreationFlow;
  
  const ActivityDetailsPage({super.key, required this.activity, this.isCreationFlow = false});

  @override
  State<ActivityDetailsPage> createState() => _ActivityDetailsPageState();
}

class _ActivityDetailsPageState extends State<ActivityDetailsPage> {
  late bool _showTasks;
  String _leaderName = 'Cargando...';
  late Activity _currentActivity;

  @override
  void initState() {
    super.initState();
    _currentActivity = widget.activity;
    _showTasks = !widget.isCreationFlow;
    _fetchLeaderName();
  }

  Future<void> _fetchLeaderName() async {
    bool isLeaderSession = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    if (isLeaderSession) {
      if (mounted) setState(() => _leaderName = 'Tú');
      return;
    }
    
    final name = await IAuthFacade.instance.getUserName(_currentActivity.uid);
    if (mounted) {
       setState(() {
         _leaderName = name ?? 'Líder';
       });
    }
  }

  int _calculateProgress() {
    if (_currentActivity.tasks.isEmpty) return 0;
    int verified = _currentActivity.tasks.where((t) => t.status == 'Verificado').length;
    return ((verified / _currentActivity.tasks.length) * 100).toInt();
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
    final present = _currentActivity.acceptedEmails;
    final pending = _currentActivity.invitedEmails;
    
    return Column(
      children: [
        const Text('Lista de Miembros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: present.length + pending.length + 1, 
            itemBuilder: (ctx, i) {
               String memberText = '';
               bool isLeader = false;
               
               if (i == 0) {
                 bool isSessionLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
                 memberText = isSessionLeader ? 'Tú (Líder)' : '$_leaderName (Líder)';
                 isLeader = true;
               } else if (i <= present.length) {
                 final m = present[i - 1];
                 final name = _currentActivity.memberNames[m.replaceAll('.', '_')] ?? m;
                 memberText = name;
               } else {
                 final m = pending[i - 1 - present.length];
                 memberText = '$m (Pendiente)';
               }
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
                         memberText, 
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                     if (!isLeader)
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
              onPressed: _currentActivity.tasks.isEmpty ? null : () async {
                final presentEmails = _currentActivity.acceptedEmails;
                final leaderEmail = IAuthFacade.instance.currentUserEmail ?? _currentActivity.uid;
                final allEmails = [leaderEmail, ...presentEmails, ..._currentActivity.invitedEmails];

                for (int i = 0; i < _currentActivity.tasks.length; i++) {
                  _currentActivity.tasks[i] = _currentActivity.tasks[i].copyWith(
                    assignedToEmail: allEmails[i % allEmails.length],
                  );
                }
                
                await ActivityService().updateActivity(_currentActivity);
                _showSuccessDialog();
              },
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
    bool isSessionLeader = _currentActivity.uid == IAuthFacade.instance.currentUserId;
    final currentUserEmail = IAuthFacade.instance.currentUserEmail;

    List<ActivityTask> displayTasks = _currentActivity.tasks;
    
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
            itemCount: displayTasks.length, 
            itemBuilder: (ctx, i) {
               final task = displayTasks[i];
               String taskName = task.name;
               String assignedToEmail = task.assignedToEmail;
               String displayName = assignedToEmail;

               if (assignedToEmail == currentUserEmail) {
                   displayName = isSessionLeader ? 'Tú (Líder)' : 'Tú';
               } else if (!_currentActivity.invitedEmails.contains(assignedToEmail) && !_currentActivity.acceptedEmails.contains(assignedToEmail)) {
                   displayName = '$_leaderName (Líder)';
               } else {
                   displayName = _currentActivity.memberNames[assignedToEmail.replaceAll('.', '_')] ?? assignedToEmail;
               }

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
                             'Asignada a: $displayName',
                             style: const TextStyle(fontSize: 13, color: Colors.black87),
                             overflow: TextOverflow.ellipsis,
                           ),
                         ]
                       )
                     ),
                     if (isSessionLeader || assignedToEmail == currentUserEmail)
                       ElevatedButton(
                          onPressed: () {
                             if (isSessionLeader) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsPage(
                                   activity: _currentActivity,
                                   task: task,
                                   assigneeName: displayName,
                                )));
                             } else {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => MemberTaskPage(
                                   activity: _currentActivity,
                                   task: task,
                                   assigneeName: displayName,
                                )));
                             }
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
        child: StreamBuilder<Activity?>(
          stream: ActivityService().getActivityStream(widget.activity.id),
          initialData: _currentActivity,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
               _currentActivity = snapshot.data!;
            }

            return Padding(
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
                                  _currentActivity.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('DL: ${_currentActivity.dueDate.day}/${_currentActivity.dueDate.month}/${_currentActivity.dueDate.year}', style: const TextStyle(fontSize: 14)),
                            ]
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                               const Text('Progreso: ', style: TextStyle(fontSize: 16)),
                               Text('${_calculateProgress()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Team Leader: $_leaderName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            );
          }
        )
      )
    );
  }
}
