import 'package:assignum/iam/infrastructure/user_service.dart';
import 'package:flutter/material.dart';
import 'package:assignum/iam/domain/user_profile.dart';
import 'package:assignum/core/infrastructure/auth_session.dart';
import 'package:assignum/shared/presentation/widgets/ui.dart';
import 'package:assignum/shared/presentation/widgets/premium_app_bar.dart';

class AboutYouPage extends StatefulWidget {
  final bool cameFromRegister;
  final String? initialName;
  final DateTime? initialBirthDate;

  const AboutYouPage({
    super.key,
    this.cameFromRegister = false,
    this.initialName,
    this.initialBirthDate,
  });

  @override
  State<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends State<AboutYouPage> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _nameCtrl = TextEditingController();

  final _disponibilidadOpts = const ['Mañana', 'Tarde', 'Noche', 'Fin de semana'];
  final _cargaOpts = const ['Ligera', 'Media', 'Alta'];

  DateTime? _birthDate;
  String _disponibilidad = 'Mañana';
  String _cargaAcademica = 'Media';
  double _trabajoEnEquipo = 3;
  double _comunicacion = 3;
  double _horasEstudio = 10;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) _nameCtrl.text = widget.initialName!;
    if (widget.initialBirthDate != null) _birthDate = widget.initialBirthDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10, 12, 31),
      initialDate: DateTime(now.year - 20, now.month, now.day),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final uid = AuthSession().uid ?? '';

    final profile = UserProfile(
      uid: uid,
      fullName: _nameCtrl.text.trim(),
      birthDate: _birthDate,
      disponibilidad: _disponibilidad,
      cargaAcademica: _cargaAcademica,
      trabajoEnEquipo: _trabajoEnEquipo.round(),
      comunicacion: _comunicacion.round(),
      horasEstudio: _horasEstudio.round(),
    );

    await _userService.createOrUpdateProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(titleText: 'Háblanos de ti'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nombre completo
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre completo' : null,
                  ),
                  const SizedBox(height: 16),

                  // Fecha de nacimiento
                  InkWell(
                    onTap: _pickBirthDate,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _birthDate == null
                                ? 'Seleccionar fecha'
                                : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                          ),
                          const Icon(Icons.calendar_today_outlined),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Disponibilidad
                  DropdownButtonFormField<String>(
                    initialValue: _disponibilidad,
                    items: _disponibilidadOpts
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _disponibilidad = v!),
                    decoration: const InputDecoration(labelText: 'Disponibilidad'),
                  ),
                  const SizedBox(height: 12),

                  // Carga académica
                  DropdownButtonFormField<String>(
                    initialValue: _cargaAcademica,
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
                    min: 1, max: 5, divisions: 4,
                    label: _trabajoEnEquipo.round().toString(),
                    onChanged: (v) => setState(() => _trabajoEnEquipo = v),
                  ),

                  Text('Comunicación (${_comunicacion.round()}/5)'),
                  Slider(
                    value: _comunicacion,
                    min: 1, max: 5, divisions: 4,
                    label: _comunicacion.round().toString(),
                    onChanged: (v) => setState(() => _comunicacion = v),
                  ),

                  Text('Horas de estudio por semana (${_horasEstudio.round()})'),
                  Slider(
                    value: _horasEstudio,
                    min: 0, max: 60, divisions: 60,
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
