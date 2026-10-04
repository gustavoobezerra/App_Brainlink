import 'package:brainlink_app/data/models/sessao_teste.dart';
import 'package:brainlink_app/services/teste/pontuacao_tarefa.dart';
import 'package:flutter_test/flutter_test.dart';

const int _ms = 1000000;

/// Ensaios com início em [inicioMs] (ms) e intervalo de 1000 ms.
List<Ensaio> _ensaios(List<(TipoEstimulo, int?)> definicao) => [
      for (var i = 0; i < definicao.length; i++)
        Ensaio(indice: i, tipo: definicao[i].$1, intervaloMs: 1000)
          ..inicioNanos =
              definicao[i].$2 == null ? null : definicao[i].$2! * _ms,
    ];

const _c = TipoEstimulo.comum;
const _r = TipoEstimulo.raro;

void main() {
  test('borda de 100 ms: 99 ms é antecipação, 100 ms é resposta', () {
    final ensaios = _ensaios([(_c, 0), (_c, 1000), (_c, 2000)]);
    final r = pontuarTarefa(
      ensaios: ensaios,
      toquesNanos: [99 * _ms, 1100 * _ms],
    );
    expect(r.antecipacoes, 1);
    expect(ensaios[0].toqueNanos, isNull);
    expect(ensaios[1].toqueNanos, 1100 * _ms);
    expect(r.acertos, 1);
    expect(r.omissoes, 2);
    expect(r.temposMs, [100]);
  });

  test('primeiro toque da janela é a resposta; demais são ignorados', () {
    final ensaios = _ensaios([(_c, 0), (_c, 1000)]);
    final r = pontuarTarefa(
      ensaios: ensaios,
      toquesNanos: [700 * _ms, 350 * _ms, 900 * _ms],
    );
    expect(ensaios[0].toqueNanos, 350 * _ms);
    expect(r.temposMs, [350]);
    expect(r.acertos, 1);
    expect(r.omissoes, 1);
    expect(r.antecipacoes, 0);
  });

  test('janela termina no início do próximo estímulo', () {
    final ensaios = _ensaios([(_c, 0), (_r, 1000)]);
    final r = pontuarTarefa(
      ensaios: ensaios,
      toquesNanos: [1000 * _ms],
    );
    // Exatamente no início do raro: antecipação do raro, não do comum.
    expect(ensaios[0].toqueNanos, isNull);
    expect(ensaios[1].toqueNanos, isNull);
    expect(r.antecipacoes, 1);
    expect(r.comissoes, 0);
    expect(r.omissoes, 1);
  });

  test('comum, raro: acertos, omissões e comissões', () {
    final ensaios =
        _ensaios([(_c, 0), (_c, 1000), (_r, 2000), (_r, 3000), (_c, 4000)]);
    final r = pontuarTarefa(
      ensaios: ensaios,
      toquesNanos: [300 * _ms, 2400 * _ms, 4250 * _ms],
    );
    expect(r.comuns, 3);
    expect(r.acertos, 2);
    expect(r.omissoes, 1);
    expect(r.raros, 2);
    expect(r.comissoes, 1);
    expect(r.temposMs, [300, 250]);
    expect(r.tempoMedioMs, 275);
    expect(ensaios[2].toqueNanos, 2400 * _ms);
  });

  test('último ensaio: janela até início + intervaloMs (inclusive)', () {
    final dentro = _ensaios([(_c, 0)]);
    expect(
      pontuarTarefa(ensaios: dentro, toquesNanos: [1000 * _ms]).acertos,
      1,
    );
    final fora = _ensaios([(_c, 0)]);
    final r = pontuarTarefa(ensaios: fora, toquesNanos: [1000 * _ms + 1]);
    expect(r.acertos, 0);
    expect(r.omissoes, 1);
    expect(fora.single.toqueNanos, isNull);
  });

  test('interrompidos e sem início ficam fora; a janela os pula', () {
    final ensaios = _ensaios([(_c, 0), (_c, 1000), (_r, null), (_c, 3000)]);
    ensaios[1].interrompido = true;
    final r = pontuarTarefa(
      ensaios: ensaios,
      // 1500 ms: cai na janela do 1º (até o próximo válido, em 3000 ms).
      toquesNanos: [1500 * _ms, 3200 * _ms],
    );
    expect(r.comuns, 2);
    expect(r.raros, 0);
    expect(r.acertos, 2);
    expect(r.temposMs, [1500, 200]);
    expect(ensaios[1].toqueNanos, isNull);
  });

  test('ordena por início e limpa toques antigos', () {
    final ensaios = _ensaios([(_c, 2000), (_c, 0)]);
    ensaios[0].toqueNanos = 123;
    final r = pontuarTarefa(ensaios: ensaios, toquesNanos: [500 * _ms]);
    expect(ensaios[1].toqueNanos, 500 * _ms);
    expect(ensaios[0].toqueNanos, isNull);
    expect(r.temposMs, [500]);
  });

  test('toques antes do primeiro estímulo e depois do fim são ignorados', () {
    final ensaios = _ensaios([(_c, 1000)]);
    final r = pontuarTarefa(
      ensaios: ensaios,
      toquesNanos: [10 * _ms, 5000 * _ms],
    );
    expect(r.antecipacoes, 0);
    expect(r.acertos, 0);
  });

  test('tempo médio arredondado e nulo sem acertos', () {
    final ensaios = _ensaios([(_c, 0), (_c, 1000)]);
    final r = pontuarTarefa(
      ensaios: ensaios,
      toquesNanos: [300 * _ms + 400000, 1301 * _ms],
    );
    expect(r.temposMs, [300, 301]);
    expect(r.tempoMedioMs, 301);

    final vazio = pontuarTarefa(ensaios: _ensaios([(_r, 0)]), toquesNanos: []);
    expect(vazio.acertos, 0);
    expect(vazio.tempoMedioMs, isNull);
    expect(pontuarTarefa(ensaios: [], toquesNanos: [1]).tempoMedioMs, isNull);
  });
}
