# Brief de design — Telas dos testes auditivo e visual (App BrainLink)

## Contexto

Aplicativo Android (Flutter) de pesquisa, usado com um headset de EEG de um
canal na testa (BrainLink). A pessoa faz um teste curto de atenção
(~5 minutos) enquanto o app grava as ondas cerebrais, os tempos de resposta e
os erros. O estudo é sobre TDAH em adultos, feito com equipe de Psicologia e
aprovação de Comitê de Ética. **O app não dá diagnóstico nem nota de atenção.**

Há duas versões do teste com o mesmo fluxo:

- **Auditivo (principal):** de olhos fechados, a pessoa ouve tons.
- **Visual (alternativa):** de olhos abertos, a pessoa vê figuras no centro da tela.

## Princípios de design (valem para tudo)

1. **O sinal cerebral é frágil.** Piscar, mexer os olhos, franzir a testa, falar
   e mexer a cabeça sujam o sinal. O design deve **acalmar**: nada piscando,
   nada se movendo pela tela, nenhuma animação chamativa durante a coleta.
2. **Olhos fechados = a tela não importa.** Nas fases de olhos fechados, toda
   instrução e toda troca de fase acontece por **som e vibração**. A tela fica
   escura e só mostra o necessário para o pesquisador.
3. **Tocar em qualquer lugar.** Nas tarefas, a tela inteira é o botão. A pessoa
   não precisa mirar.
4. **Sem feedback de acerto ou erro durante o teste** (só no treino). Nada de
   pontos, estrelas, ranking ou "nota de atenção".
5. **Linguagem neutra e não diagnóstica.** Proibido: "TDAH detectado", "atenção
   baixa", "normal/anormal", "nota", "score", porcentagem de chance.
6. **Dois públicos:** o participante (simples, calmo) e o pesquisador (dados de
   qualidade do sinal, discretos, num cantinho ou numa tela própria).
7. **Acessível:** textos grandes (mínimo 18 sp nas instruções), alto contraste,
   tema claro e escuro, botões com no mínimo 56 dp de altura.
8. **Proteção contra saída acidental:** tela sempre acesa durante o teste;
   o botão "voltar" pede confirmação; o encerramento antecipado exige
   **toque longo** (2 s) num botão discreto.

## Fluxo de telas

```text
1. Início do teste (escolha auditivo / visual + código do participante)
2. Colocar o sensor e checar contato
3. Instruções gerais
4. Calibração de piscadas (20 s)
5. Repouso de olhos fechados (1 min)
6. Instruções da tarefa + treino (≈30 s)
7. TAREFA (3 min) — auditiva OU visual
8. Repouso final de olhos fechados (40 s)
9. Questionários (ASRS-6 + contexto)
10. Fim (modo pesquisa) / Resultados descritivos (modo demonstração)
```

Uma **barra de progresso discreta** no topo mostra as etapas (não o tempo
exato, para não gerar ansiedade).

---

### Tela 1 — Início do teste

- Título: "Teste de atenção com sons" / "Teste de atenção com imagens".
- Seletor: **Auditivo** (recomendado) · **Visual**.
- Campo: **código do participante** (ex.: P017). Nada de nome.
- Interruptor: **Modo demonstração** (para a apresentação; não salva dados
  identificados).
- Botão principal: "Começar".
- Texto pequeno: "Duração: cerca de 5 minutos."

### Tela 2 — Colocar o sensor e checar contato

- Ilustração simples de onde fica o sensor na testa (sem cabelo entre sensor e
  pele) e, se houver, o clipe de orelha.
- **Indicador de contato** grande, em três estados:
  - "Procurando sinal…" (neutro)
  - "Ajuste o sensor" (âmbar), com dica curta: "Encoste bem na testa, sem
    cabelo no meio."
  - "Contato bom" (verde), que precisa ficar estável por **10 segundos** para
    liberar o botão.
- Para o pesquisador: um traçado pequeno e calmo do sinal ao vivo (linha fina,
  sem cores fortes).
- Botão: "Continuar" (desabilitado até o contato ficar estável).

### Tela 3 — Instruções gerais

Texto curto, em tópicos:
- "Sente-se confortável e apoie os braços."
- "Durante o teste, evite falar, mexer a cabeça ou apertar os dentes."
- "Você vai ouvir **um bipe** quando for para **fechar** os olhos e **dois
  bipes** quando for para **abrir**. O celular também vai vibrar."
- Botão: "Entendi".

### Tela 4 — Calibração de piscadas (20 s)

- Instrução: "Pisque **uma vez** cada vez que ouvir o bipe."
- Um círculo no centro que **cresce suavemente** a cada bipe (sem flash).
- Contador discreto: "3 de 5".
- Ao final, para o pesquisador: "Piscadas detectadas: 5 de 5" (ou "4 de 5 —
  repetir?"), com opção de repetir.

### Tela 5 — Repouso de olhos fechados (1 min)

- Antes de começar: "Agora feche os olhos e fique relaxado até ouvir dois
  bipes." Botão "Começar repouso".
- Durante: **tela quase preta**, com um único ponto suave no centro.
  - Canto inferior, bem discreto (para o pesquisador): tempo restante e um
    pontinho de qualidade do sinal (verde/âmbar/vermelho).
- Fim: dois bipes + vibração. Texto aparece: "Pode abrir os olhos."

### Tela 6 — Instruções da tarefa + treino

**Versão auditiva:**
- Texto: "Você vai ouvir dois sons: um **grave** e um **agudo**."
- Dois botões para ouvir exemplos: "▶ Som grave" · "▶ Som agudo".
- Regra em destaque, com ícones:
  - **Som grave → toque na tela**
  - **Som agudo → NÃO toque**
- "Responda o mais rápido que puder, sem errar. Você vai fazer de **olhos
  fechados**, segurando o celular."
- **Treino (10 sons):** aqui sim há feedback suave após cada som
  ("✓ Certo" / "Era para não tocar"), por texto e vibração curta diferente.
- Botão: "Começar o teste".

**Versão visual:**
- Texto: "Vão aparecer figuras no centro da tela, uma de cada vez."
- Mostrar as duas figuras: **figura comum** (ex.: barco) e **figura rara**
  (ex.: barco pirata). Formas grandes, simples, alto contraste, **mesmo tamanho
  e mesma posição**.
- Regra: **figura comum → toque** · **figura rara → NÃO toque**.
- "Olhe sempre para o centro da tela."
- Treino (10 figuras) com o mesmo feedback suave.

### Tela 7A — TAREFA AUDITIVA (3 min)

- Começa com um bipe: "Feche os olhos." (um bipe + vibração)
- **Tela preta.** A tela inteira é a área de toque.
- **Nenhum feedback** de acerto/erro. O toque pode gerar uma **micro-vibração
  idêntica** para qualquer toque (só para a pessoa saber que tocou), ou nenhuma
  — decidir no piloto.
- Para o pesquisador, num canto com brilho mínimo: tempo restante, qualidade
  do sinal, número de toques.
- Fim: dois bipes + vibração.

**Parâmetros (para referência do design; o áudio é gerado pelo app):**
- Tom grave ~600 Hz, tom agudo ~1200 Hz, 100 ms cada, com rampa suave de 10 ms.
- 80% graves e 20% agudos, em ordem sorteada (nunca dois agudos seguidos).
- Um tom a cada 0,9–1,3 s, sorteado (média ~1,1 s) → ~160 tons em 3 min.

### Tela 7B — TAREFA VISUAL (3 min)

- Fundo neutro e escuro, **cruz de fixação** pequena no centro entre as figuras.
- Cada figura aparece **no centro**, por **250 ms**, e some. Próxima figura em
  0,9–1,3 s.
- Figuras: mesma forma geral, tamanho e brilho; diferença clara só no
  detalhe (ex.: vela branca × bandeira pirata). Nada se move, nada cresce.
- 80% comuns e 20% raras, ordem sorteada.
- Tela inteira é área de toque. Sem feedback de acerto/erro.
- Para o pesquisador: mesmo canto discreto da versão auditiva.

### Tela 7C — (opcional, a decidir) Bloco de controle "toque no ritmo" (1 min)

- Mesmo visual da tarefa, mas **todos os sons/figuras são iguais** e a pessoa
  toca em todos. Serve para separar o efeito do movimento do dedo do efeito da
  atenção. Desenhar como variante da Tela 7, com a instrução: "Agora toque em
  **todos** os sons."

### Tela 8 — Repouso final de olhos fechados (40 s)

- Igual à Tela 5, com o texto: "Último repouso. Feche os olhos até ouvir dois
  bipes."

### Tela 9 — Questionários

- **ASRS-6:** uma pergunta por tela, com 5 opções grandes (Nunca, Raramente,
  Algumas vezes, Frequentemente, Muito frequentemente). Barra "Pergunta 2 de 6".
- **Contexto (uma tela):**
  - "Quantas horas você dormiu na última noite?" (< 5 · 5–7 · > 7)
  - "Tomou café ou energético nas últimas 3 horas?" (Sim · Não)
  - "Toma medicação para atenção? Tomou hoje?" (Não toma · Toma e tomou hoje ·
    Toma e não tomou hoje · Prefiro não dizer)
  - "Usa lente de contato?" (Sim · Não) — afeta piscadas.

### Tela 10A — Fim (modo pesquisa)

- "Obrigado! Sua participação foi registrada."
- "Este teste **não é diagnóstico**. Se quiser conversar sobre atenção, procure
  um profissional." + botão "Ver serviços de atendimento" (folha de
  encaminhamento definida pela equipe).
- Nada de números.

### Tela 10B — Resultados descritivos (modo demonstração)

Cartões simples, sem cores de "bom/ruim" sobre a pessoa:

1. **"O sensor captou seu cérebro"** — o alfa subiu ao fechar os olhos (+4 dB).
2. **"Seu cérebro trocou de estado"** — gráfico de 3 barras: repouso · tarefa ·
   repouso (a barra da tarefa normalmente mais baixa).
3. **"Piscadas"** — "Detectamos 5 de 5 na calibração."
4. **"Sua tarefa"** — acertos, toques no som/figura rara e tempo médio de
   resposta, **sem comparação com outras pessoas**.
5. Rodapé fixo: "Demonstração de pesquisa. Não é diagnóstico."

## Estados e casos de erro (desenhar também)

- **Sensor perdeu contato no meio do teste:** pausa automática, som de alerta
  suave, tela "Reposicione o sensor" e opção de retomar ou recomeçar a fase.
- **Bluetooth desconectou:** tela de reconexão, sem perder o que já foi gravado.
- **Saída antecipada:** confirmação ("Encerrar o teste? Os dados desta sessão
  não serão usados.").
- **Calibração com poucas piscadas detectadas:** sugestão de repetir.
- **Volume do celular baixo** (versão auditiva): aviso antes de começar —
  "Aumente o volume" — com botão de som de teste.

## Elementos de som e vibração (resumo)

| Evento | Som | Vibração |
| --- | --- | --- |
| Fechar os olhos / começar fase | 1 bipe | 1 vibração curta |
| Abrir os olhos / fim da fase | 2 bipes | 2 vibrações curtas |
| Calibração | 1 bipe por piscada | — |
| Perda de contato | alerta suave | 1 vibração longa |

Os bipes de fase devem soar **diferentes** dos tons da tarefa (ex.: timbre de
sino), para não serem confundidos com estímulos.

## O que NÃO fazer

- Animações, partículas, confetes, contagem regressiva grande na tela.
- Cores vermelho/verde para julgar a pessoa (só para o contato do sensor).
- Elementos que façam o olho percorrer a tela durante a tarefa visual.
- Qualquer texto que sugira diagnóstico, nota ou comparação com "o normal".
