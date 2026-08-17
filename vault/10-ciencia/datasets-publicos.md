---
titulo: Datasets públicos de EEG e TDAH
tags: [ciencia/dados, metodologia, abordagem/A4]
status: consolidado
atualizado: 2026-08-13
---

# Datasets públicos de EEG e TDAH

> [!tip] O caminho mais barato para uma resposta honesta
> Permitem testar qualquer índice contra diagnóstico clínico real **sem tocar em
> hardware e sem coletar dado de ninguém**. Base de
> [[A4-validacao-offline-dataset]].

## Nasrabadi et al. — o mais adequado a este projeto

| Atributo | Valor |
| --- | --- |
| Fonte | IEEE DataPort, DOI `10.21227/rzfh-zn36` (também espelhado no Kaggle) |
| Participantes | **61 com TDAH + 60 controles** |
| Idade | 7–12 anos |
| Diagnóstico | Psiquiatra experiente, critérios DSM-IV |
| Canais | 19, padrão 10-20 |
| Taxa de amostragem | **128 Hz** |
| Referência | A1 e A2 (lóbulos das orelhas) |
| Protocolo | Tarefa de atenção visual |
| Publicação | 2020 |

Três coincidências o tornam quase sob medida:

1. **Inclui Fp1** — o mesmo eletrodo do BrainLink. Dá para descartar os outros 18
   canais e simular exatamente a limitação do headset.
2. **128 Hz** — a mesma taxa de EEG bruto do BrainLink Lite. Ver
   [[brainlink-lite]].
3. **Referência em lóbulo de orelha** — o mesmo esquema do clipe do BrainLink.

Ou seja: é possível reproduzir offline, com razoável fidelidade, o que o headset
veria — com diagnóstico clínico como verdade de referência.

## Healthy Brain Network

Amostra de grande porte (N = 1.499 no estudo de referência), usada como base
principal em [[analise-multiverso-tbr]]. Valor sobretudo comparativo: permite
confrontar resultados próprios com os do estudo que refutou o TBR.

## Como usar sem se enganar

Duas armadilhas metodológicas comprometem qualquer resultado:

**1. Escolher o corte depois de ver o resultado.** Separação treino/teste
declarada **antes** de rodar, e o ponto de corte congelado antes da avaliação
final. Caso contrário, você está reportando o melhor de muitas tentativas, não o
desempenho do método.

**2. Reportar acurácia sem incerteza.** AUC sem intervalo de confiança não
informa nada com N = 121. Incluir IC95% e teste de permutação.

## Por que um bom resultado ainda não transfere

Se o índice separar os grupos no dataset, isso é condição **necessária e não
suficiente** para funcionar no BrainLink. As diferenças reais:

| Dimensão | Dataset | BrainLink |
| --- | --- | --- |
| Eletrodo | Gel, clínico | Seco, de consumo |
| Ambiente | Laboratório | Sala de casa |
| População | Crianças 7–12, contexto iraniano | Usuário do app |
| Protocolo | Tarefa de atenção visual padronizada | Livre |
| Preparo | Técnico treinado | O próprio usuário |

## Por que um resultado ruim é igualmente valioso

Se o expoente aperiódico em Fp1 isolado der AUC próxima de 0,5, isso é a resposta
à pergunta central do projeto — obtida sem risco, sem coleta e sem custo. Para um
TCC, um resultado negativo bem conduzido é resultado.

O compromisso de publicar o resultado **qualquer que ele seja** está registrado
em [[A4-validacao-offline-dataset]], antes de o número existir, justamente para
que não haja espaço para reinterpretá-lo depois.

## Relacionadas

[[A4-validacao-offline-dataset]] · [[analise-multiverso-tbr]] ·
[[atividade-aperiodica-1f]] · [[limitacoes-fp1]] · [[brainlink-lite]]
