import 'dart:convert';

import 'package:flutter/services.dart';

import 'banco.dart';

/// Leitura dos dados de análise da banca (app/assets/analises/), que
/// alimentam a tela "Raio-X da banca": histórico de anulações e gabaritos
/// alterados em provas reais da FAFIPA, e os temas que ela mais cobra por
/// matéria — fora das trilhas, como a Flávia pediu em 08/10/2026.
///
/// Os dois arquivos vêm de docs/estilo-fafipa.md, e tools/test_analises_fafipa.py
/// garante que todo item do edital aparece em exatamente uma das listas
/// (com registro, sem registro na amostra, ou município excluído).

class Motivo {
  const Motivo({required this.codigo, required this.descricao});

  final String codigo;
  final String descricao;

  factory Motivo.deJson(Map<String, dynamic> json) =>
      Motivo(codigo: json['codigo'] as String, descricao: json['descricao'] as String);
}

class QuestaoAnulada {
  const QuestaoAnulada({required this.numero, this.motivo, this.observacao});

  final int numero;
  final String? motivo;
  final String? observacao;

  factory QuestaoAnulada.deJson(Map<String, dynamic> json) => QuestaoAnulada(
        numero: json['numero'] as int,
        motivo: json['motivo'] as String?,
        observacao: json['observacao'] as String?,
      );
}

class GabaritoAlterado {
  const GabaritoAlterado({required this.numero, required this.paraLetra, this.motivo});

  final int numero;
  final String paraLetra;
  final String? motivo;

  factory GabaritoAlterado.deJson(Map<String, dynamic> json) => GabaritoAlterado(
        numero: json['numero'] as int,
        paraLetra: json['paraLetra'] as String,
        motivo: json['motivo'] as String?,
      );
}

class ProvaFafipa {
  const ProvaFafipa({
    required this.concurso,
    required this.ano,
    required this.cargo,
    required this.questoes,
    required this.gabaritoDefinitivoPublicado,
    required this.anuladas,
    required this.gabaritoAlterado,
    required this.fonte,
    this.edital,
    this.observacao,
  });

  final String concurso;
  final String? edital;
  final int ano;
  final String cargo;
  final int questoes;
  final bool gabaritoDefinitivoPublicado;
  final List<QuestaoAnulada> anuladas;
  final List<GabaritoAlterado> gabaritoAlterado;
  final String? observacao;
  final String fonte;

  /// Pra a tela: toda prova com alguma anulação ou gabarito trocado, mais as
  /// que ainda só têm preliminar (ela precisa saber que isso pode mudar).
  bool get temAlerta => anuladas.isNotEmpty || gabaritoAlterado.isNotEmpty || !gabaritoDefinitivoPublicado;

  factory ProvaFafipa.deJson(Map<String, dynamic> json) => ProvaFafipa(
        concurso: json['concurso'] as String,
        edital: json['edital'] as String?,
        ano: json['ano'] as int,
        cargo: json['cargo'] as String,
        questoes: json['questoes'] as int,
        gabaritoDefinitivoPublicado: json['gabaritoDefinitivoPublicado'] as bool,
        anuladas: [for (final a in json['anuladas'] as List) QuestaoAnulada.deJson(a as Map<String, dynamic>)],
        gabaritoAlterado: [
          for (final a in json['gabaritoAlterado'] as List) GabaritoAlterado.deJson(a as Map<String, dynamic>)
        ],
        observacao: json['observacao'] as String?,
        fonte: json['fonte'] as String,
      );
}

class ResumoHistorico {
  const ResumoHistorico({
    required this.provasComGabaritoDefinitivo,
    required this.questoesNessasProvas,
    required this.anuladas,
    required this.taxaDeAnulacao,
    required this.gabaritosAlterados,
    required this.observacao,
  });

  final int provasComGabaritoDefinitivo;
  final int questoesNessasProvas;
  final int anuladas;
  final double taxaDeAnulacao;
  final int gabaritosAlterados;
  final String observacao;

  factory ResumoHistorico.deJson(Map<String, dynamic> json) => ResumoHistorico(
        provasComGabaritoDefinitivo: json['provasComGabaritoDefinitivo'] as int,
        questoesNessasProvas: json['questoesNessasProvas'] as int,
        anuladas: json['anuladas'] as int,
        taxaDeAnulacao: (json['taxaDeAnulacao'] as num).toDouble(),
        gabaritosAlterados: json['gabaritosAlterados'] as int,
        observacao: json['observacao'] as String,
      );
}

class HistoricoFafipa {
  const HistoricoFafipa({required this.resumo, required this.motivos, required this.provas, required this.metodologia});

  final ResumoHistorico resumo;
  final List<Motivo> motivos;
  final List<ProvaFafipa> provas;
  final String metodologia;

  String? descricaoDoMotivo(String? codigo) {
    if (codigo == null) return null;
    for (final m in motivos) {
      if (m.codigo == codigo) return m.descricao;
    }
    return codigo;
  }

  factory HistoricoFafipa.deJson(Map<String, dynamic> json) => HistoricoFafipa(
        resumo: ResumoHistorico.deJson(json['resumo'] as Map<String, dynamic>),
        motivos: [for (final m in json['motivos'] as List) Motivo.deJson(m as Map<String, dynamic>)],
        provas: [for (final p in json['provas'] as List) ProvaFafipa.deJson(p as Map<String, dynamic>)],
        metodologia: json['metodologia'] as String,
      );
}

/// Os temas que a banca mais cobra numa matéria, e a cobertura do nosso
/// edital frente à amostra analisada.
class TemasDaMateria {
  const TemasDaMateria({
    required this.temasFrequentes,
    required this.itensComRegistro,
    required this.itensSemRegistroNaAmostra,
    required this.itensMunicipaisExcluidos,
    this.notaEspecial,
  });

  final List<String> temasFrequentes;
  final List<int> itensComRegistro;
  final List<int> itensSemRegistroNaAmostra;
  final List<int> itensMunicipaisExcluidos;
  final String? notaEspecial;

  factory TemasDaMateria.deJson(Map<String, dynamic> json) => TemasDaMateria(
        temasFrequentes: [for (final t in json['temasFrequentes'] as List) t as String],
        itensComRegistro: [for (final i in json['itensComRegistro'] as List) i as int],
        itensSemRegistroNaAmostra: [for (final i in json['itensSemRegistroNaAmostra'] as List) i as int],
        itensMunicipaisExcluidos: [for (final i in json['itensMunicipaisExcluidos'] as List) i as int],
        notaEspecial: json['notaEspecial'] as String?,
      );
}

class TemasFafipa {
  const TemasFafipa({required this.metodologia, required this.padroesGerais, required this.motivoMaisComum, required this.materias});

  final String metodologia;
  final List<String> padroesGerais;
  final String motivoMaisComum;
  final Map<String, TemasDaMateria> materias;

  factory TemasFafipa.deJson(Map<String, dynamic> json) => TemasFafipa(
        metodologia: json['metodologia'] as String,
        padroesGerais: [for (final p in json['padroesGerais'] as List) p as String],
        motivoMaisComum: (json['comoABancaErra'] as Map<String, dynamic>)['licaoParaEstudar'] as String,
        materias: {
          for (final entrada in (json['materias'] as Map<String, dynamic>).entries)
            entrada.key: TemasDaMateria.deJson(entrada.value as Map<String, dynamic>),
        },
      );
}

Future<HistoricoFafipa> carregarHistoricoFafipa([AssetBundle? pacote]) async {
  final bundle = pacote ?? rootBundle;
  final texto = await bundle.loadString('assets/analises/fafipa_historico.json');
  return HistoricoFafipa.deJson(jsonDecode(texto) as Map<String, dynamic>);
}

Future<TemasFafipa> carregarTemasFafipa([AssetBundle? pacote]) async {
  final bundle = pacote ?? rootBundle;
  final texto = await bundle.loadString('assets/analises/fafipa_temas.json');
  return TemasFafipa.deJson(jsonDecode(texto) as Map<String, dynamic>);
}

/// Cobertura de uma matéria: quantos itens do nosso edital têm registro
/// histórico, quantos não, quantos são municipais (fora da comparação).
/// Usado pelo gráfico de barras da tela.
class CoberturaMateria {
  const CoberturaMateria({required this.materia, required this.comRegistro, required this.semRegistro, required this.municipais});

  final String materia;
  final int comRegistro;
  final int semRegistro;
  final int municipais;

  int get total => comRegistro + semRegistro + municipais;

  /// Dos itens COMPARÁVEIS (estaduais/federais, sem os municipais), a fração
  /// com registro histórico — é o que vai na barra.
  double get fracaoComRegistro {
    final comparaveis = comRegistro + semRegistro;
    return comparaveis == 0 ? 0 : comRegistro / comparaveis;
  }

  String get nome => nomesDasMaterias[materia] ?? materia;
}

List<CoberturaMateria> coberturaPorMateria(TemasFafipa temas) => [
      for (final entrada in temas.materias.entries)
        CoberturaMateria(
          materia: entrada.key,
          comRegistro: entrada.value.itensComRegistro.length,
          semRegistro: entrada.value.itensSemRegistroNaAmostra.length,
          municipais: entrada.value.itensMunicipaisExcluidos.length,
        ),
    ];
