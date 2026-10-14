import 'dart:convert';

import 'package:flutter/services.dart';

/// Leitura do log de alterações (app/assets/analises/log_alteracoes.json):
/// a cronologia do que mudou no banco por causa do edital — pedido da
/// Flávia em 14/10/2026, pra saber o que saiu, quando, e por quê.
///
/// tools/test_log_alteracoes.py faz o batimento: toda questão listada como
/// removida não pode mais existir no banco, e toda criada tem que existir.

enum TipoEvento {
  /// O próprio edital (publicação ou retificação) — não mexe no banco sozinho.
  edital,

  /// Questão(ões) saíram do banco.
  remocao,

  /// Mudança que não troca questão nenhuma (ex.: peso na prova).
  ajuste,

  /// Questão(ões) novas entraram no banco.
  criacao,
}

class EventoDoLog {
  const EventoDoLog({
    required this.data,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    this.questoesRemovidas = const [],
    this.questoesCriadas = const [],
    this.commit,
  });

  final DateTime data;
  final TipoEvento tipo;
  final String titulo;
  final String descricao;
  final List<String> questoesRemovidas;
  final List<String> questoesCriadas;

  /// Hash curto do commit que fez a mudança, quando houver — rastreável no
  /// histórico do repositório.
  final String? commit;

  factory EventoDoLog.deJson(Map<String, dynamic> json) => EventoDoLog(
        data: DateTime.parse(json['data'] as String),
        tipo: TipoEvento.values.byName(json['tipo'] as String),
        titulo: json['titulo'] as String,
        descricao: json['descricao'] as String,
        questoesRemovidas: [for (final q in (json['questoesRemovidas'] as List?) ?? []) q as String],
        questoesCriadas: [for (final q in (json['questoesCriadas'] as List?) ?? []) q as String],
        commit: json['commit'] as String?,
      );
}

class LogDeAlteracoes {
  const LogDeAlteracoes({required this.atualizadoEm, required this.introducao, required this.eventos});

  final DateTime atualizadoEm;
  final String introducao;
  final List<EventoDoLog> eventos;

  /// Do mais recente para o mais antigo: é a ordem que a tela usa.
  List<EventoDoLog> get doMaisRecente => [...eventos]..sort((a, b) => b.data.compareTo(a.data));

  factory LogDeAlteracoes.deJson(Map<String, dynamic> json) => LogDeAlteracoes(
        atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
        introducao: json['introducao'] as String,
        eventos: [for (final e in json['eventos'] as List) EventoDoLog.deJson(e as Map<String, dynamic>)],
      );
}

Future<LogDeAlteracoes> carregarLogDeAlteracoes([AssetBundle? pacote]) async {
  final bundle = pacote ?? rootBundle;
  final texto = await bundle.loadString('assets/analises/log_alteracoes.json');
  return LogDeAlteracoes.deJson(jsonDecode(texto) as Map<String, dynamic>);
}
