import 'package:assignum/activities/domain/activity_task.dart';

/// Carga de trabajo (horas estimadas) de un estudiante dentro de una actividad.
class MemberLoad {
  int activeHours = 0;
  int activeTasks = 0;
  int completedHours = 0;
  int completedTasks = 0;

  int get totalHours => activeHours + completedHours;
  int get totalTasks => activeTasks + completedTasks;
}

/// Misma regla que el backend: las tareas completadas también cuentan como carga, para
/// que quien terminó antes no reciba más por ello. [excludeTaskIds] ignora las tareas
/// que se van a repartir de nuevo.
Map<String, MemberLoad> computeLoads(
  List<ActivityTask> tasks,
  Iterable<String> emails, {
  Set<String> excludeTaskIds = const {},
}) {
  final loads = {for (final e in emails) e: MemberLoad()};
  for (final t in tasks) {
    if (t.assignedToEmail.isEmpty || excludeTaskIds.contains(t.id)) continue;
    final load = loads[t.assignedToEmail];
    if (load == null) continue;
    final hours = t.estimatedHours > 0 ? t.estimatedHours : 1;
    if (t.isCompleted) {
      load.completedHours += hours;
      load.completedTasks += 1;
    } else {
      load.activeHours += hours;
      load.activeTasks += 1;
    }
  }
  return loads;
}

String describeLoad(MemberLoad load) {
  if (load.totalTasks == 0) return 'Sin tareas';
  final tasks = '${load.totalTasks} tarea${load.totalTasks == 1 ? '' : 's'}';
  final done = load.completedHours > 0 ? ' (${load.completedHours} h completadas)' : '';
  return '$tasks · ${load.totalHours} h$done';
}
