---
titulo: Faixa etária — crianças ou adultos?
tags: [ciencia/eeg, produto, decisao, evidencia/forte]
status: consolidado
atualizado: 2026-08-17
---

# Faixa etária — crianças ou adultos?

> [!important] A decisão de escopo mais consequente do projeto
> Ela determina a validade do método, o instrumento de rastreio, o regime de
> consentimento e o risco ético — tudo de uma vez.

## A resposta curta

**Adultos.** E a razão principal não é regulatória nem ética — é **metodológica**.

## O problema: em crianças, a régua se move

A abordagem defensável deste projeto ([[ADR-004-linguagem-nao-diagnostica]])
compara a pessoa **com ela mesma ao longo do tempo**, porque não existe norma
populacional para as features em Fp1 de headset de consumo.

Essa estratégia pressupõe que, **na ausência de mudança de estado, a feature fica
parada**. Em adultos, fica. Em crianças, não.

### A IAF é um alvo em movimento

A frequência alfa individual é um marcador de maturação neural, e ela sobe
sistematicamente durante a infância:

| Idade | Pico alfa aproximado |
| --- | --- |
| 6 meses | 6,1 Hz |
| 5 anos | 8,4 Hz |
| 13 anos | 9,7 Hz |
| Assíntota adulta | ~10,1 Hz |

Os 10 Hz maduros são comumente atingidos por volta dos 10 anos, mas a faixa
normal de chegada se estende de **10 a 15 anos**.

Ou seja: numa criança de 8 anos, a IAF pode subir de forma perceptível ao longo
de poucos meses **por puro desenvolvimento**. Um app que mostrasse "seu alfa
mudou" estaria medindo crescimento, não estado atencional. E como as bandas
seriam relativas ao IAF, **toda a métrica derivada se desloca junto**.

### O expoente aperiódico é pior ainda: não é monotônico

O expoente também muda com a idade, e de forma que impede extrapolação simples:

- da primeira à média infância, o expoente **aumenta** linearmente;
- na infância tardia, passa a **diminuir**;
- há efeitos quadráticos de idade tanto no expoente quanto no offset;
- adultos apresentam expoente mais achatado que crianças.

Uma feature cuja derivada em relação à idade **troca de sinal** no meio da
infância não admite correção etária ingênua. Precisaria de normas
estratificadas por idade, com granularidade fina — que não existem para este
hardware.

> Há um estudo de 2024 dedicado exatamente a isso — *EEG aperiodic dynamics from
> early through late childhood: Associations with ADHD, cognition, and
> development* — que não consegui ler diretamente (paywall). Registro como
> leitura obrigatória antes de qualquer tentativa com público infantil. Ver
> [[bibliografia|ref-31]].

### A consequência prática

```text
Adulto:   feature medida = estado + ruído
          → variação = informação

Criança:  feature medida = estado + desenvolvimento + ruído
          → variação = informação + crescimento, indistinguíveis
```

Sem norma etária fina, não há como separar os dois termos. O acompanhamento
longitudinal — que é o núcleo de [[A1-diario-de-atencao]] — perde o sentido.

## O argumento a favor de adultos

### A evidência existe e é específica

Kiiski et al. (2020), com 38 adultos com TDAH, 45 parentes de primeiro grau e 51
controles, usando classificação por aprendizado de máquina:

| Achado | Valor |
| --- | --- |
| Potência espectral (olhos abertos) discriminou TDAH de controles | **AUC 0,71–0,77** |
| **TBR** classificou o status de TDAH | **Não** |

Os autores levantam explicitamente a hipótese de que o TBR seja característica do
TDAH **infantil**, não adulto.

Isto é duplamente útil. Confirma que [[razao-theta-beta]] não serve em adultos —
e mostra que **outras features espectrais servem**, com AUC modesta mas acima do
acaso.

**A ressalva honesta:** os melhores preditores foram em regiões
**centro-parietais**, que o BrainLink não alcança. Só "beta baixo frontal" está
ao alcance de Fp1. Isso não invalida a direção, mas rebaixa a expectativa — e é
exatamente o tipo de coisa que [[A4-validacao-offline-dataset]] existe para
quantificar.

### O instrumento de rastreio é melhor

| | Crianças | Adultos |
| --- | --- | --- |
| Escala | SNAP-IV | **ASRS v1.1 6Q** |
| Respondente | Pais e/ou professores | **O próprio** |
| Validada em PT-BR | Sim | Sim |
| Licença livre | Sim | Sim |

A ASRS é autoaplicada. Isso elimina a dependência de um terceiro observador e
simplifica radicalmente o fluxo do app. Ver [[escalas-validadas]].

### O consentimento é direto

Adulto consente por si. Com menores, o art. 14 da LGPD exige consentimento
**específico e destacado** de um dos pais ou responsável, **esforços razoáveis de
verificação** de que quem consentiu é de fato o responsável, e observância do
**melhor interesse** do menor. Ver [[lgpd-dados-sensiveis]].

Verificação de responsável é um problema não resolvido em produto, e resolvê-lo
mal é pior que não tentar.

### O risco ético é menor

Um falso sinal em um adulto que decidiu se auto-observar é um incômodo. Um falso
sinal sobre uma criança pode gerar rótulo escolar, ansiedade familiar e —
principalmente — **adiamento de avaliação profissional**. É o dano nomeado pelo
[[practice-advisory-aan]].

## A ironia que vale registrar

Toda a tradição do TBR é infantil. O [[fda-neba-system]] cobre 6 a 17 anos. O
[[datasets-publicos|dataset de Nasrabadi]] é de 7 a 12 anos. É em crianças que o
marcador teve alguma tração histórica.

E é justamente em crianças que a abordagem intra-sujeito — a única honestamente
disponível a este projeto — **não funciona**, porque a referência se move.

Não é contradição, é consequência: o TBR "funcionava" em crianças em parte porque
capturava maturação. Ver a cadeia causal em
[[A2-indice-espectral-multifeature]].

## Uso do dataset infantil, apesar disso

[[A4-validacao-offline-dataset]] usa dados de crianças de 7 a 12 anos, e isso
continua correto — mas com escopo declarado:

- O dataset serve para responder **"quanto sinal sobra em Fp1 isolado a
  128 Hz?"** — pergunta sobre o *método*, não sobre a população.
- Um resultado positivo **não** transfere automaticamente para adultos. As
  features diferem entre as faixas.
- Se o objetivo virar adultos, o ideal é validar também em amostra adulta. Isso
  é lacuna aberta do plano.

## Decisão

**Público-alvo: adultos (18+).**

| Dimensão | Consequência |
| --- | --- |
| Escala | ASRS v1.1 6Q, autoaplicada |
| Linha de base | Válida — features estáveis em escala de meses |
| Consentimento | Do próprio usuário |
| LGPD | Regime de dado sensível, sem art. 14 |
| Ética | Risco substancialmente menor |
| Evidência | Kiiski 2020 dá direção específica para adultos |

**Crianças ficam fora do escopo atual**, e isso deve ser explícito no produto —
não uma omissão. Se um dia entrarem, exigem: normas por idade, protocolo de
consentimento parental verificável, parecer de CEP e, muito provavelmente, um
desenho de estudo próprio.

## Relacionadas

[[frequencia-alfa-individual]] · [[atividade-aperiodica-1f]] ·
[[A2-indice-espectral-multifeature]] · [[escalas-validadas]] ·
[[lgpd-dados-sensiveis]] · [[A1-diario-de-atencao]] · [[fda-neba-system]]
