import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'progresso.dart';

/// Progresso no Firestore, com o cache offline do próprio Firestore.
///
/// Dois lugares por usuária, gravados juntos num lote:
///
/// - `usuarios/{uid}/respostas/{auto}`: uma linha por resposta, para sempre.
///   Hoje ninguém lê; existe para a revisão de erros e as estatísticas.
/// - `usuarios/{uid}/unidades/{unidadeId}`: o resumo que a tela inicial lê.
///   Ler o resumo custa um documento por unidade; ler o histórico custaria um
///   por resposta, e em poucos meses isso passaria da cota gratuita diária.
class ProgressoFirestore implements RegistroDeProgresso {
  ProgressoFirestore(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _usuaria => _db.collection('usuarios').doc(_uid);

  @override
  Future<void> registrar(Resposta r) async {
    final lote = _db.batch()
      ..set(_usuaria.collection('respostas').doc(), {
        'questaoId': r.questaoId,
        'unidadeId': r.unidadeId,
        'materia': r.materia,
        'escolhida': r.escolhida,
        'acertou': r.acertou,
        'usouDica': r.usouDica,
        'em': Timestamp.fromDate(r.em),
      })
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

    // O commit só termina quando o SERVIDOR confirma. Sem internet, esperar
    // por ele travaria a trilha. O Firestore já aplicou a escrita no cache
    // local ao chamar commit(); a subida acontece quando a rede voltar.
    unawaited(lote.commit().catchError((Object _) {}));
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
}
