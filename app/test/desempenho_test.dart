import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/desempenho.dart';

import 'apoio.dart';

void main() {
  final licitacoes = unidadeDeTeste('adm-07', 'Licitações', 4); // adm-0701..0704
  final atos = unidadeDeTeste('adm-04', 'Atos administrativos', 3); // adm-0401..0403
  final controle = unidadeDeTeste('const-03', 'Controle de constitucionalidade', 2);
  final unidades = [atos, licitacoes, controle];

  test('sem respostas, nada feito e nada a reforçar', () {
    final d = analisarDesempenho(unidades, {});
    expect(d.feitas, 0);
    expect(d.taxa, 0);
    expect(d.temasAReforcar, isEmpty);
  });

  test('conta feitas e acertos por assunto, por matéria e no geral', () {
    final d = analisarDesempenho(unidades, {
      'adm-0701': true,
      'adm-0702': false,
      'adm-0703': false,
      'adm-0401': true,
      'const-0301': true,
    });
    expect(d.feitas, 5);
    expect(d.acertos, 3);

    final adm = d.materias.firstWhere((m) => m.codigo == 'adm');
    expect(adm.feitas, 4);
    expect(adm.total, 7);
    expect(adm.erradas.map((q) => q.id), ['adm-0702', 'adm-0703']);
  });

  test('onde reforçar: mais erros primeiro; no empate, a menor taxa de acerto', () {
    final d = analisarDesempenho(unidades, {
      // Licitações: 2 erros em 4 (50%)
      'adm-0701': true, 'adm-0702': false, 'adm-0703': false, 'adm-0704': true,
      // Atos: 1 erro em 1 (0%)
      'adm-0401': false,
      // Controle: 1 erro em 2 (50%)
      'const-0301': false, 'const-0302': true,
    });
    expect(d.temasAReforcar.map((t) => t.nome), ['Licitações', 'Atos administrativos', 'Controle de constitucionalidade']);
  });

  test('assunto sem erro não entra na lista de reforço', () {
    final d = analisarDesempenho(unidades, {'adm-0401': true, 'adm-0402': true});
    expect(d.temasAReforcar, isEmpty);
  });

  test('erros de um simulado agrupados por assunto, do maior para o menor', () {
    final r = errosPorAssunto(unidades, ['adm-0401', 'adm-0701', 'adm-0702', 'inexistente']);
    expect([for (final (u, n) in r) '${u.titulo}:$n'], ['Licitações:2', 'Atos administrativos:1']);
  });
}
