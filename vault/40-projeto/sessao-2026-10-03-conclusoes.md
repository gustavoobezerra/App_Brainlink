---
titulo: Sessão de 03/10/2026 — o que debatemos e o que concluímos
tags: [projeto, decisao, resumo, tdah, psicologia]
status: consolidado
atualizado: 2026-10-03
---

# Sessão de 03/10/2026 — conclusões

Resumo do debate do dia sobre a direção do App BrainLink. O detalhamento
científico, com todas as fontes e números, está em
`docs/pesquisa/EMBASAMENTO-E-PROJETO-CONJUNTO-2026-10-03.md`. A decisão formal
está em [[ADR-005-tarefa-auditiva-e-papel-do-aperiodico]].

## 1. A conclusão em uma frase

> A pessoa faz uma tarefa auditiva curta enquanto o app grava as ondas, os
> tempos de resposta e os erros; depois a equipe clínica avalia o TDAH e nós
> comparamos quem tem e quem não tem — e quem tem mais ou menos sintomas.

## 2. O que debatemos e o que ficou decidido

### 2.1 Razão theta/beta
- Já não era usada como marcador (ADR-001). A leitura dos artigos confirmou.
- Nos dados reais do BrainLink Pro, "theta maior que beta" aparece em 97% dos
  adultos saudáveis de olhos fechados. A frase descreve o aparelho, não a pessoa.
- **Decisão:** remover a frase da tela.

### 2.2 Aperiódico
- **Não** funciona como sinal de TDAH: o maior estudo pré-registrado (1.426
  jovens) deu nulo. Também é a medida que menos se repete na mesma pessoa
  (ICC ~0,5 em um mês).
- **Continua sendo usado como "faxineiro":** separa o fundo do espectro dos
  picos, para medir o alfa corretamente.
- Analogia usada: chiado de fundo × nota da flauta.

### 2.3 O que é o alfa e o que significa
- É o ritmo de "marcha lenta" do cérebro: sobe de olhos fechados e relaxado,
  cai quando a pessoa presta atenção.
- **Alfa alto ou baixo sozinho não significa nada** (crânio, contato, idade,
  genética, aparelho). Não existe "alfa normal" para o BrainLink.
- O alfa é uma **régua, não uma resposta**. Quatro usos:
  1. provar que o sensor capta cérebro (subida ao fechar os olhos);
  2. medir se o aparelho é confiável (mesma pessoa em dias diferentes);
  3. ver o estado mudar dentro da sessão (repouso × tarefa);
  4. frequência do pico alfa (IAF), para corrigir as outras medidas.

### 2.4 Detector de piscadas
- A piscada gera um sinal ~10× maior que o cérebro e passava pelo filtro do
  app: 43% dos trechos aceitos tinham piscada.
- O detector: filtra 1–15 Hz → limite adaptado à pessoa → confere a largura
  (40–500 ms) → espera 400 ms para não contar o "eco" → recorta 100 ms antes e
  400 ms depois.
- Validado em dados reais do BrainLink Pro: achou 550 de 600 piscadas (92%).

### 2.5 Saturação
- Quando o sinal passa do máximo que o chip mede, o valor "trava" no topo,
  como um copo transbordando.
- O chip mede de ~−2.048 a +2.047 contagens (±450 µV), mas o app só checava
  acima de 32.760, então a checagem nunca disparava.
- **Decisão:** corrigir o limite para ±2.047.

### 2.6 Duração e tipo de tarefa
- 25 minutos era muito para a apresentação; precisamos de algo de ~5 minutos
  para testar várias pessoas.
- **Olhos fechados resolve o tempo:** quase não há piscada, e 1 minuto de
  olhos fechados já basta (29 de 29 sessões no BrainLink Pro).
- **Tarefa auditiva**, porque o olho fica parado e o sinal da testa sai mais
  limpo.
- O estudo de Lin 2024 (CPT × CATA auditivo em crianças com TDAH) inspirou a
  ideia. Não dá para replicar exatamente: ele usou coerência entre vários
  canais, e o BrainLink tem um só. Só lemos o resumo; falta o texto completo
  para ver a duração e os parâmetros do CATA.

### 2.7 Foco em TDAH
- O projeto é sobre TDAH e o debate deve ser direcionado para isso.
- Abordagem **dimensional** (sintomas como contínuo, pelo ASRS) **e**
  comparação de grupos, com a avaliação clínica feita pela equipe.
- **A avaliação clínica fica com os profissionais da equipe** (doutores em
  Psicologia, psiquiatras, psicólogos, alunos e estagiários supervisionados),
  com aprovação do Comitê de Ética. Eles escolhem as ferramentas.

### 2.8 Bandas individualizadas pela IAF (o "alfa = x")
- O pico alfa varia de pessoa para pessoa (9 Hz em uma, 11 Hz em outra). Com
  faixas fixas, o alfa lento invade o theta e parece "theta alto" (Lansbergen 2011).
- **Decisão:** tratar o pico alfa como incógnita **x**, medida no minuto de
  olhos fechados, e montar as faixas a partir dele:
  theta = [x−6, x−2), alfa = [x−2, x+2), beta = [x+3, 30).
- O x é **medido em toda sessão** e **salvo no perfil** da pessoa, para
  comparar com sessões anteriores. Ele é estável (ICC ~0,85 em até 90 min;
  ~0,66 em 1 mês na simulação), mas cai com sono, cansaço e idade.
- Se não houver pico identificável (~15% na testa, Finley 2022): usar faixas
  fixas e avisar no relatório.
- As faixas pela IAF só funcionam **junto** com a remoção do fundo aperiódico.
  Sozinhas, pioraram o resultado na simulação.
- Código de referência: `estimate_iaf` e `individual_bands` em
  `tools/validacao/pipeline_referencia.py`.

### 2.9 Mesma "nota", regiões diferentes (alfa × mu)
- Alfa (visão, parte de trás) e mu (movimento, faixa central) estão ambos em
  ~10 Hz. Na tarefa de tons, a queda de 10 Hz pode vir da atenção **ou** do
  dedo tocando na tela.
- **Proposta (a decidir):** acrescentar um bloco de controle "toque no ritmo",
  com o mesmo movimento e sem decisão, para separar atenção de movimento.

## 3. O protocolo escolhido (~5 min)

```text
0:00 – 0:20  Calibração: 5 piscadas no bipe
0:20 – 1:20  Repouso de olhos FECHADOS (1 min)
1:20 – 4:20  TAREFA de olhos fechados (3 min)
             toca em TODO tom grave (80%), NÃO toca no agudo (20%)
             um tom a cada ~1,1 s → ~130 tempos de reação, ~30 chances de errar
4:20 – 5:00  Repouso de olhos FECHADOS (40 s)
Depois:      ASRS-6 + contexto (sono, café, remédio) + avaliação clínica
```

A regra foi invertida em relação à primeira ideia ("toca só no raro"). Agora a
pessoa entra no embalo de tocar e precisa **frear** no agudo, o que mede
impulsividade e gera muito mais tempos de reação.

## 4. O que comparar no final

| Medida | Por quê |
| --- | --- |
| **Variação do tempo de reação (τ)** | É o que mais difere no TDAH (d ≈ 0,53). O tempo **médio** quase não difere (d ≈ 0,04) |
| **Erros por impulsividade** (tocou no agudo) | Inibição de resposta |
| **Omissões** (não tocou no grave) | Desatenção |
| **Queda do alfa na tarefa** × repouso | Parte nova e exploratória: o cérebro "engatando" |

Comparações:
- quem tem TDAH × quem não tem;
- mais sintomas × menos sintomas no ASRS (meta: ~85 pessoas).

O resultado esperado é de grupo ("em média, mais variação"), nunca um corte
individual em milissegundos.

## 5. O que não esquecer

- [ ] **Antes de tudo:** fotografar os eletrodos do Lite. O fabricante descreve
  3 eletrodos na testa, sem clipe; o README manda usar clipe na orelha.
- [ ] Testar na equipe se o alfa sobe ao fechar os olhos e se cai na tarefa.
  Com referência na testa, a simulação mostrou que isso pode sumir.
- [ ] Separar na análise quem toma remédio para TDAH (não pedir para parar).
- [ ] Gravar tons, toques e EEG no mesmo relógio; medir o atraso do áudio e do
  toque no celular usado.
- [ ] Conseguir o PDF completo de Lin 2024 (IEEE TNSRE,
  doi 10.1109/TNSRE.2024.3360137) para alinhar os parâmetros do CATA.
- [ ] Demonstração na apresentação: não guardar dados identificados sem o
  protocolo aprovado.

## 6. Checklist de mudanças no app

- [ ] Detector de piscadas + mostrar o motivo de cada trecho descartado
- [ ] Saturação em ±2.047
- [ ] poorSignal = 0 como padrão na análise
- [ ] Parar de mostrar delta (o chip corta abaixo de ~3 Hz)
- [ ] Remover "theta maior que beta" da tela
- [ ] Exportar EEG bruto em CSV
- [ ] Separar fundo e picos (aperiódico só como limpeza)
- [ ] Perfil da pessoa com a IAF (pico alfa) medida em cada sessão
- [ ] Bandas individualizadas a partir da IAF; faixas fixas + aviso quando não houver pico
- [ ] Medidas descritivas: potência alfa, IAF, queda do alfa, piscadas/min
- [ ] "Não estimável" quando faltar sinal limpo
- [ ] Implementar a tarefa auditiva de 5 min

## 7. Onde está cada coisa

| O quê | Onde |
| --- | --- |
| Embasamento completo | `docs/pesquisa/EMBASAMENTO-E-PROJETO-CONJUNTO-2026-10-03.md` |
| Notas dos especialistas | `docs/pesquisa/notas-especialistas-2026-10-03/` |
| Complemento PubMed e plano de validação | `docs/pesquisa/PESQUISA-PUBMED-COMPLEMENTO-2026-10-03.md`, `docs/pesquisa/PLANO-VALIDACAO-2026-10-03.md` |
| Código, figuras e resultados | `tools/validacao/` |

## Relacionadas

[[ADR-001-nao-usar-tbr-isolado]] · [[ADR-005-tarefa-auditiva-e-papel-do-aperiodico]] ·
[[PLANO-DE-MUDANCA]] · [[artefatos-canal-unico]] · [[brainlink-lite]] ·
[[testes-cpt]] · [[escalas-validadas]]
