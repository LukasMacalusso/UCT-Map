import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _lostItemsAlerts = true;
  bool _reportsAlerts = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionHeader('Notificaciones y Alertas'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.fieldBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.uctBlue),
                  title: const Text('Notificaciones Push'),
                  subtitle: const Text('Recibir avisos en tu dispositivo'),
                  value: _pushNotifications,
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                  },
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
                SwitchListTile(
                  secondary: const Icon(Icons.email_outlined,
                      color: AppColors.uctBlue),
                  title: const Text('Alertas por Correo Institucional'),
                  subtitle: const Text('Enviar copias a tu cuenta @uct.cl'),
                  value: _emailNotifications,
                  onChanged: (val) {
                    setState(() => _emailNotifications = val);
                  },
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
                SwitchListTile(
                  secondary: const Icon(Icons.find_in_page_outlined,
                      color: Color(0xFF16A34A)),
                  title: const Text('Objetos Encontrados'),
                  subtitle: const Text('Avisarme de inmediato si encuentran mi objeto'),
                  value: _lostItemsAlerts,
                  onChanged: (val) {
                    setState(() => _lostItemsAlerts = val);
                  },
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
                SwitchListTile(
                  secondary: const Icon(Icons.construction_outlined,
                      color: Color(0xFFEA580C)),
                  title: const Text('Avances de Incidencias'),
                  subtitle: const Text('Avisar cuando se resuelvan mis reportes'),
                  value: _reportsAlerts,
                  onChanged: (val) {
                    setState(() => _reportsAlerts = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Apariencia e Interfaz'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.fieldBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined,
                      color: AppColors.uctBlue),
                  title: const Text('Modo Oscuro'),
                  subtitle: const Text('Ajustar a paleta oscura de alto contraste'),
                  value: _darkMode,
                  onChanged: (val) {
                    setState(() => _darkMode = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? 'Modo oscuro activado (simulado)'
                            : 'Modo claro activado'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.uctBlue),
                  title: const Text('Idioma'),
                  subtitle: const Text('Español (Chile)'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Idioma predeterminado: Español (Chile)'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Cuenta y Privacidad'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.fieldBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.uctBlue),
                  title: const Text('Seguridad y Contraseña'),
                  subtitle: const Text('Información de acceso a UCT Map'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Contraseña de UCT Map',
                      'Estas cuentas pertenecen a UCT Map. La recuperación de contraseña aún no está disponible en la aplicación.',
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
                ListTile(
                  leading: const Icon(Icons.my_location, color: AppColors.uctBlue),
                  title: const Text('Permisos de GPS y Ubicación'),
                  subtitle: const Text('Permitir ubicación en el campus'),
                  trailing: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                  onTap: () {},
                ),
                const Divider(height: 1, color: AppColors.fieldBorder),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.uctBlue),
                  title: const Text('Políticas de Privacidad y Términos'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      'Términos y Privacidad',
                      'UCT Map respeta tu privacidad. La información de reportes y ubicación solo es compartida con el departamento de Servicios Generales y Seguridad de la Universidad Católica de Temuco.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Información'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.fieldBorder),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.uctBlue),
              title: const Text('Acerca de UCT Map'),
              subtitle: const Text('Versión 1.0.0 • Taller de Integración 4'),
              trailing: const Icon(Icons.chevron_right, color: AppColors.hint),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'UCT Map',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      '© 2026 Universidad Católica de Temuco. Desarrollado para Taller de Integración 4.',
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.subtitle,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: AppColors.uctBlue)),
          ),
        ],
      ),
    );
  }
}
