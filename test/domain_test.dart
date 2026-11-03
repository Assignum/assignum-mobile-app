import 'package:flutter_test/flutter_test.dart';
import 'package:assignum/activities/domain/activity.dart';
import 'package:assignum/activities/domain/activity_task.dart';
import 'package:assignum/activities/domain/inbox_item.dart';
import 'package:assignum/activities/domain/workload.dart';

ActivityTask task(String id, String email, String status, int hours) => ActivityTask(
      id: id,
      name: 'Tarea $id',
      assignedToEmail: email,
      status: status,
      estimatedHours: hours,
    );

void main() {
  group('Carga de trabajo', () {
    final tasks = [
      task('1', 'ana@upc.edu.pe', 'Verificado', 10),
      task('2', 'ana@upc.edu.pe', 'Entregado', 2),
      task('3', 'beto@upc.edu.pe', 'En Progreso', 4),
      task('4', 'beto@upc.edu.pe', 'Pendiente', 3),
      task('5', '', 'Pendiente', 5),
      task('6', 'fuera@upc.edu.pe', 'Pendiente', 8),
    ];

    test('las tareas completadas cuentan como carga', () {
      final loads = computeLoads(tasks, ['ana@upc.edu.pe', 'beto@upc.edu.pe']);
      expect(loads['ana@upc.edu.pe']!.completedHours, 12);
      expect(loads['ana@upc.edu.pe']!.activeHours, 0);
      expect(loads['beto@upc.edu.pe']!.activeHours, 7);
      expect(loads['beto@upc.edu.pe']!.totalTasks, 2);
    });

    test('ignora tareas sin asignar, de otras personas o excluidas', () {
      final loads = computeLoads(tasks, ['beto@upc.edu.pe'], excludeTaskIds: {'4'});
      expect(loads.length, 1);
      expect(loads['beto@upc.edu.pe']!.totalHours, 4);
    });

    test('describe la carga para mostrarla', () {
      final loads = computeLoads(tasks, ['ana@upc.edu.pe', 'nadie@upc.edu.pe']);
      expect(describeLoad(loads['ana@upc.edu.pe']!), '2 tareas · 12 h (12 h completadas)');
      expect(describeLoad(loads['nadie@upc.edu.pe']!), 'Sin tareas');
    });
  });

  group('Modelos', () {
    test('Entregado y Verificado son completadas', () {
      expect(task('a', '', 'Entregado', 1).isCompleted, isTrue);
      expect(task('b', '', 'Verificado', 1).isCompleted, isTrue);
      expect(task('c', '', 'En Progreso', 1).isCompleted, isFalse);
    });

    test('Activity.fromMap tolera campos faltantes', () {
      final a = Activity.fromMap({'id': 'x', 'name': 'Proyecto', 'tasks': null});
      expect(a.name, 'Proyecto');
      expect(a.tasks, isEmpty);
      expect(a.acceptedEmails, isEmpty);
      expect(a.finalized, isFalse);
    });

    test('ActivityTask.fromMap convierte archivos y enlaces', () {
      final t = ActivityTask.fromMap({
        'id': 't1',
        'name': 'Informe',
        'files': ['https://a/1.pdf', 'https://a/2.png'],
        'links': [],
        'estimatedHours': 3,
      });
      expect(t.files, 'https://a/1.pdf\nhttps://a/2.png');
      expect(t.links, '');
      expect(t.estimatedHours, 3);
      expect(t.toCreationMap()['name'], 'Informe');
    });

    test('InboxItem.fromMap lee un aviso del backend', () {
      final item = InboxItem.fromMap({
        'id': 'n1',
        'type': 'task_assigned',
        'title': 'Nueva tarea asignada',
        'body': 'En "Proyecto": Informe',
        'activityId': 'act-1',
        'read': false,
        'createdAt': '2026-11-03T10:00:00.000Z',
      });
      expect(item.read, isFalse);
      expect(item.createdAt.toUtc().hour, 10);
    });
  });
}
