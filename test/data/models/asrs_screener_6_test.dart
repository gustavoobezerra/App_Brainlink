import 'package:brainlink_app/data/models/asrs_screener_6.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ASRS v1.1 6Q', () {
    test('mantém as seis perguntas oficiais em português do Brasil', () {
      expect(
        AsrsScreener6.questions,
        [
          'Com que freqüência você sente dificuldade para finalizar os últimos '
              'detalhes de uma tarefa, depois de já ter feito as partes mais '
              'complicadas?',
          'Com que freqüência você sente dificuldade para manter as coisas em '
              'ordem quando precisa realizar uma tarefa que exige organização?',
          'Com que freqüência você tem problemas para se lembrar de compromissos '
              'ou obrigações?',
          'Quando precisa realizar uma tarefa que exige muita concentração, com '
              'que freqüência você evita ou atrasa o seu início?',
          'Com que freqüência você fica se mexendo na cadeira ou balançando as '
              'mãos ou os pés quando precisa ficar sentado(a) durante um longo '
              'período de tempo?',
          'Com que freqüência você se sente excessivamente ativo(a) e compelido(a) '
              'a fazer coisas, como se fosse conduzido(a) por um motor?',
        ],
      );
      expect(
        AsrsResponse.values.map((value) => value.label),
        [
          'Nunca',
          'Raramente',
          'Algumas vezes',
          'Freqüentemente',
          'Muito freqüentemente',
        ],
      );
    });

    test('atribui de zero a quatro pontos a cada resposta', () {
      expect(AsrsResponse.values.map((value) => value.points), [0, 1, 2, 3, 4]);
      expect(
        AsrsScreener6.score(List.filled(6, AsrsResponse.never)).total,
        0,
      );
      expect(
        AsrsScreener6.score(List.filled(6, AsrsResponse.veryOften)).total,
        24,
      );
    });

    test('classifica corretamente todos os limites da escala atualizada', () {
      AsrsScreenerResult resultFor(int total) {
        final answers = <AsrsResponse>[];
        var remaining = total;
        for (var index = 0; index < 6; index++) {
          final points = remaining.clamp(0, 4);
          answers.add(AsrsResponse.values[points]);
          remaining -= points;
        }
        return AsrsScreener6.score(answers);
      }

      expect(resultFor(9).band, AsrsScoreBand.lowNegative);
      expect(resultFor(10).band, AsrsScoreBand.highNegative);
      expect(resultFor(13).reachedScreeningCutoff, isFalse);
      expect(resultFor(13).possibilityLabel, 'Ponto de corte não atingido');
      expect(resultFor(13).guidance, contains('não exclui TDAH'));
      expect(resultFor(13).guidance, contains('não é diagnóstico'));
      expect(resultFor(14).band, AsrsScoreBand.lowPositive);
      expect(resultFor(14).reachedScreeningCutoff, isTrue);
      expect(resultFor(14).possibilityLabel, 'Possibilidade aumentada no ASRS');
      expect(
          resultFor(14).guidance, contains('possibilidade aumentada de TDAH'));
      expect(resultFor(14).guidance, contains('não é diagnóstico'));
      expect(resultFor(17).band, AsrsScoreBand.lowPositive);
      expect(resultFor(18).band, AsrsScoreBand.highPositive);
      expect(resultFor(24).band, AsrsScoreBand.highPositive);
    });

    test('recusa um preenchimento incompleto', () {
      expect(
        () => AsrsScreener6.score(List.filled(5, AsrsResponse.never)),
        throwsArgumentError,
      );
    });
  });
}
