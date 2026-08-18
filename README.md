# Projeto BrainLink

Aplicativo Android de uma única tela para realizar uma coleta guiada com o
BrainLink Lite. A pessoa escolhe **Ver demonstração** ou **Conectar BrainLink**,
lê as instruções, acompanha o teste e recebe um indicador visual da qualidade,
com o traçado ao vivo e uma comparação descritiva das bandas entre olhos abertos
e fechados. Depois, adultos podem responder ao rastreio ASRS v1.1 de seis
perguntas. Respostas e resumo do EEG ficam juntos no relatório, com cálculos
separados.

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
Indicador visual + traçado e bandas
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
- Durante a coleta, o app desenha os últimos cinco segundos do EEG bruto. Ao
  final, mostra delta, theta, alfa e beta apenas quando há trechos limpos
  suficientes; contato ruim, perdas, sinal plano e amplitudes compatíveis com
  artefato invalidam os trechos.
- As bandas descrevem somente esta sessão e não classificam TDAH.
- O app informa condicionalmente se theta ficou maior que beta nas duas etapas,
  o padrão histórico mais pesquisado. Esse estado é descritivo: estudos atuais
  não sustentam usá-lo como possibilidade individual de TDAH.
- O ASRS gera uma segunda pontuação, de 0 a 24, calculada somente a partir das
  seis respostas; o ponto de corte de rastreio é 14.
- A partir de 14, o app mostra **Possibilidade aumentada no ASRS**; abaixo de
  14, mostra **Ponto de corte não atingido**. Não calcula percentual de chance.
- O cartão do ASRS exibe **NÃO É DIAGNÓSTICO**. O resultado não confirma nem
  exclui TDAH; seu cálculo permanece separado do EEG.
- Ao concluir o ASRS, um resumo reúne ponto de corte e estado das ondas para
  levar ao médico. A exportação lista cada pergunta, resposta e pontos; a
  possibilidade continua calculada somente pelas respostas.
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
   escolha o dispositivo. O Android também pede localização: ela só serve para
   encontrar aparelhos ainda não pareados. Recusar não impede nada — o BrainLink
   pareado no passo 2 continua aparecendo na lista.
5. Sente-se confortavelmente. Evite falar, tensionar a testa ou a mandíbula e
   movimentar a cabeça.
6. Inicie: fique 1 minuto com os olhos abertos olhando para um ponto fixo. Ao
   aviso sonoro/tátil, feche os olhos por mais 1 minuto, sem apertá-los.

### Se o BrainLink não aparece na lista

1. Confirme que ele está pareado em **Configurações → Bluetooth**. Esse é o
   caminho garantido: o app lista os pareados mesmo quando a busca ativa falha.
2. Ligue a **Localização** do sistema. O Android não devolve aparelhos novos
   com ela desligada, qualquer que seja a permissão concedida ao app.
3. Verifique se o BrainLink não está conectado a outro celular ou aplicativo.

Se o indicador mostrar coleta ruim, limpe e seque os pontos de contato,
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
├── services/          # espectro, controle de artefatos e exportação
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
- as potências relativas delta/theta/alfa/beta não têm corte populacional e
  não permitem concluir TDAH;
- os índices do fabricante não possuem interpretação clínica;
- somente o ASRS v1.1 produz a mensagem de possibilidade de TDAH: ele é um
  rastreio de sintomas para adultos, não uma conclusão clínica, e nunca é
  combinado ao EEG;
- a integração final deve ser exercitada com o BrainLink Lite físico e o
  Android que serão usados na apresentação.

Texto PT-BR oficial e pontuação atualizada do ASRS:
[instrumento de seis perguntas](https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/6Q_Portuguese%20%28for%20Brazil%29_final.pdf)
e [regra 0–24](https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/ASRS_v1.1_screener%286Q%29_scoring_update.pdf).

O SDK proprietário `libStreamSDK_v1.3.2.jar` deve ser usado e distribuído de
acordo com os termos de seu fabricante.
