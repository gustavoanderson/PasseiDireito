import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'progresso.dart';

/// Progresso no Firestore, com o cache offline do próprio Firestore.
///
/// Por usuária (`usuarios/{uid}/...`):
///
/// - `respostas/{auto}`: uma linha por resposta, para sempre (histórico).
/// - `unidades/{unidadeId}`: o resumo com a última resposta de cada questão.
///   É o que as telas leem: um documento por unidade, e não um por resposta,
///   para não passar da cota gratuita de leituras.
/// - `simulados/{auto}`: cada simulado entregue, com todas as respostas.
class ProgressoFirestore implements RegistroDeProgresso {
  ProgressoFirestore(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _usuaria => _db.collection('usuarios').doc(_uid);

  void _acrescentar(WriteBatch lote, Resposta r) {
    lote
      ..set(_usuaria.collection('respostas').doc(), _respostaParaMapa(r))
      // merge funde o mapa aninhado: só a questão respondida muda.
      ..set(
        _usuaria.collection('unidades').doc(r.unidadeId),
        {
          'materia': r.materia,
          'questoes': {
            r.questaoId: {'acertou': r.acertou, 'em': Timestamp.fromDate(r.em)},
          },
        },
        SetOptions(merge: true),
      );
  }

  /// O commit só termina quando o SERVIDOR confirma. Sem internet, esperar
  /// por ele travaria a tela. O Firestore já aplicou a escrita no cache local
  /// ao chamar commit(); a subida acontece quando a rede voltar.
  void _enviarSemEsperar(WriteBatch lote) => unawaited(lote.commit().catchError((Object _) {}));

  @override
  Future<void> registrar(Resposta r) async {
    final lote = _db.batch();
    _acrescentar(lote, r);
    _enviarSemEsperar(lote);
  }

  @override
  Future<Map<String, ResumoUnidade>> resumos() async {
    final docs = await _usuaria.collection('unidades').get();
    return {
      for (final d in docs.docs)
        d.id: ResumoUnidade({
          for (final e in ((d.data()['questoes'] as Map?) ?? {}).entries)
            e.key as String: ((e.value as Map)['acertou'] as bool?) ?? false,
        }),
    };
  }

  @override
  Future<void> registrarSimulado(ResultadoSimulado s) async {
    // Um lote: 1 simulado + 2 escritas por resposta. 100 questões = 201,
    // abaixo do limite de 500 operações do Firestore.
    final lote = _db.batch()
      ..set(_usuaria.collection('simulados').doc(), {
        'inicio': Timestamp.fromDate(s.inicio),
        'duracaoSegundos': s.duracao.inSeconds,
        'tempoPrevistoSegundos': s.tempoPrevisto.inSeconds,
        'respostas': [for (final r in s.respostas) _respostaParaMapa(r)],
      });
    for (final r in s.respostas) {
      _acrescentar(lote, r);
    }
    _enviarSemEsperar(lote);
  }

  @override
  Future<List<ResultadoSimulado>> simulados() async {
    final docs = await _usuaria.collection('simulados').orderBy('inicio', descending: true).get();
    return [
      for (final d in docs.docs)
        ResultadoSimulado(
          inicio: (d.data()['inicio'] as Timestamp).toDate(),
          duracao: Duration(seconds: d.data()['duracaoSegundos'] as int),
          tempoPrevisto: Duration(seconds: d.data()['tempoPrevistoSegundos'] as int),
          respostas: [for (final r in d.data()['respostas'] as List) _mapaParaResposta(r as Map<String, dynamic>)],
        ),
    ];
  }

  static Map<String, dynamic> _respostaParaMapa(Resposta r) => {
        'questaoId': r.questaoId,
        'unidadeId': r.unidadeId,
        'materia': r.materia,
        'escolhida': r.escolhida,
        'acertou': r.acertou,
        'usouDica': r.usouDica,
        'origem': r.origem.name,
        'em': Timestamp.fromDate(r.em),
      };

  static Resposta _mapaParaResposta(Map<String, dynamic> m) => Resposta(
        questaoId: m['questaoId'] as String,
        unidadeId: m['unidadeId'] as String,
        materia: m['materia'] as String,
        escolhida: m['escolhida'] as String,
        acertou: m['acertou'] as bool,
        usouDica: m['usouDica'] as bool,
        em: (m['em'] as Timestamp).toDate(),
        origem: OrigemResposta.values.byName(m['origem'] as String),
      );
}
