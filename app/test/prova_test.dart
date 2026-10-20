import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/prova.dart';

Map<String, dynamic> _json({bool definitivo = false}) => {
      "versaoFormato": 1,
      "prova": {
        "id": "teste-2020",
        "concurso": "Teste",
        "banca": "FAFIPA",
        "ano": 2020,
        "cargo": "Procurador",
        "dataAplicacao": "2020-03-15",
        "gabaritoDefinitivoPublicado": definitivo,
        "fonte": "https://exemplo.org/teste",
      },
      "questoes": [
        {
          "numeroOriginal": 1,
          "id": "teste-2020-001",
          "materia": "adm",
          "tema": "Tema de teste",
          "enunciado": "Enunciado de teste.",
          "alternativas": {"A": "a", "B": "b", "C": "c", "D": "d", "E": "e"},
          "correta": "A",
          "dica": "Dica de teste.",
          "explicacao": {"A": "a", "B": "b", "C": "c", "D": "d", "E": "e"},
          "fontes": [
            {"tipo": "lei", "referencia": "Lei de teste", "data": "2019-01-01"},
          ],
        },
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DadosDaProva.deJson lê os campos e monta o nome', () {
    final dados = DadosDaProva.deJson(_json()["prova"] as Map<String, dynamic>);
    expect(dados.id, 'teste-2020');
    expect(dados.ano, 2020);
    expect(dados.dataAplicacao, DateTime(2020, 3, 15));
    expect(dados.gabaritoDefinitivoPublicado, isFalse);
    expect(dados.nome, 'FAFIPA 2020 · Teste');
  });

  test('ProvaReal.deJson monta Questao com a prova como unidade e origem adaptada', () {
    final prova = ProvaReal.deJson(_json());
    expect(prova.questoes, hasLength(1));
    final q = prova.questoes.single;
    expect(q.id, 'teste-2020-001');
    expect(q.materia, 'adm');
    expect(q.unidadeId, 'teste-2020');
    expect(q.origem.tipo, 'adaptada');
    expect(q.origem.prova, contains('FAFIPA 2020 · Teste'));
    expect(q.origem.prova, contains('gabarito preliminar'));
  });

  test('ProvaReal.deJson marca gabarito definitivo quando a prova diz isso', () {
    final prova = ProvaReal.deJson(_json(definitivo: true));
    expect(prova.questoes.single.origem.prova, contains('gabarito definitivo'));
  });

  test('sem nenhuma prova no banco (pasta ainda vazia), carregarProvas não quebra', () async {
    final provas = await carregarProvas();
    expect(provas, isA<List<ProvaReal>>());
  });

  test('letras seguem o mesmo conjunto A-E do resto do banco', () {
    final prova = ProvaReal.deJson(_json());
    expect(prova.questoes.single.alternativas.keys, letras);
  });
}
