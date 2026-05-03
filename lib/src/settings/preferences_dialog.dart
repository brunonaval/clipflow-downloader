import 'package:flutter/material.dart';

import 'app_preferences.dart';
import 'output_folder_choice.dart';

enum PreferencesSection { general, downloads, engine, notifications, advanced }

class PreferencesDialog extends StatefulWidget {
  final AppPreferences initialPreferences;

  const PreferencesDialog({super.key, required this.initialPreferences});

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  late AppPreferences _preferences;
  PreferencesSection _section = PreferencesSection.general;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 760,
        height: 500,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildSidebar(),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildSectionContent()),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, _preferences),
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Preferências',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          _sectionTile(PreferencesSection.general, 'Geral'),
          _sectionTile(PreferencesSection.downloads, 'Downloads'),
          _sectionTile(PreferencesSection.engine, 'Motor'),
          _sectionTile(PreferencesSection.notifications, 'Notificações'),
          _sectionTile(PreferencesSection.advanced, 'Avançado'),
        ],
      ),
    );
  }

  Widget _sectionTile(PreferencesSection value, String label) {
    final selected = _section == value;
    return ListTile(
      title: Text(label),
      selected: selected,
      onTap: () => setState(() => _section = value),
      dense: true,
    );
  }

  Widget _buildSectionContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: switch (_section) {
          PreferencesSection.general => _generalSection(),
          PreferencesSection.downloads => _downloadsSection(),
          PreferencesSection.engine => _engineSection(),
          PreferencesSection.notifications => _notificationsSection(),
          PreferencesSection.advanced => _advancedSection(),
        },
      ),
    );
  }

  Widget _generalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Geral',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _dropdownRow(
          label: 'Idioma',
          value: _preferences.languageLabel,
          options: const ['Sistema', 'Português', 'Inglês'],
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(languageLabel: value),
          ),
        ),
        const SizedBox(height: 12),
        _dropdownRow(
          label: 'Tema',
          value: _preferences.themeLabel,
          options: const ['Sistema', 'Claro', 'Escuro'],
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(themeLabel: value),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Modo inteligente'),
          subtitle: const Text(
            'Colar link inicia automaticamente usando as opções atuais.',
          ),
          value: _preferences.smartModeEnabled,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(smartModeEnabled: value),
          ),
        ),
      ],
    );
  }

  Widget _downloadsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Downloads',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _dropdownRow(
          label: 'Pasta padrão',
          value: _preferences.outputFolderChoice.label,
          options: const ['Downloads', 'Vídeos', 'Documentos'],
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              outputFolderChoice: switch (value) {
                'Vídeos' => const OutputFolderChoice(
                  type: OutputFolderType.videos,
                  label: 'Vídeos',
                ),
                'Documentos' => const OutputFolderChoice(
                  type: OutputFolderType.documents,
                  label: 'Documentos',
                ),
                _ => OutputFolderChoice.downloads,
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Abrir pasta quando concluir'),
          value: _preferences.openFolderWhenDone,
          onChanged: (value) => setState(
            () =>
                _preferences = _preferences.copyWith(openFolderWhenDone: value),
          ),
        ),
        SwitchListTile(
          title: const Text('Remover concluídos automaticamente'),
          value: _preferences.removeCompletedAutomatically,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              removeCompletedAutomatically: value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _engineSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motor',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        Text('Motor YouTube: yt-dlp'),
        SizedBox(height: 8),
        Text('Merge de alta qualidade: FFmpeg quando disponível'),
        SizedBox(height: 8),
        Text('Saída padrão: Downloads/ClipFlow'),
        SizedBox(height: 16),
        Text(
          'Verificação detalhada virá em rodada futura',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _notificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notificações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Notificar ao concluir download'),
          value: _preferences.notifyWhenDownloadCompletes,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              notifyWhenDownloadCompletes: value,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Notificar ao falhar download'),
          value: _preferences.notifyWhenDownloadFails,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              notifyWhenDownloadFails: value,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Confirmar saída com downloads ativos'),
          value: _preferences.confirmExitWithActiveDownloads,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              confirmExitWithActiveDownloads: value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _advancedSection() {
    final allowed = AppPreferences.allowedSimultaneousDownloads;
    final rawIndex = allowed.indexOf(_preferences.simultaneousDownloads);
    final selectedIndex = rawIndex < 0 ? 0 : rawIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avançado',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const Text(
          'Transferências simultâneas',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Slider(
          value: selectedIndex.toDouble(),
          min: 0,
          max: (allowed.length - 1).toDouble(),
          divisions: allowed.length - 1,
          label:
              '${allowed[selectedIndex]} ${AppPreferences.simultaneousDownloadsRiskLabel(allowed[selectedIndex])}',
          onChanged: (value) {
            final index = value.round().clamp(0, allowed.length - 1);
            setState(() {
              _preferences = _preferences.copyWith(
                simultaneousDownloads: allowed[index],
              );
            });
          },
        ),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: allowed
              .map(
                (value) => Text(
                  '$value ${AppPreferences.simultaneousDownloadsRiskLabel(value)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        const Text(
          'A alta intensidade pode aumentar o desempenho global da transferência, mas também pode causar falhas temporárias ou bloqueios do YouTube.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Impedir suspensão enquanto baixa'),
          value: _preferences.keepSystemAwakeWhileDownloading,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              keepSystemAwakeWhileDownloading: value,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Mostrar formatos avançados'),
          value: _preferences.showAdvancedFormats,
          onChanged: (value) => setState(
            () => _preferences = _preferences.copyWith(
              showAdvancedFormats: value,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Formatos avançados podem exigir merge ou gerar arquivos maiores.',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _dropdownRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: value,
          items: options
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ],
    );
  }
}
