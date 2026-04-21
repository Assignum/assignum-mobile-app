import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';

class AboutYouPage extends StatefulWidget {
  final String fullName;
  final DateTime? birthDate;
  final bool cameFromRegister;

  const AboutYouPage({
    super.key,
    required this.fullName,
    required this.birthDate,
    this.cameFromRegister = false,
  });

  @override
  State<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends State<AboutYouPage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _disponibilidadOpts = const ['Mañana', 'Tarde', 'Noche', 'Fin de semana'];
  final _cargaOpts = const ['Ligera', 'Media', 'Alta'];

  String _disponibilidad = 'Mañana';
  String _cargaAcademica = 'Media';
  double _trabajoEnEquipo = 3; // 1–5
  double _comunicacion = 3;    // 1–5
  double _horasEstudio = 10;   // 0–60
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final profile = UserProfile(
      uid: uid,
      fullName: widget.fullName,
      birthDate: widget.birthDate,
      disponibilidad: _disponibilidad,
      cargaAcademica: _cargaAcademica,
      trabajoEnEquipo: _trabajoEnEquipo.round(),
      comunicacion: _comunicacion.round(),
      horasEstudio: _horasEstudio.round(),
    );

    await _userService.createOrUpdateProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Háblanos de ti')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _disponibilidad,
                    items: _disponibilidadOpts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _disponibilidad = v!),
                    decoration: const InputDecoration(labelText: 'Disponibilidad'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _cargaAcademica,
                    items: _cargaOpts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _cargaAcademica = v!),
                    decoration: const InputDecoration(labelText: 'Carga académica'),
                  ),
                  const SizedBox(height: 20),

                  Text('Trabajo en equipo (${_trabajoEnEquipo.round()}/5)'),
                  Slider(
                    value: _trabajoEnEquipo,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _trabajoEnEquipo.round().toString(),
                    onChanged: (v) => setState(() => _trabajoEnEquipo = v),
                  ),
                  const SizedBox(height: 12),

                  Text('Comunicación (${_comunicacion.round()}/5)'),
                  Slider(
                    value: _comunicacion,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _comunicacion.round().toString(),
                    onChanged: (v) => setState(() => _comunicacion = v),
                  ),
                  const SizedBox(height: 12),

                  Text('Horas de estudio por semana (${_horasEstudio.round()})'),
                  Slider(
                    value: _horasEstudio,
                    min: 0,
                    max: 60,
                    divisions: 60,
                    label: _horasEstudio.round().toString(),
                    onChanged: (v) => setState(() => _horasEstudio = v),
                  ),
                  const SizedBox(height: 20),

                  PrimaryButton(
                    text: _saving ? 'Guardando...' : 'Registrarte',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
