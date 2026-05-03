import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/settings/app_preferences.dart';
import 'package:clipflow_downloader/src/settings/output_folder_choice.dart';
import 'package:clipflow_downloader/src/settings/preferences_dialog.dart';

void main() {
  testWidgets('renderiza seções de preferências', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PreferencesDialog(initialPreferences: AppPreferences.defaults),
        ),
      ),
    );

    expect(find.text('Preferências'), findsOneWidget);
    expect(find.text('Geral'), findsAtLeastNWidgets(1));
    expect(find.text('Downloads'), findsOneWidget);
    expect(find.text('Motor'), findsOneWidget);
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Avançado'), findsOneWidget);
  });

  testWidgets('troca seção e mostra conteúdo correspondente', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PreferencesDialog(initialPreferences: AppPreferences.defaults),
        ),
      ),
    );

    await tester.tap(find.text('Motor'));
    await tester.pump();

    expect(find.text('Motor YouTube: yt-dlp'), findsOneWidget);

    await tester.tap(find.text('Avançado'));
    await tester.pump();

    expect(find.text('Mostrar formatos avançados'), findsOneWidget);
    expect(find.text('Transferências simultâneas'), findsOneWidget);
  });

  testWidgets('seção downloads mostra pasta padrão e salva vídeos', (
    tester,
  ) async {
    AppPreferences? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog<AppPreferences>(
                  context: context,
                  builder: (_) => const PreferencesDialog(
                    initialPreferences: AppPreferences.defaults,
                  ),
                );
                saved = result;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    await tester.tap(find.text('Downloads'));
    await tester.pump();

    expect(find.text('Pasta padrão'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vídeos').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.outputFolderChoice.type, OutputFolderType.videos);
    expect(saved!.outputFolderChoice.label, 'Vídeos');
  });

  testWidgets('cancelar fecha sem salvar', (tester) async {
    AppPreferences? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog<AppPreferences>(
                  context: context,
                  builder: (_) => const PreferencesDialog(
                    initialPreferences: AppPreferences.defaults,
                  ),
                );
                saved = result;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pump();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(saved, isNull);
  });

  testWidgets('modo inteligente pode ser ativado e salvo', (tester) async {
    AppPreferences? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog<AppPreferences>(
                  context: context,
                  builder: (_) => const PreferencesDialog(
                    initialPreferences: AppPreferences.defaults,
                  ),
                );
                saved = result;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Modo inteligente'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.smartModeEnabled, isTrue);
  });

  testWidgets('avançado altera transferências simultâneas e mostra risco', (
    tester,
  ) async {
    AppPreferences? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final result = await showDialog<AppPreferences>(
                  context: context,
                  builder: (_) => const PreferencesDialog(
                    initialPreferences: AppPreferences.defaults,
                  ),
                );
                saved = result;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avançado'));
    await tester.pumpAndSettle();

    expect(find.text('Transferências simultâneas'), findsOneWidget);
    expect(find.textContaining('Ideal'), findsWidgets);
    expect(find.textContaining('Arriscado'), findsWidgets);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(3);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.simultaneousDownloads, 6);
  });
}
