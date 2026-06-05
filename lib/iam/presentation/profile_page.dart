import 'package:flutter/material.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _userService.getProfile();
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  Future<void> _editField(String title, String initialValue, Function(String) onSave, {bool isNumeric = false, List<String>? options}) async {
    String value = initialValue;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar $title'),
        content: Form(
          key: formKey,
          child: options != null
              ? DropdownButtonFormField<String>(
                  initialValue: value,
                  items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => value = v ?? value,
                )
              : TextFormField(
                  initialValue: initialValue,
                  keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(labelText: title),
                  onChanged: (v) => value = v,
                  validator: (v) => v == null || v.isEmpty ? 'El campo es requerido' : null,
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) { Navigator.pop(ctx); onSave(value); }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileAndReload(UserProfile newProfile) async {
    setState(() => _loading = true);
    await _userService.createOrUpdateProfile(newProfile);
    await _loadProfile();
  }

  Widget _buildFieldRow(String label, String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis)),
                ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE51D2A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(60, 32),
                    elevation: 0,
                  ),
                  child: const Text('Editar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final name = _profile?.fullName ?? AuthSession().email ?? 'Usuario';
    final email = AuthSession().email ?? 'Sin correo';

    return Scaffold(
      appBar: const PremiumAppBar(titleText: 'Perfiles'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    CircleAvatar(backgroundColor: Colors.grey[400], radius: 30),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFieldRow('Nombre', name, () {
                      _editField('Nombre', name, (val) async {
                        if (_profile != null) {
                          await _updateProfileAndReload(UserProfile(
                            uid: _profile!.uid, fullName: val, birthDate: _profile!.birthDate,
                            disponibilidad: _profile!.disponibilidad, cargaAcademica: _profile!.cargaAcademica,
                            trabajoEnEquipo: _profile!.trabajoEnEquipo, comunicacion: _profile!.comunicacion, horasEstudio: _profile!.horasEstudio,
                          ));
                        }
                      });
                    }),
                    _buildFieldRow('Correo electrónico', email, () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambia tu correo desde la configuración de tu cuenta.')));
                    }),
                    if (_profile != null) ...[
                      _buildFieldRow('Disponibilidad', _profile!.disponibilidad, () {
                        _editField('Disponibilidad', _profile!.disponibilidad, (val) async {
                          await _updateProfileAndReload(UserProfile(uid: _profile!.uid, fullName: _profile!.fullName, birthDate: _profile!.birthDate, disponibilidad: val, cargaAcademica: _profile!.cargaAcademica, trabajoEnEquipo: _profile!.trabajoEnEquipo, comunicacion: _profile!.comunicacion, horasEstudio: _profile!.horasEstudio));
                        }, options: ['Mañana', 'Tarde', 'Noche', 'Fin de semana']);
                      }),
                      _buildFieldRow('Carga académica', _profile!.cargaAcademica, () {
                        _editField('Carga académica', _profile!.cargaAcademica, (val) async {
                          await _updateProfileAndReload(UserProfile(uid: _profile!.uid, fullName: _profile!.fullName, birthDate: _profile!.birthDate, disponibilidad: _profile!.disponibilidad, cargaAcademica: val, trabajoEnEquipo: _profile!.trabajoEnEquipo, comunicacion: _profile!.comunicacion, horasEstudio: _profile!.horasEstudio));
                        }, options: ['Ligera', 'Media', 'Alta']);
                      }),
                      _buildFieldRow('Trabajo en equipo', _profile!.trabajoEnEquipo.toString(), () {
                        _editField('Trabajo en equipo (1-5)', _profile!.trabajoEnEquipo.toString(), (val) async {
                          final num = int.tryParse(val) ?? 3;
                          await _updateProfileAndReload(UserProfile(uid: _profile!.uid, fullName: _profile!.fullName, birthDate: _profile!.birthDate, disponibilidad: _profile!.disponibilidad, cargaAcademica: _profile!.cargaAcademica, trabajoEnEquipo: num.clamp(1, 5), comunicacion: _profile!.comunicacion, horasEstudio: _profile!.horasEstudio));
                        }, isNumeric: true);
                      }),
                      _buildFieldRow('Comunicación', _profile!.comunicacion.toString(), () {
                        _editField('Comunicación (1-5)', _profile!.comunicacion.toString(), (val) async {
                          final num = int.tryParse(val) ?? 3;
                          await _updateProfileAndReload(UserProfile(uid: _profile!.uid, fullName: _profile!.fullName, birthDate: _profile!.birthDate, disponibilidad: _profile!.disponibilidad, cargaAcademica: _profile!.cargaAcademica, trabajoEnEquipo: _profile!.trabajoEnEquipo, comunicacion: num.clamp(1, 5), horasEstudio: _profile!.horasEstudio));
                        }, isNumeric: true);
                      }),
                      _buildFieldRow('Horas de estudio semanales', _profile!.horasEstudio.toString(), () {
                        _editField('Horas de estudio', _profile!.horasEstudio.toString(), (val) async {
                          final num = int.tryParse(val) ?? 10;
                          await _updateProfileAndReload(UserProfile(uid: _profile!.uid, fullName: _profile!.fullName, birthDate: _profile!.birthDate, disponibilidad: _profile!.disponibilidad, cargaAcademica: _profile!.cargaAcademica, trabajoEnEquipo: _profile!.trabajoEnEquipo, comunicacion: _profile!.comunicacion, horasEstudio: num.clamp(0, 168)));
                        }, isNumeric: true);
                      }),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE51D2A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('Cerrar', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
