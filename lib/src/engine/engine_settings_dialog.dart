import 'package:flutter/material.dart';

import 'engine_settings.dart';

class EngineSettingsDialog extends StatefulWidget {
  final EngineSettings initialSettings;

  const EngineSettingsDialog({
    super.key,
    required this.initialSettings,
  });

  @override
  State<EngineSettingsDialog> createState() => _EngineSettingsDialogState();
}

class _EngineSettingsDialogState extends State<EngineSettingsDialog> {
  late EngineSettings _settings;
  late TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _pathController = TextEditingController(text: _settings.executablePath);
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_settings.canSaveMockConfiguration) return;

    final saved = _settings.copyWith(
      executablePath: _pathController.text,
      status: EngineSetupStatus.configuredMock,
    );
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final statusText = 'Status: ${_settings.statusLabel}';

    return AlertDialog(
      title: const Text('Configurar motor externo'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusText),
              const SizedBox(height: 16),
              DropdownButtonFormField<EngineType>(
                initialValue: _settings.engineType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de motor',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: EngineType.ytDlp,
                    child: Text('yt-dlp'),
                  ),
                  DropdownMenuItem(
                    value: EngineType.youtubeDl,
                    child: Text('youtube-dl'),
                  ),
                  DropdownMenuItem(
                    value: EngineType.custom,
                    child: Text('Personalizado'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _settings = _settings.copyWith(engineType: value);
                  });
                },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const Key('engineUseSystemExecutableCheckbox'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Usar executável disponível no sistema'),
                value: _settings.useSystemExecutable,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _settings = _settings.copyWith(useSystemExecutable: value);
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('engineExecutablePathField'),
                controller: _pathController,
                enabled: !_settings.useSystemExecutable,
                decoration: const InputDecoration(
                  labelText: 'Caminho do executável',
                  hintText: 'Ex.: C:\\tools\\yt-dlp.exe',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(executablePath: value);
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Use apenas com conteúdo próprio, autorizado, em domínio público, Creative Commons quando permitido ou downloads explicitamente permitidos pela plataforma.',
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const Key('engineSettingsLegalUsageCheckbox'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Entendo que devo usar apenas conteúdo autorizado ou permitido',
                ),
                value: _settings.acceptedLegalUsage,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _settings = _settings.copyWith(acceptedLegalUsage: value);
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('engineSettingsCancelButton'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('engineSettingsSaveButton'),
          onPressed: _settings.canSaveMockConfiguration ? _save : null,
          child: const Text('Salvar configuração'),
        ),
      ],
    );
  }
}
