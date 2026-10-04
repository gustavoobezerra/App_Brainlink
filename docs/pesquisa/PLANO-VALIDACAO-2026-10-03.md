---
titulo: Plano de validação e mudança tecnológica
tags: [validacao, engenharia, pesquisa]
status: em-aberto
atualizado: 2026-10-03
complementa: [PESQUISA-EEG-TDAH-2026-10-03.md, PESQUISA-PUBMED-COMPLEMENTO-2026-10-03.md]
---

# Como validar o que o App BrainLink faz

Documento escrito a partir de três artigos indicados pela equipe, lidos em 3 de
outubro de 2026, e do código atual do app. Junto com ele vai um programa que já
roda: `tools/validacao/pipeline_referencia.py`.

> [!warning] Mesma regra de sempre
> Validar o **processamento** e a **medida** não é validar um **diagnóstico**.
> Nada aqui autoriza o app a falar em TDAH a partir do EEG.

---

## 1. Os três artigos, em uma linha cada

| Artigo | O que fez | O que serve para nós |
| --- | --- | --- |
| **Lansbergen et al., 2011** — 49 meninos com TDAH × 49 controles ([DOI](https://doi.org/10.1016/j.pnpbp.2010.08.004)) | A razão theta/beta com bandas fixas foi maior no TDAH; com bandas **ajustadas ao pico alfa de cada criança**, a diferença **sumiu** | Um resultado publicado que dá para **reproduzir em código**. Se o nosso pipeline reproduz, ele se comporta como a literatura |
| **Lin et al., 2024** — 53 crianças com TDAH × 19 controles, EEG **sem fio**, CPT visual e CATA auditivo ([DOI](https://doi.org/10.1109/TNSRE.2024.3360137)) | Mediu coerência entre eletrodos; as diferenças apareceram mais na tarefa **auditiva** (CATA) do que na visual (CPT), sobretudo em alfa | A ideia de **tarefa auditiva**. A coerência precisa de vários canais e não serve para o BrainLink |
| **Zhang et al., 2024 — preprint medRxiv** — 77 crianças, 64 canais, repouso e oddball visual ([DOI](https://doi.org/10.1101/2024.08.21.24312402)) | Em vez de "tem ou não tem TDAH", usou o **desempenho num CPT** como resultado. EEG de repouso explicou pouco (R² ajustado ≈ 0,10); somando oddball e escala dos pais chegou a ≈ 0,39 em 41 crianças | O **desenho do estudo**: correlacionar o EEG com uma medida objetiva de desempenho é possível sem diagnóstico clínico |

(Lin 2024 e Lansbergen 2011: resumo lido no PubMed. Zhang 2024: texto
integral lido, com o PDF enviado pela equipe.)

### Explicação simples dos três

- **Lansbergen** é como descobrir que uma balança "acusava" pessoas mais
  pesadas, quando na verdade elas só eram mais altas. O "theta alto" de parte
  das crianças era, na verdade, **alfa lento**: o pico alfa delas estava em 8
  Hz em vez de 10 Hz e caía dentro da faixa fixa de theta (4–8 Hz).
- **Lin** mostra que a **tarefa** muda o que se enxerga. Ouvir estímulos
  revelou mais diferença do que ver estímulos.
- **Zhang** mostra um jeito honesto de fazer pesquisa sem médico na equipe:
  em vez de prever diagnóstico, prever **desempenho de atenção medido**.

### O que não copiar deles

| Problema | Onde | Por que importa para nós |
| --- | --- | --- |
| Muitas correlações sem correção (64 canais × 4 bandas × 2 estados) e regressão **stepwise** | Zhang | Com amostra pequena, isso acha padrões que não se repetem. Nós vamos fixar poucas medidas **antes** e usar validação cruzada |
| Melhores resultados em eletrodos **parietais e occipitais** | Zhang | O BrainLink fica na testa. Esses números não valem para nós |
| Crianças | Os três | O app é para adultos (18+); idade muda IAF e expoente |
| Preprint sem revisão por pares | Zhang | O próprio medRxiv avisa para não guiar prática clínica |
| Coerência entre canais | Lin | Impossível com um canal |

---

## 2. A ideia central: validar em quatro degraus

**Explicação simples.** Para confiar num termômetro novo, primeiro você testa
se o visor mostra o número que o circuito mede (software). Depois coloca o
termômetro em água a 0 °C e a 100 °C, temperaturas que você **sabe** quais são
(manipulação conhecida). Só depois compara com outros termômetros e, por
último, vê se ele ajuda o médico. O app precisa da mesma escada.

```text
Degrau 1  Software      O Dart calcula igual a uma referência independente?
Degrau 2  Aquisição     Os dados chegam completos, na taxa certa, com horário certo?
Degrau 3  Medida        O app detecta efeitos que SABEMOS que existem?
Degrau 4  Utilidade     A medida acompanha desempenho de atenção, além do ASRS?
```

Os degraus 1 a 3 **não exigem pacientes nem diagnóstico** e cabem num projeto de
alunos de Ciência da Computação. O degrau 4 exige protocolo aprovado pelo CEP.

---

## 3. As mudanças tecnológicas que tornam isso possível

São cinco, em ordem. Cada uma resolve um bloqueio concreto que existe hoje.

### Mudança 1 — Exportar o EEG bruto da sessão

**Bloqueio atual:** o app exporta só HTML e TXT com os resultados. Sem o sinal
bruto, ninguém fora do celular consegue conferir as contas. **Toda** validação
depende disso.

**O que fazer:** um botão "Exportar dados brutos (pesquisa)" que grava um CSV,
uma linha por lote:

```text
phase,seq,arrival_ms,poor_signal,samples
olhos_abertos,0,10234.5,0,12;-8;33;...   (512 valores)
```

Os campos já existem no `RawBatch` do Dart; é só serializar. Sem nome, sem
identificação — LGPD continua atendida, e o arquivo só é criado quando a pessoa
toca no botão, como hoje.

### Mudança 2 — Pipeline de referência em Python (já feito)

O arquivo `tools/validacao/pipeline_referencia.py` foi escrito nesta sessão e
**roda**. Ele é o "gabarito": implementa as contas com SciPy, de forma
independente do Dart.

Resultado da execução (arquivo `saida_demo.txt`):

```text
[ok] PSD calibrado: seno 20 µV -> 200.0 µV² (esperado 200)
[ok] IAF: verdadeira 8.50 Hz -> estimada 8.50 Hz
[ok] IAF: verdadeira 10.00 Hz -> estimada 10.00 Hz
[ok] IAF: verdadeira 11.50 Hz -> estimada 11.50 Hz
[ok] Sem pico alfa -> 'pico alfa não identificável'
[ok] Relógio: taxa real 511.3 Hz -> estimada 511.30 Hz
     erro de horário (p95): chegada do lote 64.8 ms -> relógio reconstruído 0.27 ms
```

Com uma sessão exportada (Mudança 1):

```bash
python tools/validacao/pipeline_referencia.py --sessao minha_sessao.csv
```

Saída de teste, com um arquivo sintético no formato proposto:

```text
[olhos_abertos]  1.0 min | lotes faltando: 0 | taxa reconstruída 511.7 Hz | IAF: 10.0 | piscadas/min: 14.0
[olhos_fechados] 1.0 min | lotes faltando: 0 | taxa reconstruída 511.5 Hz | IAF: 10.0 | piscadas/min: 0.0
Reatividade alfa (fechados vs abertos): +11.4 dB
```

**Como vira validação:** o mesmo CSV passa pelo Dart (num teste `flutter
test` que lê o arquivo) e pelo Python. Os números precisam bater dentro de uma
tolerância fixada antes (ex.: bandas com diferença < 1%). Isso se chama
**teste diferencial** — duas implementações independentes conferindo uma à
outra. É a forma mais forte de testar código numérico sem ter o "valor
verdadeiro".

### Mudança 3 — Relógio reconstruído

**Bloqueio atual:** o vault diz que não dá para analisar resposta a estímulos
(ERP) porque o Bluetooth entrega os lotes em rajadas, com atraso variável.

**A ideia de computação:** o número da amostra é um relógio muito melhor do que
o horário de chegada do lote. A amostra 51.200 aconteceu exatamente 100
segundos depois da amostra 0, se a taxa for 512 Hz — chegue o lote quando
chegar. Basta ajustar uma reta:

```text
horário_de_chegada ≈ atraso + número_da_amostra / taxa_real
```

Com regressão robusta (Theil-Sen, que ignora as rajadas), a reta devolve **a
taxa real do conversor** e um horário para **cada amostra**. Na simulação, o
erro de horário caiu de **64,8 ms** (horário de chegada) para **0,27 ms**
(relógio reconstruído).

Isso resolve duas lacunas do vault de uma vez:

- **"Validação do CODE_RAW no hardware"**: a taxa real sai da reta, sem
  precisar de equipamento.
- **"Caracterização do jitter de timestamp"**: o resíduo da reta é o jitter.

Falta uma coisa que só o hardware responde: o **atraso fixo** entre o
conversor e o celular. Ele é igual para todos os estímulos, então não atrapalha
análises por bloco; para ERP, precisa ser medido uma vez (ver degrau 3).

### Mudança 4 — Bandas pela IAF **e** sem o fundo 1/f

Esta é a mudança que vem direto de Lansbergen 2011, e a simulação trouxe uma
surpresa importante.

O programa cria dois grupos simulados com **o mesmo theta e o mesmo fundo**;
só muda o pico alfa (10 Hz × 8,5 Hz). A resposta correta é "não há diferença"
(d ≈ 0):

```text
ln TBR, bandas fixas            : d = +0.46, p = 0.047   ← falso positivo (o efeito Lansbergen)
ln TBR, bandas pela IAF         : d = +2.06, p = 1.6e-13 ← PIOR
D_TBR, bandas fixas (sem fundo) : d = +0.49, p = 0.034   ← ainda errado
D_TBR, bandas IAF (sem fundo)   : d = +0.37, p = 0.11    ← mais perto do correto
```

**Explicação simples.** Ajustar as bandas ao pico alfa, sozinho, **piorou**:
quem tem alfa lento ganha uma faixa de theta deslocada para frequências mais
baixas, onde o fundo 1/f é naturalmente mais forte. É trocar um erro por outro
maior. Só a **combinação** — bandas pela IAF **mais** remoção do fundo
aperiódico — chegou perto do valor verdadeiro, e ainda sobra um resíduo
(d = 0,37, não significativo com 40 por grupo, mas não é zero).

Lição de engenharia: **toda correção nova precisa passar pelo teste com
resposta conhecida antes de entrar no app.** Isso vale como resultado do
projeto, porque une Lansbergen 2011 e Donoghue 2020 numa demonstração
reproduzível.

O app já tem o que precisa: a fase de olhos fechados dá a IAF. A ordem de
implementação no Dart seria IAF → fundo 1/f (regressão censurada, já
recomendada no documento de hoje) → bandas individualizadas → D_TBR, cada
passo com teste diferencial contra o Python.

### Mudança 5 — Tarefa auditiva, inspirada em Lin 2024

**Por que auditiva:** no BrainLink, o maior inimigo é o olho. Uma tarefa visual
faz a pessoa mover os olhos e piscar perto do estímulo — exatamente o artefato
que contamina Fp1. Uma tarefa **auditiva** pode ser feita **olhando para um
ponto fixo, ou até de olhos fechados**. Lin 2024 ainda encontrou mais diferença
na tarefa auditiva do que na visual.

**Desenho proposto** (adaptando o oddball de Zhang para áudio):

```text
Tom grave (padrão) 80%  ·  Tom agudo (alvo) 20%
Toque na tela só no alvo
Tom de 100 ms, intervalo aleatório de 800 a 1200 ms
3 blocos de 100 tons, 30 s de pausa entre blocos
Olhos fixos num ponto (ou fechados)
```

Registra-se cada toque com horário (relógio monotônico) e cada tom com o
horário de envio ao áudio. Medidas: acertos, omissões, comissões, tempo de
reação individual (para μ, σ e τ), piscadas e potência por bloco. Análise por
**bloco** de imediato; análise **por estímulo** só depois que o degrau 3 medir
o atraso do áudio do celular.

---

## 4. Os degraus em detalhe

### Degrau 1 — Software (sem pessoas)

| Teste | Critério | Estado |
| --- | --- | --- |
| Senoide conhecida → potência em µV² | Erro < 5% | **Passa no Python**; falta no Dart |
| IAF em sinal sintético 8,5 / 10 / 11,5 Hz | Erro ≤ 0,5 Hz | **Passa no Python** |
| Sinal sem alfa → "não estimável" | Nunca inventar pico | **Passa no Python** (0 falsos em 100) |
| Dart × Python no mesmo CSV | Diferença < 1% nas bandas | Depende da Mudança 1 |
| Efeito Lansbergen simulado | Variante escolhida com d ≈ 0 | **Rodado**; resultado acima |

### Degrau 2 — Aquisição (o próprio aluno, sem coleta com terceiros)

| Teste | Como | Critério |
| --- | --- | --- |
| Taxa real | Reta do relógio em 5 min de gravação | Registrar o valor; desvio do nominal documentado |
| Perda de dados | Lotes faltando por sequência | ≥ 99% dos lotes (já está no `PLANO-DE-MUDANCA`) |
| Conferência com o SDK | Comparar nosso CSV com `startRecordRawData()` | Amostras idênticas |
| Jitter | Resíduo da reta | Registrar p50, p95, máximo |

### Degrau 3 — Medida: efeitos que sabemos que existem

**Explicação simples.** É a água a 0 °C e a 100 °C do termômetro. Não depende
de diagnóstico; depende de a pessoa fazer o que foi pedido.

| Manipulação | O que se espera | Medida do app |
| --- | --- | --- |
| Fechar os olhos | Alfa sobe (efeito Berger) | Reatividade alfa em dB |
| Piscar ao comando, a cada 3 s | Uma piscada por comando | Sensibilidade e falsos positivos do detector |
| Cerrar a mandíbula 5 s | Potência alta em beta/gama | Taxa de rejeição correta |
| Repetir a sessão no mesmo dia e em outro dia | Valores parecidos | Confiabilidade (ICC) de alfa, IAF, expoente, piscadas/min |
| Piscar no bipe (calibração de atraso) | Piscada ~200–400 ms depois do som | Estimativa grosseira do atraso som → EEG |

A literatura dá a régua para a confiabilidade: em EEG de laboratório, alfa
posterior teve ICC 0,84 e IAF 0,73 em cinco anos (Park 2026, ver nota PubMed).
Se o BrainLink ficar muito abaixo disso em uma semana, o problema é de
aquisição ou de colocação, não de cérebro.

Testes feitos pela própria equipe em si mesma servem para engenharia. Para
publicar, ou para coletar com outras pessoas, o CEP precisa aprovar antes
(Resolução CNS 466/2012) — o `PLANO-DE-MUDANCA` já lista isso como decisão
pendente.

### Degrau 4 — Utilidade (com CEP aprovado)

Desenho no estilo de Zhang, corrigindo os pontos fracos:

```text
Participantes: adultos 18+
Medidas fixadas ANTES:  ASRS-6 · desempenho na tarefa auditiva (τ, omissões)
                         · 3 a 5 features de EEG (reatividade alfa, IAF,
                           D_TBR, piscadas/min, potência por bloco)
Pergunta principal:     o EEG acrescenta algo ao ASRS para prever o
                        desempenho na tarefa?
Análise:                M0 = desempenho ~ ASRS
                        M1 = desempenho ~ ASRS + EEG
                        comparação por validação cruzada (não stepwise),
                        resultado publicado mesmo se der zero
```

Isso **não** é um estudo diagnóstico. Responde a uma pergunta mais modesta e
honesta, que alunos conseguem conduzir: *o sinal do BrainLink carrega alguma
informação sobre desempenho de atenção que a escala sozinha não carrega?*

---

## 5. O que cada mudança entrega para o projeto

| Mudança | Esforço | Destrava | Alegação clínica nova? |
| --- | --- | --- | --- |
| 1. Exportar bruto | Baixo | Todos os degraus | Não |
| 2. Pipeline de referência | **Feito** | Degrau 1 | Não |
| 3. Relógio reconstruído | Baixo (portar para Dart) | Taxa real, jitter, tarefa | Não |
| 4. IAF + fundo 1/f + D_TBR | Médio | Descrição espectral mais correta | Não |
| 5. Tarefa auditiva | Médio | Degraus 3 e 4 | Não |

Nenhuma delas muda o que o app **promete**. Todas mudam o quanto o projeto
consegue **provar**.

---

## Referências

- Lansbergen MM et al. *The increase in theta/beta ratio on resting-state EEG
  in boys with ADHD is mediated by slow alpha peak frequency.* Prog
  Neuropsychopharmacol Biol Psychiatry, 2011;35(1):47–52. PMID 20713113.
  [DOI](https://doi.org/10.1016/j.pnpbp.2010.08.004)
- Lin JW et al. *Temporal Alpha Dissimilarity of ADHD Brain Network in
  Comparison With CPT and CATA.* IEEE Trans Neural Syst Rehabil Eng,
  2024;32:1333–1343. PMID 38289841.
  [DOI](https://doi.org/10.1109/TNSRE.2024.3360137)
- Zhang S, Yu S, Cui X, Li X. *Neural Oscillation Features of ADHD Symptoms in
  Children: EEG Evidence from Resting State and Oddball Task.* medRxiv,
  preprint, 22/08/2024. [DOI](https://doi.org/10.1101/2024.08.21.24312402)
- Demais referências (Park 2026, Kałamała 2026, Donoghue 2020): ver
  `PESQUISA-PUBMED-COMPLEMENTO-2026-10-03.md` e
  `PESQUISA-EEG-TDAH-2026-10-03.md`.

Metadados de Lansbergen 2011 e Lin 2024 obtidos no PubMed.
