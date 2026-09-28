import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/trilha.dart';

Questao _q(String id, {String unidade = 'adm-04'}) => Questao(
      id: id,
      materia: unidade.split('-').first,
      unidadeId: unidade,
      tema: 't',
      enunciado: 'e',
      alternativas: {for (final l in letras) l: l},
      correta: 'A',
      dica: 'd',
      explicacao: {for (final l in letras) l: l},
      fontes: const [],
    );

List<String> _ids(List<Questao> qs) => [for (final q in qs) q.id];

void main() {
  final questoes = [for (var i = 1; i <= 5; i++) _q('adm-000$i')];

  group('montarSessao', () {
    test('sem nada respondido, começa pelo início do edital', () {
      expect(_ids(montarSessao(questoes, {}, tamanho: 3)), ['adm-0001', 'adm-0002', 'adm-0003']);
    });

    test('pula as já respondidas e segue nas inéditas', () {
      final ultimas = {'adm-0001': true, 'adm-0002': false};
      expect(_ids(montarSessao(questoes, ultimas, tamanho: 3)), ['adm-0003', 'adm-0004', 'adm-0005']);
    });

    test('acabando as inéditas, completa com as que ela errou', () {
      final ultimas = {'adm-0001': true, 'adm-0002': false, 'adm-0003': true, 'adm-0004': false};
      expect(_ids(montarSessao(questoes, ultimas, tamanho: 3)), ['adm-0005', 'adm-0002', 'adm-0004']);
    });

    test('acertou tudo: a trilha continua, revisando as acertadas', () {
      final ultimas = {for (final q in questoes) q.id: true};
      expect(_ids(montarSessao(questoes, ultimas, tamanho: 2)), ['adm-0001', 'adm-0002']);
    });

    test('a sessão padrão tem 10 questões', () {
      final muitas = [for (var i = 10; i < 40; i++) _q('adm-00$i')];
      expect(montarSessao(muitas, {}), hasLength(10));
    });
  });

  test('agrupa as unidades de uma matéria numa trilha só, na ordem recebida', () {
    Unidade u(String id, List<Questao> qs) =>
        Unidade(materia: id.split('-').first, id: id, titulo: id, itemEdital: 1, questoes: qs);
    final materias = agruparPorMateria([
      u('adm-03', [_q('adm-0007', unidade: 'adm-03')]),
      u('adm-04', [_q('adm-0001')]),
      u('const-01', [_q('const-0001', unidade: 'const-01')]),
      u('trib-01', []),
    ]);

    expect([for (final m in materias) m.codigo], ['adm', 'const'], reason: 'matéria sem questões não aparece');
    expect(_ids(materias.first.questoes), ['adm-0007', 'adm-0001']);
    expect(materias.first.nome, 'Direito Administrativo');
  });
}
