import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banca.dart';
import 'package:passeidireito/tela_banca.dart';
import 'package:passeidireito/tema.dart';

HistoricoFafipa _historico({bool todasDefinitivas = true}) => HistoricoFafipa(
      metodologia: 'metodologia de teste',
      resumo: const ResumoHistorico(
        provasComGabaritoDefinitivo: 2,
        questoesNessasProvas: 120,
        anuladas: 4,
        taxaDeAnulacao: 0.033,
        gabaritosAlterados: 1,
        observacao: 'observação de teste',
      ),
      motivos: const [Motivo(codigo: 'sem-correta', descricao: 'sem alternativa correta')],
      provas: [
        const ProvaFafipa(
          concurso: 'Concurso Alfa',
          ano: 2025,
          cargo: 'Procurador',
          questoes: 80,
          gabaritoDefinitivoPublicado: true,
          anuladas: [QuestaoAnulada(numero: 6, motivo: 'sem-correta')],
          gabaritoAlterado: [],
          fonte: 'https://exemplo.org/alfa',
        ),
        ProvaFafipa(
          concurso: 'Concurso Beta',
          ano: 2026,
          cargo: 'Procurador',
          questoes: 40,
          gabaritoDefinitivoPublicado: todasDefinitivas,
          anuladas: const [],
          gabaritoAlterado: const [],
          observacao: todasDefinitivas ? null : 'Só o gabarito preliminar saiu até agora',
          fonte: 'https://exemplo.org/beta',
        ),
      ],
    );

TemasFafipa _temas() => const TemasFafipa(
      metodologia: 'metodologia de teste',
      padroesGerais: ['Letra de lei domina.', 'Absolutos costumam ser a alternativa errada.'],
      motivoMaisComum: 'desconfie de lei recém-alterada',
      materias: {
        'adm': TemasDaMateria(
          temasFrequentes: ['Princípios do art. 37'],
          itensComRegistro: [1, 2],
          itensSemRegistroNaAmostra: [3],
          itensMunicipaisExcluidos: [4],
        ),
        'const': TemasDaMateria(
          temasFrequentes: ['Controle de constitucionalidade'],
          itensComRegistro: [1],
          itensSemRegistroNaAmostra: [2],
          itensMunicipaisExcluidos: [],
          notaEspecial: 'tema recente, sem registro na amostra',
        ),
      },
    );

Future<void> _abrir(WidgetTester tester, {bool todasDefinitivas = true}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaBanca(
        carregarHistorico: () async => _historico(todasDefinitivas: todasDefinitivas),
        carregarTemas: () async => _temas(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra o resumo de anulações e a taxa', (tester) async {
    await _abrir(tester);
    expect(find.byKey(const Key('taxa-anulacao')), findsOneWidget);
    expect(find.textContaining('3,3%'), findsOneWidget);
  });

  testWidgets('lista as provas com alerta, com o motivo da anulação', (tester) async {
    await _abrir(tester);
    expect(find.textContaining('Concurso Alfa'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prova-Concurso Alfa-2025')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Questão 6 anulada'), findsOneWidget);
    expect(find.textContaining('sem alternativa correta'), findsOneWidget);
  });

  testWidgets('prova só com gabarito preliminar aparece mesmo sem anulação', (tester) async {
    await _abrir(tester, todasDefinitivas: false);
    expect(find.textContaining('Concurso Beta'), findsOneWidget);
    expect(find.textContaining('Só o gabarito preliminar'), findsOneWidget);
  });

  testWidgets('mostra os padrões gerais e os temas por matéria', (tester) async {
    await _abrir(tester);
    expect(find.textContaining('Letra de lei domina'), findsOneWidget);
    expect(find.byKey(const Key('cobertura-adm')), findsOneWidget);
    expect(find.byKey(const Key('cobertura-const')), findsOneWidget);
    expect(find.textContaining('2 de 3 itens com registro'), findsOneWidget);
  });

  testWidgets('mostra a legislação municipal separada da contagem comparável', (tester) async {
    await _abrir(tester);
    expect(find.textContaining('1 item de legislação municipal'), findsOneWidget);
  });

  testWidgets('mostra a nota especial de um tema recente', (tester) async {
    await _abrir(tester);
    expect(find.byKey(const Key('nota-const')), findsOneWidget);
    expect(find.textContaining('tema recente, sem registro na amostra'), findsOneWidget);
  });
}
