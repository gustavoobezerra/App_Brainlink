# Projeto BrainLink

Aplicativo Android de uma única tela para realizar uma coleta guiada com o
BrainLink Lite. A pessoa escolhe **Ver demonstração** ou **Conectar BrainLink**,
lê as instruções, acompanha o teste e recebe um resultado simples em formato de
velocímetro. Depois, adultos podem responder ao rastreio ASRS v1.1 de seis
perguntas, sem misturá-lo aos dados do aparelho.

> A nota de 0 a 100 representa somente a qualidade da coleta: contato do sensor
> e continuidade dos dados. Ela não avalia saúde, TDAH ou capacidade da pessoa.

## Fluxo do aplicativo

```text
Demonstração ou BrainLink
          ↓
Instruções de uso
          ↓
Olhos abertos → olhos fechados
          ↓
Velocímetro + dados do aparelho
          ↓
ASRS v1.1 6Q (adultos 18+)
          ↓
Resultados separados → exportar ou repetir
```

- **Demonstração:** duas etapas de 8 segundos, com dados simulados claramente
  identificados.
- **Hardware:** 1 minuto com olhos abertos e 1 minuto com olhos fechados.
- A mudança de etapa e o encerramento usam som e vibração.
- O resultado mostra `Coleta boa`, `Coleta aceitável` ou `Coleta ruim`.
- Os índices de atenção e relaxamento aparecem como saídas proprietárias do
  fabricante, sem classificação da pessoa.
- Em coleta ruim ou sem dados, esses índices ficam ocultos e o app orienta a
  reposicionar o sensor.
- O ASRS gera uma segunda pontuação, de 0 a 24, calculada somente a partir das
  seis respostas; o ponto de corte de rastreio é 14.
- O ASRS não confirma nem exclui TDAH e é apresentado em um cartão separado da
  qualidade do EEG.
- Os resultados podem ser exportados em HTML e TXT e compartilhados pelo
  Android.

## Usar com o BrainLink

1. Carregue e ligue o BrainLink.
2. No Android, abra **Configurações → Bluetooth** e pareie o dispositivo. Em
   aparelhos antigos, o código pode ser `0000`.
3. Coloque o sensor metálico na testa, cerca de 1 a 2 cm acima da sobrancelha,
   sem cabelo entre sensor e pele. Ajuste o clipe para contato direto com o
   lóbulo da orelha.
4. Abra o app, toque em **Conectar BrainLink**, permita o acesso ao Bluetooth e
   escolha o dispositivo.
5. Sente-se confortavelmente. Evite falar, tensionar a testa ou a mandíbula e
   movimentar a cabeça.
6. Inicie: fique 1 minuto com os olhos abertos olhando para um ponto fixo. Ao
   aviso sonoro/tátil, feche os olhos por mais 1 minuto, sem apertá-los.

Se o velocímetro indicar coleta ruim, limpe e seque os pontos de contato,
reposicione o sensor e o clipe e repita. Piscadas frequentes, fala, movimento,
cabelo, suor ou cosméticos entre metal e pele podem degradar o sinal.

## Instalar o APK no celular

O arquivo entregue para instalação é `ProjetoBrainLink.apk`, na Área de
Trabalho. Envie esse arquivo ao Android, abra-o no celular e autorize a
instalação de apps dessa origem quando o sistema solicitar. Uma versão anterior
pode ser atualizada por cima porque o identificador do aplicativo foi mantido.

## Arquitetura

```text
lib/
├── data/models/       # EEG, Bluetooth e pontuação ASRS
├── native/            # contrato Flutter ↔ Android
├── services/          # exportação dos resultados
└── ui/screens/        # fluxo visual único

android/app/src/main/java/com/brainlink/app/
└── MainActivity.java  # SDK, Bluetooth Clássico e compartilhamento
```

O contrato nativo está em
[`FRONTEND_INTEGRATION.md`](FRONTEND_INTEGRATION.md). A fundamentação e os
limites científicos estão em [`vault/README.md`](vault/README.md).

## Executar e validar

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
dart analyze lib test
flutter test
flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`.

## Privacidade e limites

- não há conta, nuvem ou envio automático;
- arquivos são criados somente quando a pessoa toca em exportar;
- o headset possui um canal frontal sensível a contato, piscadas e movimento;
- os índices do fabricante não possuem interpretação clínica;
- o ASRS v1.1 é um rastreio de sintomas para adultos, não uma conclusão
  clínica, e nunca é combinado ao EEG;
- a integração final deve ser exercitada com o BrainLink Lite físico e o
  Android que serão usados na apresentação.

Texto PT-BR oficial e pontuação atualizada do ASRS:
[instrumento de seis perguntas](https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/6Q_Portuguese%20%28for%20Brazil%29_final.pdf)
e [regra 0–24](https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/ASRS_v1.1_screener%286Q%29_scoring_update.pdf).

O SDK proprietário `libStreamSDK_v1.3.2.jar` deve ser usado e distribuído de
acordo com os termos de seu fabricante.
