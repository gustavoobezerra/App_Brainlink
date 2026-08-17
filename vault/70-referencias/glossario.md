---
titulo: Glossário
tags: [referencia]
status: consolidado
atualizado: 2026-08-17
---

# Glossário

## Eletrofisiologia

**EEG** — Eletroencefalografia. Registro da atividade elétrica cerebral por
eletrodos no escalpo.

**Sistema 10-20** — Padrão internacional de posicionamento de eletrodos. Os
números indicam a distância proporcional entre pontos anatômicos de referência.

**Fp1** — Posição frontopolar esquerda, sobre a testa. O único eletrodo do
BrainLink. Ver [[limitacoes-fp1]].

**Cz** — Vértice do crânio. Posição usada pelo [[fda-neba-system]] — e que o
BrainLink não possui.

**Bandas de frequência** — Faixas convencionais do espectro: delta (0,5–4 Hz),
theta (4–8 Hz), alfa (8–12 Hz), beta (12–30 Hz), gama (>30 Hz). As bordas são
convenção, não fronteiras fisiológicas — é o que torna a
[[frequencia-alfa-individual]] importante.

**Efeito Berger** — Aumento da potência alfa ao fechar os olhos. Um dos achados
mais robustos da eletrofisiologia; serve de teste de sanidade do hardware.

**Artefato** — Sinal registrado que não tem origem cerebral: piscada, movimento
ocular, atividade muscular, rede elétrica, mau contato. Ver
[[artefatos-canal-unico]].

**Época** — Janela de tempo em que o sinal é segmentado para análise.

## Análise espectral

**PSD** — *Power Spectral Density*, densidade espectral de potência. Distribuição
da potência do sinal pelas frequências. Em EEG, expressa em µV²/Hz.

**FFT** — *Fast Fourier Transform*. Algoritmo que decompõe um sinal em suas
componentes de frequência.

**Método de Welch** — Estimativa de PSD pela média de espectros de segmentos
sobrepostos. Reduz variância ao custo de resolução.

**Janela de Hann** — Função que suaviza as bordas de um segmento antes da FFT,
reduzindo vazamento espectral.

**TBR** — *Theta/Beta Ratio*, razão theta/beta. Ver [[razao-theta-beta]].

**Componente aperiódico (1/f)** — O decaimento em lei de potência que forma o
"fundo" do espectro. Parametrizado pelo **expoente** (inclinação) e pelo
**offset**. Ver [[atividade-aperiodica-1f]].

**IAF** — *Individual Alpha Frequency*. A frequência exata do pico alfa de uma
pessoa. Ver [[frequencia-alfa-individual]].

**specparam / FOOOF** — Algoritmo que separa os componentes aperiódico e
oscilatório do espectro.

**Dados composicionais** — Conjunto de valores que somam um total fixo (como
potências relativas de banda). São interdependentes: se um sobe, os outros
necessariamente descem. Exigem transformação log-ratio antes de análise
estatística.

**MAD** — *Median Absolute Deviation*. Medida de dispersão robusta a valores
extremos, preferível ao desvio-padrão quando pode haver artefato residual.

## Hardware

**TGAM / TGAT** — O ASIC da NeuroSky que faz amplificação, digitalização e o
cálculo dos índices proprietários. Ver [[chip-tgam-protocolo]].

**eSense** — Nome comercial dos índices `attention` e `meditation`, de algoritmo
fechado. Ver [[indices-esense]].

**poorSignal** — Indicador de qualidade de contato do eletrodo, de 0 a 200.
Valores menores são melhores. Não distingue piscada de mau contato.

**SPP** — *Serial Port Profile*, perfil de Bluetooth Clássico que emula porta
serial. É o transporte usado pelo SDK — não BLE. Ver [[sdk-libstreamsdk]].

**Frequência de Nyquist** — Metade da taxa de amostragem. É a maior frequência
representável sem *aliasing*. A 128 Hz, são 64 Hz.

## Avaliação clínica

**TDAH** — Transtorno de Déficit de Atenção e Hiperatividade.

**DSM-5** — Manual diagnóstico e estatístico de transtornos mentais, 5ª edição.

**SNAP-IV** — Escala de rastreio para crianças e adolescentes, validada em
PT-BR. Ver [[escalas-validadas]].

**ASRS v1.1 6Q** — Rastreador de autorrelato para adultos, derivado da escala
de 18 itens desenvolvida por grupo ligado à OMS. A versão de 6 perguntas em
PT-BR pode ser usada sem permissão formal, desde que texto, opções e algoritmo
não sejam alterados. Ver
[[escalas-validadas]].

**CPT** — *Continuous Performance Test*. Ver [[testes-cpt]].

**Rastreio (screening)** — Procedimento para separar "vale investigar" de
"provavelmente não vale". **Não** é diagnóstico.

**Sensibilidade** — Proporção de casos verdadeiros que o teste identifica.

**Especificidade** — Proporção de não-casos que o teste corretamente descarta.

**VPP** — Valor preditivo positivo. Dado um resultado positivo, a probabilidade
de o caso ser real. **Depende da prevalência** — e é por isso que um teste com
boa sensibilidade e especificidade ainda pode produzir mais falsos positivos que
verdadeiros positivos numa população de baixa prevalência. É o argumento central
do [[practice-advisory-aan]].

**AUC** — Área sob a curva ROC. Mede a capacidade de discriminação de um
classificador. 0,5 equivale a acaso.

**Teste de permutação** — Procedimento que embaralha os rótulos de grupo muitas
vezes para estimar a distribuição do resultado sob a hipótese nula.

**Análise multiverso** — Metodologia que roda todas as especificações analíticas
defensáveis e reporta a distribuição dos resultados, em vez de escolher uma. Ver
[[analise-multiverso-tbr]].

## Regulatório

**SaMD** — *Software as a Medical Device*. Software que é, em si, dispositivo
médico. Ver [[anvisa-rdc-657]].

**Finalidade pretendida** — O que o fabricante declara que o produto faz. É o
critério que determina o enquadramento regulatório — **não** a tecnologia
empregada.

**Notificação** — Procedimento simplificado de regularização junto à ANVISA para
Classes I e II. Não depende de aprovação prévia.

**Registro** — Procedimento completo, exigido para Classes III e IV.

**De novo (FDA)** — Via de classificação para dispositivos novos sem equivalente
prévio no mercado. Foi como o NEBA foi autorizado.

**Dado sensível** — Categoria da LGPD que inclui dado de saúde, com regime de
tratamento mais restrito. Ver [[lgpd-dados-sensiveis]].

**CEP / CONEP** — Sistema brasileiro de comitês de ética em pesquisa com seres
humanos. Relevante a partir do primeiro dado coletado de terceiros.
