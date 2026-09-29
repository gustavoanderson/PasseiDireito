import 'dart:convert';

import 'package:flutter/services.dart';

/// Leitura do banco de questões que vem dentro do app (app/assets/questoes/).
///
/// O formato é o de tools/questao.schema.json, e o validador já garantiu que
/// cada arquivo o cumpre antes de ele entrar no app. Por isso aqui não há
/// checagem defensiva campo a campo: um arquivo fora do formato é defeito de
/// build, não situação que o app deva contornar.

const letras = ['A', 'B', 'C', 'D', 'E'];

const nomesDasMaterias = {
  'adm': 'Direito Administrativo',
  'const': 'Direito Constitucional',
  'trib': 'Direito Tributário e Financeiro',
  'pc': 'Direito Processual Civil',
  'urb': 'Direito Urbanístico e Ambiental',
  'trab': 'Direito do Trabalho',
  'prev': 'Direito Previdenciário',
  'pen': 'Direito Penal e Processual Penal',
  'emp': 'Direito Empresarial',
  'civ': 'Direito Civil',
};

class Fonte {
  const Fonte({required this.referencia});

  final String referencia;

  factory Fonte.deJson(Map<String, dynamic> json) =>
      Fonte(referencia: json['referencia'] as String);
}

class Questao {
  const Questao({
    required this.id,
    required this.materia,
    required this.unidadeId,
    required this.tema,
    required this.enunciado,
    required this.alternativas,
    required this.correta,
    required this.dica,
    required this.explicacao,
    required this.fontes,
    this.alerta,
  });

  final String id;

  /// Código da matéria e unidade de origem. A Flávia não vê a unidade: ela
  /// organiza o banco por item do edital e é onde o progresso é resumido.
  final String materia;
  final String unidadeId;
  final String tema;
  final String enunciado;
  final Map<String, String> alternativas;
  final String correta;
  final String dica;
  final Map<String, String> explicacao;
  final List<Fonte> fontes;

  /// Flag de mudança na lei. Aparece na trilha e na revisão, nunca no simulado.
  final String? alerta;

  factory Questao.deJson(Map<String, dynamic> json, {required String materia, required String unidadeId}) => Questao(
        id: json['id'] as String,
        materia: materia,
        unidadeId: unidadeId,
        tema: json['tema'] as String,
        enunciado: json['enunciado'] as String,
        alternativas: Map<String, String>.from(json['alternativas'] as Map),
        correta: json['correta'] as String,
        dica: json['dica'] as String,
        explicacao: Map<String, String>.from(json['explicacao'] as Map),
        fontes: [
          for (final f in json['fontes'] as List) Fonte.deJson(f as Map<String, dynamic>),
        ],
        alerta: json['alerta'] as String?,
      );
}

class Unidade {
  const Unidade({
    required this.materia,
    required this.id,
    required this.titulo,
    required this.itemEdital,
    required this.questoes,
  });

  final String materia;
  final String id;
  final String titulo;
  final int itemEdital;
  final List<Questao> questoes;

  String get nomeDaMateria => nomesDasMaterias[materia] ?? materia;

  factory Unidade.deJson(Map<String, dynamic> json) {
    final unidade = json['unidade'] as Map<String, dynamic>;
    final materia = json['materia'] as String;
    final id = unidade['id'] as String;
    return Unidade(
      materia: materia,
      id: id,
      titulo: unidade['titulo'] as String,
      itemEdital: unidade['itemEdital'] as int,
      questoes: [
        for (final q in json['questoes'] as List)
          Questao.deJson(q as Map<String, dynamic>, materia: materia, unidadeId: id),
      ],
    );
  }
}

/// Todas as unidades do banco, na ordem do edital: matéria e depois item.
Future<List<Unidade>> carregarUnidades([AssetBundle? pacote]) async {
  final bundle = pacote ?? rootBundle;
  final manifesto = await AssetManifest.loadFromAssetBundle(bundle);
  final arquivos = manifesto
      .listAssets()
      .where((a) => a.startsWith('assets/questoes/') && a.endsWith('.json'));

  final unidades = <Unidade>[
    for (final arquivo in arquivos)
      Unidade.deJson(jsonDecode(await bundle.loadString(arquivo)) as Map<String, dynamic>),
  ];

  final ordemDasMaterias = nomesDasMaterias.keys.toList();
  unidades.sort((a, b) {
    final porMateria = ordemDasMaterias.indexOf(a.materia).compareTo(ordemDasMaterias.indexOf(b.materia));
    return porMateria != 0 ? porMateria : a.itemEdital.compareTo(b.itemEdital);
  });
  return unidades;
}
