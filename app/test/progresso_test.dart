import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/progresso_firestore.dart';

Resposta _r(String questao, bool acertou, {String unidade = 'adm-04', int minuto = 0}) => Resposta(
      questaoId: questao,
      unidadeId: unidade,
      materia: unidade.split('-').first,
      escolhida: 'B',
      acertou: acertou,
      usouDica: false,
      em: DateTime(2026, 10, 1, 9, minuto),
    );

/// Registra e deixa a fila de eventos andar. O ProgressoFirestore não espera o
/// servidor (offline não pode travar a trilha): o SDK real aplica a escrita no
/// cache na hora, e o Firestore falso aplica no próximo ciclo.
Future<void> _registrar(RegistroDeProgresso p, Resposta r) async {
  await p.registrar(r);
  await pumpEventQueue();
}

/// O mesmo contrato vale para as duas implementações: o que a tela inicial
/// vê não pode depender de onde o progresso está guardado.
void _contrato(String nome, RegistroDeProgresso Function() criar) {
  group(nome, () {
    test('sem respostas, não há resumo', () async {
      expect(await criar().resumos(), isEmpty);
    });

    test('resumo conta feitas e acertos por unidade', () async {
      final p = criar();
      await _registrar(p, _r('adm-0001', true));
      await _registrar(p, _r('adm-0002', false));
      await _registrar(p, _r('const-0001', true, unidade: 'const-03'));

      final resumos = await p.resumos();
      expect(resumos.keys, unorderedEquals(['adm-04', 'const-03']));
      expect(resumos['adm-04']!.feitas, 2);
      expect(resumos['adm-04']!.acertos, 1);
      expect(resumos['const-03']!.acertos, 1);
    });

    test('refazer a questão substitui o resultado anterior, e não soma', () async {
      final p = criar();
      await _registrar(p, _r('adm-0001', false, minuto: 0));
      await _registrar(p, _r('adm-0001', true, minuto: 5));

      final resumo = (await p.resumos())['adm-04']!;
      expect(resumo.feitas, 1);
      expect(resumo.acertos, 1);
    });

    test('responder uma questão não apaga as outras da mesma unidade', () async {
      final p = criar();
      await _registrar(p, _r('adm-0001', true));
      await _registrar(p, _r('adm-0002', true));
      await _registrar(p, _r('adm-0003', false));

      expect((await p.resumos())['adm-04']!.ultimaPorQuestao, {
        'adm-0001': true,
        'adm-0002': true,
        'adm-0003': false,
      });
    });
  });
}

void main() {
  _contrato('em memória', ProgressoEmMemoria.new);
  _contrato('Firestore', () => ProgressoFirestore(FakeFirebaseFirestore(), 'flavia'));

  test('no Firestore, grava o histórico e o resumo no caminho que as regras permitem', () async {
    final db = FakeFirebaseFirestore();
    await ProgressoFirestore(db, 'flavia').registrar(_r('adm-0001', true));
    // O commit não é aguardado de propósito (offline não pode travar a trilha).
    await Future<void>.delayed(Duration.zero);

    final historico = await db.collection('usuarios/flavia/respostas').get();
    expect(historico.docs, hasLength(1));
    expect(historico.docs.single.data(), containsPair('questaoId', 'adm-0001'));
    expect(historico.docs.single.data(), containsPair('usouDica', false));

    final unidade = await db.doc('usuarios/flavia/unidades/adm-04').get();
    expect(unidade.exists, isTrue);
  });

  test('no Firestore, uma conta não enxerga o progresso de outra', () async {
    final db = FakeFirebaseFirestore();
    await ProgressoFirestore(db, 'flavia').registrar(_r('adm-0001', true));
    await Future<void>.delayed(Duration.zero);

    expect(await ProgressoFirestore(db, 'outra-conta').resumos(), isEmpty);
  });
}
