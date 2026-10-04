---
titulo: Complemento PubMed à pesquisa EEG-TDAH
tags: [pesquisa, pubmed, complemento]
status: em-aberto
atualizado: 2026-10-03
complementa: PESQUISA-EEG-TDAH-2026-10-03.md
---

# Complemento PubMed à pesquisa EEG e TDAH

Levantamento feito em 3 de outubro de 2026 no **PubMed** (conector oficial),
depois da leitura do `README.md`, do `vault/` inteiro, do
[PESQUISA-EEG-TDAH-2026-10-03](PESQUISA-EEG-TDAH-2026-10-03.md), das três notas
dos especialistas e de `lib/services/eeg_spectrum_analyzer.dart`.

O objetivo não foi refazer a pesquisa de hoje, que já é sólida, mas responder
três perguntas que ela deixou abertas:

1. O que o PubMed **confirma, corrige ou acrescenta** ao que já decidimos?
2. Existe **outra forma de usar o que o BrainLink já mede**, que ninguém no
   projeto explorou?
3. O que muda, na prática, no app e no plano de validação?

> [!warning] Mesma regra do projeto
> Nada aqui autoriza o app a afirmar presença, ausência ou grau de TDAH. As
> propostas são hipóteses de pesquisa. Ver `vault/30-regulatorio/linguagem-permitida.md`.

> [!note] Limite deste levantamento
> Foram lidos **título e resumo** (abstract) dos artigos no PubMed, não o texto
> integral. Números citados abaixo são os que aparecem no resumo. Antes de usar
> qualquer número em texto formal (TCC, PROBIC), ler o artigo completo — a
> maioria tem PMC aberto, indicado na tabela final.

---

## Resumo em uma página

| # | Achado | Força | O que muda |
| --- | --- | --- | --- |
| 1 | **O ASRS-6 tem evidência brasileira**: AUC 0,82 em 805 adultos (Costa 2026) | Boa | Reforça o núcleo do app; citar no relatório |
| 2 | O ASRS-6 é **específico na comunidade e pouco específico em rastreio amplo** | Boa | Justifica a frase "não é diagnóstico" com número |
| 3 | O **expoente aperiódico não separou TDAH** em 1.426 jovens (registered report) | Forte | Rebaixa a aposta principal da A2 |
| 4 | Expoente e alfa são **estáveis em 5 anos** (ICC 0,51–0,88), mas o expoente muda muito entre olhos abertos e fechados | Boa | Apoia a linha de base pessoal **se** o estado for padronizado |
| 5 | **Estimulante altera o expoente** — em crianças e em adultos saudáveis | Boa | Medicação precisa ser registrada em toda sessão |
| 6 | **Piscadas e movimentos oculares** carregam informação sobre atenção; Fp1 os capta | Fraca a moderada | **Nova abordagem (A6)**: tratar a piscada como sinal, não só como lixo |
| 7 | **Variabilidade do tempo de reação** (τ ex-Gaussiano) é um dos achados mais consistentes em TDAH | Boa (meta-análise) | Fortalece a A3 e diz qual medida priorizar |
| 8 | **Medir movimento** durante a tarefa superou o EEG NeuroSky em um estudo direto | Moderada | Ideia barata: câmera ou acelerômetro do celular |
| 9 | Headsets NeuroSky tiveram o **pior desempenho** em revisão de detecção de sonolência | Moderada | Mais um motivo para não exibir índices eSense |

---

## 1. O que o PubMed confirma no ASRS — o núcleo do app

**Explicação simples.** Pense no app como um carro com dois motores: o ASRS é
o motor que funciona; o EEG é o motor ainda em teste na bancada. Antes de
mexer no motor experimental, vale saber o quanto o motor principal é bom.

### Evidência no Brasil

- **Costa e colaboradores, 2026** — 805 adultos brasileiros, com e sem
  diagnóstico prévio relatado. As seis perguntas da Parte A (o mesmo ASRS-6 do
  app) discriminaram o diagnóstico relatado com **AUC = 0,82**. Os autores
  escrevem que, em taxas de base realistas, o valor preditivo positivo cai, e
  que **um resultado positivo indica avaliação adicional**, com cortes ainda
  preliminares. [DOI](https://doi.org/10.1080/23279095.2026.2735472)
  - Limitação: o diagnóstico foi **relatado pela própria pessoa**, não
    confirmado por avaliação clínica no estudo.

Isso é valioso porque, até agora, o vault citava o ASRS apenas pela fonte de
Harvard. Agora há um estudo em adultos brasileiros.

### Evidência internacional

| Estudo | Amostra | Resultado do ASRS-6 |
| --- | --- | --- |
| Kessler 2005 — estudo original | 154 adultos da NCS-R, diagnóstico clínico cego | Sensibilidade 68,7%, especificidade 99,5% [DOI](https://doi.org/10.1017/s0033291704002892) |
| Brevik 2020 — Noruega | 646 pacientes diagnosticados + 908 controles | AUC 0,903 (IC95% 0,886–0,920), igual ao ASRS completo [DOI](https://doi.org/10.1002/brb3.1605) |
| Lewczuk 2024 — 42 países | 72.627 pessoas | 18–21% "em risco"; os autores reforçam a **baixa especificidade** dos rastreios adultos [DOI](https://doi.org/10.1177/10870547231215518) |
| Gray 2014 — universitários com TDAH | 135 estudantes | Concordância telefone × papel r = 0,66; autorrelato × informante r = 0,47 [DOI](https://doi.org/10.7717/peerj.324) |

**Como ler essa aparente contradição** (especificidade de 99,5% em um estudo e
"baixa especificidade" em outro): depende de **quem responde**. Numa amostra
comunitária com diagnóstico clínico cuidadoso, quase ninguém sem TDAH pontua
alto. Numa pesquisa online aberta, com muita gente estressada, ansiosa ou
deprimida, muitas pontuam alto sem ter TDAH — a nota de validação do projeto já
citava Dunlop 2018 sobre depressão e ansiedade. A conta de VPP do documento de
hoje (17,4% com prevalência de 5%) é exatamente o efeito que Lewczuk observa
em escala.

**Ação sugerida:** citar Costa 2026 e Brevik 2020 no relatório exportado e em
`vault/10-ciencia/escalas-validadas.md`, ao lado do aviso de não diagnóstico.

---

## 2. O que o PubMed corrige na aposta do expoente aperiódico

**Explicação simples.** O expoente aperiódico é como a "inclinação do terreno"
do espectro. A esperança do plano (A2) era que pessoas com TDAH tivessem um
terreno com inclinação diferente. Um estudo grande, com plano registrado antes
de ver os dados, mediu isso e não encontrou a diferença.

### O estudo mais importante desta busca

- **Panda e colaboradores, 2026 — registered report**, Healthy Brain Network.
  863 meninos e 320 meninas com TDAH; 136 meninos e 107 meninas sem TDAH; 5 a
  18 anos; controle de nível socioeconômico, QI e medicação. Conclusão textual:
  **nem a atividade aperiódica nem o seu desenvolvimento diferem de forma
  confiável** entre pessoas com e sem TDAH. O expoente cai linearmente com a
  idade em todos. [DOI](https://doi.org/10.1016/j.dcn.2026.101732) · PMC13187580

O documento de hoje já citava esse artigo pelo link do PMC ("outra análise
ampla pediátrica não encontrou efeito principal"). O PubMed acrescenta o peso:
é um **registered report** com mais de 1.400 participantes — o formato que
mais protege contra resultado inflado.

Somado à análise multiverso do TBR, o quadro fica assim:

```text
TBR bruto            → refutado (multiverso, AAN)
Expoente aperiódico  → não separou TDAH no maior estudo pré-registrado
IAF e alfa           → estáveis e medíveis, mas sem evidência de separar TDAH em Fp1
```

### Estudos menores que apontam diferenças — e por que não bastam

| Estudo | Achado | Por que não resolve |
| --- | --- | --- |
| Robertson 2019 | Crianças de 3–7 anos **sem medicação** com TDAH: inclinação mais íngreme; com estimulante, igual aos controles [DOI](https://doi.org/10.1152/jn.00388.2019) | Idade pré-escolar; efeito some com tratamento |
| Karalunas 2022 | Adolescentes com TDAH **nunca medicados**: expoente menor; medicados, não [DOI](https://doi.org/10.1002/dev.22228) | Direção oposta à de Robertson |
| Arnett 2022 | Expoente achatado só em **quem não respondeu** ao metilfenidato [DOI](https://doi.org/10.3389/fnbeh.2022.887622) | 29 crianças |

Ou seja: quando aparece efeito, ele **muda de direção com a idade e some com a
medicação**. Isso é coerente com Panda 2026 e não sustenta um corte.

**Ação sugerida:** manter o expoente como **descrição da sessão** e como
variável de pesquisa, mas registrar em ADR que ele **deixou de ser o candidato
principal** de discriminação. A hipótese H2 do documento de hoje continua
válida como teste de **interpretação** (separar fundo de picos), não de
**diagnóstico**.

---

## 3. O que o PubMed acrescenta sobre confiabilidade — a linha de base pessoal

**Explicação simples.** Uma balança só serve para acompanhar o peso se der o
mesmo número quando nada mudou. A linha de base intra-sujeito do projeto
depende disso. Agora há dados de cinco anos.

| Estudo | O que mediu | Resultado |
| --- | --- | --- |
| Politanskaia 2026 | Adultos de 20–70 anos, duas sessões com ~5 anos de intervalo | Expoente, offset, potência alfa e IAF com **ICC de 0,51 a 0,88**; IAF caiu e o expoente achatou com o tempo [DOI](https://doi.org/10.1093/cercor/bhag113) |
| Park 2026 | Adultos saudáveis, 5 anos, também com **menos canais** | Alfa posterior relativo: ICC 0,843 e maior diferença olhos fechados × abertos (d = 1,553). IAF: ICC 0,734. **Expoente: ICC 0,668 e forte dependência do estado** (d = −0,761 entre olhos abertos e fechados) [DOI](https://doi.org/10.3389/fnagi.2026.1885392) |
| Kałamała 2026 | Confiabilidade do ajuste aperiódico | Permitir mais picos no FOOOF **reduz** a confiabilidade; regressão censurada é mais estável [DOI](https://doi.org/10.1111/psyp.70272) |
| Jiang 2026 | Largura da banda alfa individual (IAB) | Reteste bom a excelente; associações dependem do método (só com Savitzky-Golay) [DOI](https://doi.org/10.1016/j.neuroimage.2026.121685) |
| Cazares 2026 (preprint indexado) | Mudança do expoente em 5 anos | A queda do expoente na mesma pessoa acompanhou a mudança no tempo de reação de vigilância (PVT) [DOI](https://doi.org/10.64898/2026.07.22.739645) |

### O que isso significa para o app

1. **A comparação "você com você mesmo" é defensável** para alfa e IAF em
   adultos. Isso sustenta a decisão de público 18+ do `PLANO-DE-MUDANCA`.
2. **Olhos abertos e olhos fechados nunca podem ser misturados** numa linha de
   base. O protocolo atual (1 min + 1 min) já separa as fases — isso está certo
   e agora tem justificativa numérica.
3. Atenção: todos esses estudos usam EEG multicanal de laboratório. A
   confiabilidade **no BrainLink Lite** continua sendo algo que o próprio
   projeto precisa medir (Marco 3 do documento de hoje).
4. **Medida alternativa barata:** a potência alfa relativa foi a mais estável e
   a mais sensível ao fechar os olhos. É a melhor candidata a "teste de
   sanidade" por sessão — sem virar critério de invalidação automática, como o
   documento de hoje já corrigiu.

---

## 4. Medicação, sono e cafeína mudam o sinal

**Explicação simples.** Se você mede a temperatura de alguém logo depois de um
café quente, o termômetro está certo, mas a leitura não diz o que você queria.
O mesmo acontece com o EEG e o remédio.

- **Gao 2024** — ensaio duplo-cego com placebo em 25 adultos **sem TDAH**:
  metilfenidato 0,5 mg/kg **aumentou o expoente aperiódico**.
  [DOI](https://doi.org/10.1093/ijnp/pyae033)
- **Pertermann 2019** — 29 jovens com TDAH: mais "ruído neural" 1/f durante
  NoGo; o metilfenidato reduziu ao nível dos controles.
  [DOI](https://doi.org/10.1016/j.bpsc.2019.03.011)
- **Walter 2026** — 54 adultos com TDAH × 47 controles, actigrafia por 10 dias:
  ritmo de sono mais instável e atrasado; latência de sono maior associada a
  pior atenção seletiva (associações enfraqueceram após correção para
  múltiplos testes). [DOI](https://doi.org/10.1186/s12888-026-07947-9)

**Ação sugerida — pequena e concreta:** antes da coleta, três perguntas rápidas,
gravadas no relatório e **nunca** usadas em cálculo de possibilidade:

```text
1. Tomou medicação para atenção hoje?   [sim / não / prefiro não dizer]
2. Quantas horas dormiu na última noite? [<5 / 5–7 / >7]
3. Tomou café ou energético nas últimas 3 h? [sim / não]
```

Isso transforma "o EEG variou" em "o EEG variou **no dia em que dormiu 4 horas**",
que é o que o profissional consegue usar. Combina com o diário da A1.

---

## 5. Nova abordagem proposta: A6 — a piscada como sinal

Esta é a ideia nova desta pesquisa. **Nenhum documento do projeto trata a
taxa de piscadas ou o momento das piscadas como medida.** Hoje, o app trata
toda piscada como artefato e descarta a época inteira.

### Explicação simples

O sensor do BrainLink fica na testa, a poucos centímetros dos olhos. O
`vault/10-ciencia/artefatos-canal-unico.md` explica que isso é um problema: a
piscada contamina delta e theta. Mas existe o outro lado da moeda: **o BrainLink
é, de graça, um ótimo detector de piscadas.** É como um microfone que capta o
barulho do vento: para gravar voz é ruído, mas se você quer medir o vento,
é exatamente o sinal certo.

E a piscada não é aleatória. O cérebro **segura** a piscada quando espera algo
importante e **solta** logo depois. Isso tem relação com atenção e com
dopamina.

### O que a literatura diz (PubMed)

| Estudo | Amostra | Achado |
| --- | --- | --- |
| Fried 2014 | 22 pacientes com TDAH (com e sem metilfenidato) × 22 controles, durante o TOVA | Taxas de piscadas e microssacadas **maiores** no TDAH, sobretudo **perto do estímulo**; aumento mais rápido ao longo da sessão sem medicação; os autores interpretam como falha em manter o nível de alerta [DOI](https://doi.org/10.1016/j.visres.2014.05.004) |
| Groen 2015 | 16 crianças com TDAH sem medicação, 16 com, 18 controles; EOG, 60 min de tarefa | **Não** encontrou diferença na taxa nem na modulação repouso → tarefa; só redução pequena e rara (<1% dos ensaios) da inibição da piscada antes do estímulo [DOI](https://doi.org/10.1007/s00702-015-1457-6) |
| Chamorro 2021 — meta-análise | 31 estudos, 1.567 participantes | Falhas de **inibição oculomotora** no TDAH; sacadas durante **fixação prolongada**: g = 1,11 (heterogeneidade alta) [DOI](https://doi.org/10.1016/j.bpsc.2021.05.004) |
| Carr 2006 | Adultos com TDAH | **Sacadas antecipatórias** persistiram mesmo quando os sintomas melhoraram parcialmente [DOI](https://doi.org/10.1037/0894-4105.20.4.430) |
| Armstrong 2003 | 15 adultos com TDAH × controles | Mais movimentos oculares e **instabilidade do olhar** durante tarefa de atenção [DOI](https://doi.org/10.1007/s00221-003-1535-0) |
| Perquin 2019 | >100 adultos saudáveis | Taxa de piscadas tem **boa confiabilidade intraindividual**, mas **não** se correlacionou com traços de TDAH autorrelatados [DOI](https://doi.org/10.16910/jemr.12.6.11) |
| Korponay 2017 | 105 adultos saudáveis | Menor taxa espontânea de piscadas associada a mais impulsividade motora e pior acerto no no-go [DOI](https://doi.org/10.1016/j.neuroimage.2017.06.015) |
| Chang 2015 | 24 adultos | Método validado para **detectar piscadas em um único canal pré-frontal**, sem eletrodo de olho; código aberto ("Eyeblink Master") [DOI](https://doi.org/10.1016/j.cmpb.2015.10.011) |

### Leitura honesta

- A evidência é **mista**: Fried encontrou diferença, Groen não, Perquin não
  achou correlação com traço autorrelatado.
- O sinal mais promissor **não é a taxa média**, e sim o **momento**: a
  piscada em relação ao estímulo (inibição antecipatória) e a **evolução ao
  longo do tempo de tarefa** (fadiga de vigilância).
- O ponto forte é de **engenharia**: medir piscadas com um canal frontal já
  foi validado (Chang 2015), é exatamente o que o BrainLink entrega e é muito
  menos sensível a ganho, referência e filtro do que medir µV² de theta.

### Por que vale entrar no projeto mesmo com evidência mista

1. **Melhora a qualidade já hoje, sem nenhuma alegação nova.** Contar piscadas
   permite dizer *por que* uma época foi rejeitada ("38% das épocas perdidas por
   piscada; 4% por contato"). O relatório fica mais útil e a orientação ao
   usuário fica precisa ("tente piscar menos" × "reposicione o sensor").
2. **Verifica se a pessoa fechou mesmo os olhos.** Na fase de olhos fechados,
   o número esperado de piscadas é perto de zero. Muitas piscadas = a fase não
   foi cumprida. É um controle de protocolo que hoje não existe.
3. **Abre a hipótese H7** para a tarefa da A3, a custo quase zero.

### Hipótese H7 (para a tabela de hipóteses)

| Hipótese | Medida | Evidência que a sustentaria | Critério de rejeição |
| --- | --- | --- | --- |
| H7 Dinâmica das piscadas acrescenta informação à tarefa | Taxa por bloco, inclinação ao longo do tempo, fração de piscadas na janela de 0–500 ms antes do alvo | Ganho fora da amostra sobre o mesmo modelo sem piscadas, frente a diagnóstico independente | Sem ganho, ou ganho explicado por cansaço/olho seco/lentes de contato |

Confundidores que precisam ser registrados: **lente de contato, olho seco,
alergia, tela muito clara, horário, sono**. Taxa de piscadas também sobe com
conversa e cai com leitura.

### Esboço de código (não aplicado ao app)

Ideia: antes de rejeitar a época, procurar as piscadas no sinal em µV. Os
limiares abaixo são **ponto de partida para calibrar** com gravações reais do
BrainLink Lite — a polaridade depende da derivação (o documento de hoje aponta
F7–Fp1 bipolar no Lite), por isso o detector usa valor absoluto.

```dart
/// Detector simples de piscadas para um canal frontal.
/// Parâmetros iniciais, a calibrar no BrainLink Lite físico.
class BlinkDetector {
  const BlinkDetector({
    this.sampleRateHz = 512,
    this.thresholdMicrovolts = 80,   // amplitude mínima após filtro
    this.minDurationMs = 50,
    this.maxDurationMs = 500,        // piscada típica: 100–400 ms
    this.refractoryMs = 150,
  });

  final int sampleRateHz;
  final double thresholdMicrovolts;
  final int minDurationMs;
  final int maxDurationMs;
  final int refractoryMs;

  /// Devolve o índice da amostra de pico de cada piscada.
  List<int> detect(List<double> microvolts) {
    final smooth = _lowPassMovingAverage(microvolts, sampleRateHz ~/ 25);
    final baseline = _median(smooth);
    final minLen = minDurationMs * sampleRateHz ~/ 1000;
    final maxLen = maxDurationMs * sampleRateHz ~/ 1000;
    final refractory = refractoryMs * sampleRateHz ~/ 1000;

    final peaks = <int>[];
    var i = 0;
    while (i < smooth.length) {
      if ((smooth[i] - baseline).abs() < thresholdMicrovolts) { i++; continue; }
      final start = i;
      var peak = i;
      while (i < smooth.length &&
          (smooth[i] - baseline).abs() >= thresholdMicrovolts) {
        if ((smooth[i] - baseline).abs() > (smooth[peak] - baseline).abs()) {
          peak = i;
        }
        i++;
      }
      final length = i - start;
      final farFromLast = peaks.isEmpty || peak - peaks.last > refractory;
      if (length >= minLen && length <= maxLen && farFromLast) peaks.add(peak);
    }
    return peaks;
  }

  /// Piscadas por minuto num trecho.
  double ratePerMinute(List<double> microvolts) =>
      detect(microvolts).length / (microvolts.length / sampleRateHz / 60);

  static List<double> _lowPassMovingAverage(List<double> x, int window) {
    final out = List<double>.filled(x.length, 0);
    var sum = 0.0;
    for (var n = 0; n < x.length; n++) {
      sum += x[n];
      if (n >= window) sum -= x[n - window];
      out[n] = sum / (n < window ? n + 1 : window);
    }
    return out;
  }

  static double _median(List<double> x) {
    final s = [...x]..sort();
    return s.isEmpty ? 0 : s[s.length ~/ 2];
  }
}
```

Como validar antes de confiar:

1. Gravar 2 minutos pedindo **piscadas voluntárias a cada 3 s** (marcadas pelo
   app) e 2 minutos de olhos abertos normais. Medir sensibilidade e falsos
   positivos.
2. Comparar com contagem manual em vídeo da câmera frontal (o projeto não
   precisa guardar o vídeo — só a contagem).
3. Testar movimento de mandíbula e de sobrancelha, que também geram picos na
   testa e não são piscadas.

Saída permitida na interface: **"Piscadas por minuto nesta fase: 14"**, sempre
como descrição da coleta. Saída proibida: qualquer relação com TDAH.

---

## 6. Variabilidade do tempo de reação — a medida a priorizar na A3

**Explicação simples.** Duas pessoas podem ter a mesma média de tempo de
reação. Uma responde sempre em ~400 ms; a outra responde quase sempre rápido,
mas de vez em quando "some" e demora 1.200 ms. A média esconde isso. O
parâmetro **τ (tau)** da distribuição ex-Gaussiana mede justamente essa "cauda"
de respostas muito lentas — os lapsos de atenção.

- **Bella-Fernández 2023 — meta-análise**: τ e σ são, em geral, **maiores em
  amostras com TDAH**; μ só difere em idades menores; os efeitos variam com o
  intervalo entre estímulos e com o tipo de tarefa (CPT, Go/No-Go).
  [DOI](https://doi.org/10.1007/s11065-023-09587-2)
- **Chamorro 2021** também encontrou maior **coeficiente de variação** das
  sacadas no TDAH (g = 0,53). [DOI](https://doi.org/10.1016/j.bpsc.2021.05.004)

Combinado com a ressalva do documento de hoje (Brunkhorst-Kanaan 2020: em
pacientes **encaminhados**, os parâmetros ex-Gaussianos não separaram bem os
diagnósticos), a conclusão é: **τ é a melhor medida comportamental para
documentar, e a pior para prometer.** Diferencia grupos em média; não resolve
o diagnóstico diferencial.

**Ação sugerida:** quando a A3 for implementada, registrar os tempos de reação
**individuais** (não só a média), para permitir μ, σ, τ e CV_RT depois, offline.

---

## 7. Outra forma barata: medir movimento

**Explicação simples.** Uma das três letras do TDAH é *hiperatividade*. O
celular que roda o app tem câmera frontal e acelerômetro. Medir quanto a
pessoa se mexe durante a tarefa pode ser mais informativo do que o índice de
"atenção" do fabricante.

- **Chu 2020** — 63 crianças com NeuroSky Mindset e actígrafo: o índice
  "attention" do NeuroSky correlacionou com mudanças no tempo de reação, mas
  **o actígrafo superou o EEG** no rastreio de TDAH. Mesma família de chip
  (ThinkGear) do BrainLink. [DOI](https://doi.org/10.2196/12158)
- **Ulberstad 2020 — QbCheck** — teste online que mede erros, tempo de reação e
  **movimento pela webcam**: 142 adolescentes/adultos, sensibilidade 82,6% e
  especificidade 79,5%. Estudo ligado à empresa que vende o teste.
  [DOI](https://doi.org/10.1002/mpr.1822)
- **Tomlinson 2025 — revisão sistemática do NIHR** sobre CPT com sensor de
  movimento: em crianças, somar o QbTest à avaliação clínica **não mudou a
  acurácia**, mas reduziu consultas e tempo até a decisão; **dados
  insuficientes em adultos**. [DOI](https://doi.org/10.3310/DRDR7171)

**Leitura honesta:** isso não é motivo para trocar o EEG pela câmera, mas
mostra duas coisas úteis para o projeto:

1. O índice eSense ("atenção") é fraco até frente a um sensor de movimento
   simples — reforça `vault/20-hardware/indices-esense.md`.
2. Movimento da cabeça é **também artefato do EEG**. Medir movimento ajuda a
   explicar épocas rejeitadas, do mesmo jeito que a contagem de piscadas.

Proposta mínima: durante a coleta, gravar a **variância do acelerômetro do
celular** (se o celular estiver apoiado na mesa, ela mede batidas na mesa; se
estiver na mão, mede o tremor da mão). Sem câmera, sem imagem, sem dado
sensível novo. Usar só como controle de qualidade nesta fase.

---

## 8. O hardware de consumo segundo o PubMed

- **LaRocco 2020 — revisão de headsets baratos para sonolência**: de cerca de
  27 estudos com acurácia relatada, **o NeuroSky MindWave teve a menor
  (mínimo de 31%)**; os autores lembram que métricas e definições diferentes
  impedem comparação direta, e que mesmo bandas simples detectaram sonolência
  de forma consistente. [DOI](https://doi.org/10.3389/fninf.2020.553352)
- A revisão de escopo de 2024 sobre EEG de consumo e o dataset de 2026 com
  sistemas de consumo e de pesquisa (já no vault como ref-07/ref-08) aparecem
  também no PubMed (PMIDs 38446762 e 41786741).

Nenhum estudo indexado no PubMed com o termo "BrainLink" validou o Lite para
TDAH. A busca por `NeuroSky OR ThinkGear OR MindWave OR TGAM OR BrainLink` com
validação retornou 30 registros, quase todos de aplicações (emoção,
personalidade, VR), nenhum com diagnóstico clínico de TDAH em adultos.

---

## 9. O que muda no projeto — lista priorizada

| Prioridade | Mudança | Tipo | Esforço | Fonte |
| --- | --- | --- | --- | --- |
| 1 | Citar Costa 2026 e Brevik 2020 junto do ASRS no relatório e no vault | Documentação | Baixo | §1 |
| 2 | Perguntas de contexto: medicação, sono, cafeína (registro, sem cálculo) | Produto | Baixo | §4 |
| 3 | Contar piscadas por fase e informar o motivo das rejeições | Qualidade | Baixo-médio | §5 |
| 4 | Usar a contagem de piscadas na fase de olhos fechados como checagem de protocolo | Qualidade | Baixo | §5 |
| 5 | Novo ADR: expoente aperiódico deixa de ser candidato principal de discriminação | Decisão | Baixo | §2 |
| 6 | Adicionar H7 (piscadas) e priorizar τ na A3; gravar tempos individuais | Pesquisa | Médio | §5, §6 |
| 7 | Medir confiabilidade no próprio Lite: alfa relativo, IAF, expoente, piscadas/min | Pesquisa | Médio | §3 |
| 8 | Variância do acelerômetro como controle de qualidade | Qualidade | Baixo | §7 |

As prioridades 1 a 5 **não acrescentam nenhuma alegação clínica** — só melhoram
a documentação, o contexto e o controle de qualidade. Por isso podem entrar
antes de qualquer validação.

---

## Referências desta busca (PubMed)

Todas recuperadas pelo conector do PubMed em 03/10/2026. Lidos: título e
resumo.

| PMID | Primeiro autor, ano | Periódico | DOI | Texto aberto |
| --- | --- | --- | --- | --- |
| 42771540 | Costa, 2026 | Appl Neuropsychol Adult | [10.1080/23279095.2026.2735472](https://doi.org/10.1080/23279095.2026.2735472) | — |
| 15841682 | Kessler, 2005 | Psychol Med | [10.1017/s0033291704002892](https://doi.org/10.1017/s0033291704002892) | — |
| 32285644 | Brevik, 2020 | Brain Behav | [10.1002/brb3.1605](https://doi.org/10.1002/brb3.1605) | PMC7303368 |
| 38180045 | Lewczuk, 2024 | J Atten Disord | [10.1177/10870547231215518](https://doi.org/10.1177/10870547231215518) | — |
| 24711973 | Gray, 2014 | PeerJ | [10.7717/peerj.324](https://doi.org/10.7717/peerj.324) | — |
| 42107212 | Panda, 2026 | Dev Cogn Neurosci | [10.1016/j.dcn.2026.101732](https://doi.org/10.1016/j.dcn.2026.101732) | PMC13187580 |
| 31619109 | Robertson, 2019 | J Neurophysiol | [10.1152/jn.00388.2019](https://doi.org/10.1152/jn.00388.2019) | PMC6966317 |
| 35312046 | Karalunas, 2022 | Dev Psychobiol | [10.1002/dev.22228](https://doi.org/10.1002/dev.22228) | PMC9707315 |
| 35600991 | Arnett, 2022 | Front Behav Neurosci | [10.3389/fnbeh.2022.887622](https://doi.org/10.3389/fnbeh.2022.887622) | PMC9121006 |
| 42574751 | Politanskaia, 2026 | Cereb Cortex | [10.1093/cercor/bhag113](https://doi.org/10.1093/cercor/bhag113) | PMC13456336 |
| 42395346 | Park, 2026 | Front Aging Neurosci | [10.3389/fnagi.2026.1885392](https://doi.org/10.3389/fnagi.2026.1885392) | PMC13323486 |
| 41853983 | Kałamała, 2026 | Psychophysiology | [10.1111/psyp.70272](https://doi.org/10.1111/psyp.70272) | PMC13000880 |
| 41490565 | Jiang, 2026 | NeuroImage | [10.1016/j.neuroimage.2026.121685](https://doi.org/10.1016/j.neuroimage.2026.121685) | — |
| 42619668 | Cazares, 2026 | preprint indexado | [10.64898/2026.07.22.739645](https://doi.org/10.64898/2026.07.22.739645) | — |
| 39096235 | Gao, 2024 | Int J Neuropsychopharmacol | [10.1093/ijnp/pyae033](https://doi.org/10.1093/ijnp/pyae033) | PMC11348007 |
| 31103546 | Pertermann, 2019 | Biol Psychiatry CNNI | [10.1016/j.bpsc.2019.03.011](https://doi.org/10.1016/j.bpsc.2019.03.011) | — |
| 41803808 | Walter, 2026 | BMC Psychiatry | [10.1186/s12888-026-07947-9](https://doi.org/10.1186/s12888-026-07947-9) | PMC13085561 |
| 24863585 | Fried, 2014 | Vision Res | [10.1016/j.visres.2014.05.004](https://doi.org/10.1016/j.visres.2014.05.004) | — |
| 26471801 | Groen, 2015 | J Neural Transm | [10.1007/s00702-015-1457-6](https://doi.org/10.1007/s00702-015-1457-6) | PMC5281678 |
| 34052459 | Chamorro, 2021 | Biol Psychiatry CNNI | [10.1016/j.bpsc.2021.05.004](https://doi.org/10.1016/j.bpsc.2021.05.004) | — |
| 16846261 | Carr, 2006 | Neuropsychology | [10.1037/0894-4105.20.4.430](https://doi.org/10.1037/0894-4105.20.4.430) | — |
| 12851805 | Armstrong, 2003 | Exp Brain Res | [10.1007/s00221-003-1535-0](https://doi.org/10.1007/s00221-003-1535-0) | — |
| 33828751 | Perquin, 2019 | J Eye Mov Res | [10.16910/jemr.12.6.11](https://doi.org/10.16910/jemr.12.6.11) | PMC7962678 |
| 28602816 | Korponay, 2017 | NeuroImage | [10.1016/j.neuroimage.2017.06.015](https://doi.org/10.1016/j.neuroimage.2017.06.015) | PMC5600835 |
| 26560852 | Chang, 2015 | Comput Methods Programs Biomed | [10.1016/j.cmpb.2015.10.011](https://doi.org/10.1016/j.cmpb.2015.10.011) | — |
| 36877328 | Bella-Fernández, 2023 | Neuropsychol Rev | [10.1007/s11065-023-09587-2](https://doi.org/10.1007/s11065-023-09587-2) | PMC10920450 |
| 32558658 | Chu, 2020 | JMIR Ment Health | [10.2196/12158](https://doi.org/10.2196/12158) | PMC7351267 |
| 32100383 | Ulberstad, 2020 | Int J Methods Psychiatr Res | [10.1002/mpr.1822](https://doi.org/10.1002/mpr.1822) | PMC7301281 |
| 41220181 | Tomlinson, 2025 | Health Technol Assess | [10.3310/DRDR7171](https://doi.org/10.3310/DRDR7171) | PMC12668258 |
| 33178004 | LaRocco, 2020 | Front Neuroinform | [10.3389/fninf.2020.553352](https://doi.org/10.3389/fninf.2020.553352) | PMC7593569 |

Fonte de busca: PubMed / NCBI (https://pubmed.ncbi.nlm.nih.gov/).
