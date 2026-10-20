import 'dart:convert';

import 'package:flutter/services.dart';

import 'banco.dart';

/// Leitura das provas reais anteriores (app/assets/provas/) — pedido da
/// Flávia em 20/10/2026: refazer uma prova exatamente como ela caiu, ou
/// montar um simulado personalizado misturando provas.
///
/// Separado do banco de trilha (banco.dart): aqui entra também o que não
/// bate com o Anexo II de Curitiba, porque o objetivo é reproduzir a prova
/// histórica, não ensinar o edital atual. tools/validar_provas.py garante o
/// formato antes de qualquer arquivo entrar aqui.

class DadosDaProva {
  const DadosDaProva({
    required this.id,
    required this.concurso,
    required this.banca,
    required this.ano,
    required this.cargo,
    required this.dataAplicacao,
    required this.gabaritoDefinitivoPublicado,
    required this.fonte,
  });

  final String id;
  final String concurso;
  final String banca;
  final int ano;
  final String cargo;
  final DateTime dataAplicacao;

  /// Falso quando só o gabarito preliminar saiu: uma ou outra resposta
  /// ainda pode mudar depois do recurso.
  final bool gabaritoDefinitivoPublicado;
  final String fonte;

  String get nome => '$banca $ano · $concurso';

  factory DadosDaProva.deJson(Map<String, dynamic> json) => DadosDaProva(
        id: json['id'] as String,
        concurso: json['concurso'] as String,
        banca: json['banca'] as String,
        ano: json['ano'] as int,
        cargo: json['cargo'] as String,
        dataAplicacao: DateTime.parse(json['dataAplicacao'] as String),
        gabaritoDefinitivoPublicado: json['gabaritoDefinitivoPublicado'] as bool,
        fonte: json['fonte'] as String,
      );
}

/// Uma prova real completa, com as questões na ordem e numeração originais.
class ProvaReal {
  const ProvaReal({required this.dados, required this.questoes});

  final DadosDaProva dados;

  /// Na ordem do caderno original (não é sorteada, como no simulado comum).
  final List<Questao> questoes;

  factory ProvaReal.deJson(Map<String, dynamic> json) {
    final dados = DadosDaProva.deJson(json['prova'] as Map<String, dynamic>);
    return ProvaReal(
      dados: dados,
      questoes: [
        for (final q in json['questoes'] as List) _questaoDaProva(q as Map<String, dynamic>, dados),
      ],
    );
  }
}

Questao _questaoDaProva(Map<String, dynamic> json, DadosDaProva prova) => Questao(
      id: json['id'] as String,
      materia: json['materia'] as String,
      // A própria prova faz as vezes de "unidade": não existe item de edital
      // aqui, e o progresso dela não precisa se misturar com o da trilha.
      unidadeId: prova.id,
      tema: json['tema'] as String,
      enunciado: json['enunciado'] as String,
      alternativas: Map<String, String>.from(json['alternativas'] as Map),
      correta: json['correta'] as String,
      dica: json['dica'] as String,
      explicacao: Map<String, String>.from(json['explicacao'] as Map),
      fontes: [for (final f in json['fontes'] as List) Fonte.deJson(f as Map<String, dynamic>)],
      origem: Origem(tipo: 'adaptada', prova: '${prova.nome} (${prova.gabaritoDefinitivoPublicado ? 'gabarito definitivo' : 'gabarito preliminar'})'),
    );

/// Todas as provas reais do banco, da mais recente para a mais antiga.
Future<List<ProvaReal>> carregarProvas([AssetBundle? pacote]) async {
  final bundle = pacote ?? rootBundle;
  final manifesto = await AssetManifest.loadFromAssetBundle(bundle);
  final arquivos = manifesto.listAssets().where((a) => a.startsWith('assets/provas/') && a.endsWith('.json'));

  final provas = <ProvaReal>[
    for (final arquivo in arquivos) ProvaReal.deJson(jsonDecode(await bundle.loadString(arquivo)) as Map<String, dynamic>),
  ];
  provas.sort((a, b) => b.dados.dataAplicacao.compareTo(a.dados.dataAplicacao));
  return provas;
}
