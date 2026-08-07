# BrainLink EEG Monitor

Aplicativo móvel experimental para aquisição e visualização de indicadores
eletroencefalográficos obtidos com o headset BrainLink Lite. O projeto combina
uma interface Flutter com uma ponte Android em Java para o SDK nativo do
dispositivo.

> **Nota científica:** este software é um protótipo acadêmico. Os dados exibidos
> não devem ser utilizados para diagnóstico, tratamento ou tomada de decisão
> clínica.

## Objetivos

- representar amostras de EEG em uma estrutura de dados tipada;
- acompanhar indicadores de atenção, meditação e qualidade do sinal;
- comparar a potência relativa das bandas delta, theta, alfa, beta e gama;
- fornecer um ambiente simulado para desenvolvimento sem o equipamento físico;
- integrar o Flutter ao SDK Android por meio de um `MethodChannel`.

## Estado atual

A tela principal utiliza dados simulados para demonstrar o fluxo de atualização
e a apresentação das métricas. A ponte nativa recebe comandos de conexão e
converte os callbacks do SDK em eventos Dart, mas a descoberta e a seleção do
dispositivo físico ainda não estão expostas na interface.

| Componente | Situação |
| --- | --- |
| Painel de demonstração | Implementado com dados simulados |
| Modelo de amostra EEG | Implementado |
| Comunicação Flutter–Android | Implementada por `MethodChannel` |
| Processamento pelo SDK BrainLink | Integrado na camada Android |
| Descoberta e seleção do headset | Pendente na interface |
| Validação clínica | Fora do escopo |

## Arquitetura

```text
lib/
├── core/
│   └── logger.dart                 # registro técnico em desenvolvimento
├── data/models/
│   └── eeg_data.dart               # modelo imutável das amostras
├── native/
│   └── brainlink_bridge.dart        # contrato Flutter–Android
├── services/
│   └── mock_data_service.dart       # geração de dados experimentais
├── ui/screens/
│   └── home_screen.dart             # painel de visualização
└── main.dart                        # inicialização e tema

android/app/src/main/java/com/brainlink/app/
└── MainActivity.java                # adaptação do SDK nativo
```

O fluxo previsto para o dispositivo físico é:

```text
BrainLink Lite → SDK Android → MethodChannel → EEGData → interface Flutter
```

## Indicadores representados

| Indicador | Representação no aplicativo |
| --- | --- |
| Atenção | Índice eSense de 0 a 100 |
| Meditação | Índice eSense de 0 a 100 |
| Qualidade do sinal | Escala de 0 a 200; valores menores indicam melhor contato |
| Bandas de frequência | Potências relativas fornecidas pelo SDK |

As associações entre bandas de frequência e estados cognitivos são
contextuais. Sua interpretação exige protocolo experimental, controle de
artefatos e fundamentação bibliográfica adequada.

## Requisitos

- Flutter compatível com Dart `>=3.5.0 <4.0.0`;
- Android SDK configurado para desenvolvimento Flutter;
- dispositivo ou emulador Android para execução;
- headset BrainLink Lite para testes da integração nativa;
- SDK BrainLink `libStreamSDK_v1.3.2.jar`, já referenciado pelo módulo Android.

O uso e a distribuição do SDK proprietário devem respeitar os termos do
fabricante.

## Execução

Na raiz do projeto, instale as dependências:

```bash
flutter pub get
```

Verifique a qualidade estática do código:

```bash
flutter analyze
```

Execute o aplicativo em um dispositivo disponível:

```bash
flutter run
```

Na tela inicial, selecione **Iniciar demonstração** para produzir uma série
simulada. Os valores mudam periodicamente para apoiar testes de interface.

## Integração nativa

O canal `com.brainlink.app/sdk` define o contrato entre Dart e Java. Comandos,
callbacks e campos transmitidos estão documentados em
[`FRONTEND_INTEGRATION.md`](FRONTEND_INTEGRATION.md).

Ao alterar o protocolo, mantenha os nomes e tipos sincronizados entre:

- `lib/data/models/eeg_data.dart`;
- `lib/native/brainlink_bridge.dart`;
- `android/app/src/main/java/com/brainlink/app/MainActivity.java`.

## Limitações e próximos passos

- implementar descoberta BLE e seleção do headset na interface;
- solicitar permissões Bluetooth em tempo de execução;
- validar a aquisição em diferentes versões do Android;
- adicionar testes unitários, de widget e de integração;
- definir persistência, anonimização e exportação de sessões;
- estabelecer um protocolo de tratamento de ruído e artefatos;
- documentar consentimento, privacidade e governança dos dados de pesquisa.
