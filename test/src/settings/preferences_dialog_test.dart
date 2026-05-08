import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clipflow_downloader/src/settings/app_preferences.dart';
import 'package:clipflow_downloader/src/settings/output_folder_choice.dart';
import 'package:clipflow_downloader/src/settings/preferences_dialog.dart';

void main() {
  testWidgets('renderiza seções essenciais de preferências', (tester) async {
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

  testWidgets('seção geral mostra modo inteligente e opção de bandeja', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PreferencesDialog(initialPreferences: AppPreferences.defaults),
        ),
      ),
    );

    expect(find.text('Modo inteligente'), findsOneWidget);
    expect(find.text('Manter ClipFlow na bandeja ao fechar'), findsOneWidget);
    expect(find.text('Idioma'), findsNothing);
    expect(find.text('Tema'), findsNothing);
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    expect(find.text('Pasta padrão'), findsOneWidget);
    expect(find.text('Abrir pasta quando concluir'), findsNothing);
    expect(find.text('Remover concluídos automaticamente'), findsNothing);

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(saved, isNull);
  });

  testWidgets('seção notificações mantém opções reais', (tester) async {
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

    await tester.tap(find.textContaining('Notifica'));
    await tester.pumpAndSettle();

    expect(find.text('Notificar ao concluir download'), findsOneWidget);
    expect(find.text('Notificar ao falhar download'), findsOneWidget);
    expect(find.text('Confirmar saída com downloads ativos'), findsNothing);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.notifyWhenDownloadCompletes, isFalse);
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
    expect(find.text('Impedir suspensão enquanto baixa'), findsNothing);
    expect(find.text('Mostrar formatos avançados'), findsNothing);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(3);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.simultaneousDownloads, 6);
  });

  testWidgets('geral: alternar bandeja ao fechar altera prefer\u00eancia', (
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

    expect(find.text('Manter ClipFlow na bandeja ao fechar'), findsOneWidget);

    // Default is true; toggle it off
    final switches = find.byType(Switch);
    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.minimizeToTrayOnClose, isFalse);
  });

  testWidgets('motor permite alternar uso da sess\u00e3o do Firefox', (
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
    await tester.tap(find.text('Motor'));
    await tester.pumpAndSettle();

    expect(
      find.text('Usar sess\u00e3o do Firefox para YouTube'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.useFirefoxCookiesForYouTube, isTrue);
  });
}
