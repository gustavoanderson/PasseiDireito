// Construtores de dados de teste compartilhados.
import 'package:passeidireito/banco.dart';

Questao questaoDeTeste(String id, {String? unidade, String correta = 'A', String? tema}) {
  final u = unidade ?? '${id.split('-').first}-01';
  return Questao(
    id: id,
    materia: u.split('-').first,
    unidadeId: u,
    tema: tema ?? 'Tema da $id',
    enunciado: 'Enunciado da $id.',
    alternativas: {for (final l in letras) l: 'Alternativa $l da $id'},
    correta: correta,
    dica: 'Dica da $id.',
    explicacao: {for (final l in letras) l: 'Explicação $l da $id'},
    fontes: const [Fonte(referencia: 'Lei X')],
  );
}

/// Unidade com [n] questões, ids `<materia>-<item><i>`; gabarito sempre A.
Unidade unidadeDeTeste(String id, String titulo, int n) {
  final materia = id.split('-').first;
  final item = id.split('-').last;
  return Unidade(
    materia: materia,
    id: id,
    titulo: titulo,
    itemEdital: int.parse(item),
    questoes: [for (var i = 1; i <= n; i++) questaoDeTeste('$materia-$item${i.toString().padLeft(2, '0')}', unidade: id)],
  );
}
