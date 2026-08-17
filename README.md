# Projeto BrainLink

Aplicativo Android simples para adultos (18+) registrarem sessões de atenção,
contexto e o rastreio ASRS v1.1 de seis perguntas. Funciona em modo de
demonstração sem headset e também se conecta ao BrainLink Lite por Bluetooth
Clássico.

> Este é um recurso acadêmico de observação e rastreio. Não diagnostica TDAH,
> não compara a pessoa com uma população e não substitui avaliação profissional.

## O que o aplicativo entrega

- tela inicial com escolha entre demonstração e hardware;
- descoberta, seleção e conexão ao BrainLink Lite;
- sessão com gráfico, qualidade de contato e diário de contexto;
- ASRS v1.1 6Q em português, com pontuação e orientação responsável;
- histórico local de sessões;
- prévia e exportação de relatório autocontido em HTML e TXT;
- compartilhamento do relatório pelo seletor nativo do Android;
- aquisição opcional do EEG bruto a 128 Hz em lotes.

Os índices de atenção e meditação são algoritmos proprietários do
fabricante e aparecem somente de forma descritiva. Sinal ausente ou inadequado
não produz um número aparentemente medido.

## Telas

| Tela | Finalidade |
| --- | --- |
| Início | selecionar demonstração ou conectar o headset |
| Sessão | acompanhar o gráfico e registrar sono, humor, medicação e tarefa |
| ASRS | responder o rastreio e visualizar a pontuação de 0 a 6 |
| Relatório | consultar o histórico, visualizar e exportar os dados |

O ASRS permanece visualmente separado das observações do headset. Uma
pontuação que merece atenção orienta a pessoa a conversar com um profissional
de saúde, sem apresentar conclusão diagnóstica.

## Dados e privacidade

Os dados ficam no diretório privado do aplicativo, sem conta, nuvem ou envio
automático. Cada sessão grava metadados, épocas e eventos em JSON/JSONL; o raw
opcional usa `Int16` little-endian. A exportação e o compartilhamento ocorrem
somente por ação da pessoa.

## Arquitetura

```text
lib/
├── data/models/       # EEG, raw, ASRS, sessão e diário
├── native/            # contrato Flutter ↔ Android
├── services/          # demonstração, persistência e exportação
└── ui/screens/        # interface principal com quatro telas

android/app/src/main/java/com/brainlink/app/
└── MainActivity.java  # SDK, Bluetooth Clássico, raw e compartilhamento
```

O contrato nativo completo está em
[`FRONTEND_INTEGRATION.md`](FRONTEND_INTEGRATION.md). As decisões científicas,
de produto, linguagem e persistência estão em [`vault/README.md`](vault/README.md).

## Executar e validar

Requisitos: Flutter com Dart 3.5 ou superior, Android SDK e Java compatível com
o toolchain do Flutter.

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test
flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`. O modo
**Demonstração** permite percorrer o fluxo completo sem hardware. Para o modo
**Hardware**, pareie o BrainLink nas configurações do Android, conceda as
permissões Bluetooth solicitadas e escolha o dispositivo na tela inicial.

O SDK proprietário `libStreamSDK_v1.3.2.jar` deve ser usado e distribuído de
acordo com os termos de seu fabricante.

## Limites atuais

- não há validação clínica nem referência populacional;
- o headset tem um único canal frontal, sensível a movimento e piscadas;
- análises espectrais experimentais A2–A4 permanecem fora da interface;
- a integração física depende de teste com um BrainLink Lite real.

O projeto inclui testes de modelos, persistência, exportação, linguagem e do
fluxo principal da interface, além de uma rotina de CI para análise, testes e APK.
