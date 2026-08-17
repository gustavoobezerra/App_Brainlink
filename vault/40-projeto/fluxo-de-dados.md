---
titulo: Fluxo de dados atual
tags: [codigo, arquitetura]
status: consolidado
atualizado: 2026-08-17
---

# Fluxo de dados atual

```mermaid
flowchart TD
    A["Demonstração"] --> E["Coleta guiada<br/>abertos → fechados"]
    B["BrainLink Lite"] --> C["SDK Android<br/>filtro 60 Hz"]
    C -->|"eSense + poorSignal ~1 Hz"| D["MethodChannel"]
    C -->|"raw 128 Hz em lotes"| R["EventChannel"]
    D --> E
    E --> F["Pontua contato + continuidade"]
    F --> G["Velocímetro<br/>boa / aceitável / ruim"]
    E --> H["Atenção e relaxamento<br/>saídas do fabricante"]
    G --> I["HTML/TXT sob solicitação"]
    H --> I
```

## Regras

- O hardware usa 60 s com olhos abertos e 60 s com olhos fechados.
- A demonstração usa 8 s em cada fase e sempre se identifica como simulada.
- Som e vibração avisam a troca de fase e o final.
- A pontuação de 0 a 100 combina contato (`poorSignal`) e continuidade de
  leituras; não usa attention, meditation, bandas ou ASRS.
- Sem `poorSignal`, o app mostra ausência de dados em vez de inventar zero.
- eSense aparece de forma descritiva e separado da nota de coleta.
- `CODE_RAW` é transportado em lotes, mas não alimenta o velocímetro atual.
- Não há histórico, conta ou envio automático. A exportação é voluntária.

## Relacionadas

[[auditoria-codigo]] · [[brainlink-lite]] · [[indices-esense]] ·
[[artefatos-canal-unico]] · [[ADR-002-consumir-eeg-bruto]]
