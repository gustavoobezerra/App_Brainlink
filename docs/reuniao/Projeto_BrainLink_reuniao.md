# Projeto BrainLink

## Documento técnico para reunião e colaboração com a Psicologia

Gustavo Bezerra • 30 de setembro de 2026

## Proposta e contexto acadêmico

O Projeto BrainLink desenvolve um aplicativo Android que integra monitoramento de sinal eletroencefalográfico, rastreio de sintomas de TDAH em adultos e elaboração de um relatório para consulta. O projeto foi aprovado para bolsa no PROBIC. Em conversa com o orientador e com a coordenadora, identificamos que a participação de alunos de Psicologia pode contribuir para o protocolo de pesquisa, a compreensão dos resultados e a avaliação da experiência dos participantes.

O objetivo desta reunião é apresentar o funcionamento do protótipo e discutir uma colaboração interdisciplinar supervisionada. A proposta reúne desenvolvimento de software, processamento digital de sinais e conhecimento sobre avaliação psicológica e comportamento. A participação dos alunos, o número de envolvidos, a carga horária e os responsáveis por cada atividade ainda precisam ser acordados.

O aplicativo mantém a comunicação de “possibilidade aumentada” no rastreio. Essa indicação deriva das respostas ao ASRS, enquanto o EEG oferece uma descrição do sinal registrado durante a sessão. O relatório reúne os dois conjuntos de informações e identifica suas origens. A aprovação para bolsa viabiliza o desenvolvimento acadêmico; a validação do instrumento tecnológico e a definição do protocolo com participantes constituem etapas próprias do projeto.

## Problema e objetivo do projeto

O projeto busca organizar, em uma experiência guiada, informações autorreferidas sobre sintomas e registros fisiológicos obtidos por um dispositivo portátil. A contribuição pretendida é facilitar a coleta, tornar a qualidade do sinal observável e produzir um material organizado que possa apoiar a conversa com um profissional.

O objetivo técnico imediato é obter sessões reprodutíveis, com identificação de falhas de contato, interrupções e artefatos, e apresentar resultados compreensíveis. O objetivo de pesquisa proposto é investigar a viabilidade do fluxo integrado, sua usabilidade e a compreensão do significado dos resultados. A capacidade de identificar TDAH com base em características do EEG permanece uma hipótese de pesquisa e não corresponde a uma capacidade demonstrada pelo aplicativo.

## Experiência de uso

O usuário pode abrir uma demonstração com dados simulados ou conectar o BrainLink Lite por Bluetooth. A demonstração apresenta duas etapas de oito segundos e deve ser identificada como simulação em qualquer apresentação. A sessão com hardware prevê um minuto de olhos abertos e um minuto de olhos fechados, com orientação visual e avisos sonoros e táteis na transição.

Durante a aquisição, o aplicativo mostra o traçado do EEG e acompanha a qualidade do contato. Ao final, apresenta a qualidade da coleta e, quando há trechos aproveitáveis suficientes, a distribuição de potência nas bandas delta, theta, alfa e beta. A versão em desenvolvimento inclui preparação do contato e tratamento de interrupções para evitar que uma sessão incompleta seja apresentada como concluída.

Após essa etapa, adultos podem responder às seis perguntas do ASRS v1.1. O aplicativo exibe a pontuação do rastreio e organiza um relatório com as respostas, os resultados e o resumo do EEG. A exportação atual utiliza HTML e TXT e o compartilhamento do Android. Não há geração nativa de PDF no fluxo descrito.

## Como o rastreio expressa a possibilidade de TDAH

O ASRS v1.1 de seis questões é um instrumento de autorrelato para rastreio de sintomas em adultos. A implementação atual utiliza pontuação total de zero a 24 e ponto de corte de 14, conforme a regra de pontuação adotada no projeto. Ao atingir esse corte, a interface apresenta “Possibilidade aumentada no ASRS”; abaixo dele, apresenta “Ponto de corte não atingido”.

Essa pontuação não representa uma porcentagem de chance. Por exemplo, obter 18 pontos não significa ter 75% de probabilidade de TDAH. A interface informa “NÃO É DIAGNÓSTICO”, e a avaliação profissional continua necessária para interpretar sintomas, história de desenvolvimento, prejuízos funcionais e outros fatores relevantes.

O EEG não acrescenta pontos ao ASRS e não modifica seu ponto de corte. Essa separação é importante para a rastreabilidade: quem lê o relatório consegue reconhecer o que veio das respostas e o que foi calculado a partir do sinal. A revisão do instrumento, de sua versão e de sua aplicação é uma contribuição concreta que a equipe de Psicologia pode oferecer antes do estudo com participantes.

## Hardware e aquisição do sinal

O BrainLink Lite utiliza um canal frontal com contato na testa e referência auricular. Essa configuração permite registrar uma diferença de potencial elétrico em uma região limitada; ela não fornece um mapa de todo o cérebro. Piscadas, movimentos dos olhos, contração muscular, fala, deslocamento do sensor e contato inadequado podem contaminar a aquisição.

A integração Android utiliza o SDK proprietário libStreamSDK v1.3.2 e Bluetooth Clássico. O SDK disponibiliza eventos com amostras brutas, qualidade do sinal e métricas proprietárias, incluindo atenção e meditação. Esses índices do fabricante são exibidos como saídas do SDK e não recebem interpretação clínica própria no projeto.

Existe uma distinção essencial entre frequência de amostragem e código de evento. O identificador CODE_RAW = 128 corresponde ao valor hexadecimal 0x80 do protocolo; esse número identifica o tipo de mensagem. Ele não demonstra que o SDK reduza o sinal para 128 Hz. O protocolo ThinkGear documenta saída típica de 512 amostras por segundo para TGAT/TGAM1 e de 128 para determinados módulos TGEM. O contrato atual do aplicativo utiliza 512 Hz e prevê medição da cadência recebida. A taxa efetiva do conjunto BrainLink Lite, firmware, SDK e celular ainda deve ser confirmada em bancada [1].

A taxa correta é decisiva para interpretar frequências. Se um sinal efetivamente amostrado a 512 Hz fosse analisado como 128 Hz, as frequências seriam estimadas com escala incorreta. Por isso, a homologação deve medir quantidade de amostras por intervalo, perdas, regularidade dos lotes e comportamento em diferentes condições de conexão.

## Processamento digital e controle de qualidade

O aplicativo recebe o EEG bruto em lotes e executa uma análise espectral própria. O pipeline atual segmenta os dados em épocas de 512 amostras, com sobreposição de 50%. Para a taxa nominal de 512 Hz, cada época corresponde a um segundo. O processamento remove a média e a tendência linear, aplica uma janela de Hann e calcula a transformada rápida de Fourier, ou FFT.

A FFT permite estimar como a potência do sinal se distribui por frequência. O projeto agrupa os resultados nas faixas delta de 1 a 4 Hz, theta de 4 a 8 Hz, alfa de 8 a 13 Hz e beta de 13 a 30 Hz, conforme as convenções implementadas no analisador. A comparação entre olhos abertos e fechados descreve o comportamento da sessão; não estabelece, por si só, uma categoria clínica.

O controle de qualidade rejeita trechos com contato inadequado, descontinuidade, saturação, amplitude excessiva ou sinal praticamente plano. Na configuração de hardware, a apresentação do espectro depende de pelo menos 20 épocas aceitas em cada etapa e de uma fração aceita de pelo menos 50% por etapa. São critérios técnicos do software, ainda sujeitos à avaliação experimental, e não limiares de diagnóstico.

A nota de qualidade de zero a 100 informa condições de aquisição e continuidade. Ela não mede inteligência, desempenho cognitivo, saúde mental ou gravidade de TDAH. Já as potências relativas descrevem a participação de cada banda no espectro analisado. Esses dois resultados têm finalidades diferentes e precisam permanecer identificáveis no relatório.

O aplicativo também descreve se theta ficou acima de beta nas duas etapas. Essa observação dialoga com a literatura histórica sobre a razão theta/beta, mas não constitui um classificador individual validado. Não há no fluxo atual um modelo de aprendizado de máquina treinado e validado para calcular probabilidade de TDAH a partir do EEG.

## Arquitetura e organização dos dados

A interface e a lógica de apresentação são desenvolvidas em Flutter e Dart. A camada Android, em Java, gerencia o SDK e a conexão Bluetooth. Canais de plataforma transportam comandos e eventos entre as duas camadas. Modelos de dados representam as amostras, os lotes de EEG e as respostas ao questionário; serviços executam a análise espectral e a exportação.

O fluxo técnico começa no sensor, passa pelo SDK e pela ponte nativa, chega aos modelos Dart e segue para o controle de qualidade, a análise e a apresentação. Em paralelo, as respostas do ASRS alimentam um cálculo próprio. A exportação reúne essas saídas com identificação de sua procedência.

O funcionamento descrito é local, sem conta de usuário, backend ou envio automático à nuvem. Os resultados de sessão permanecem em memória durante o uso; não existe um histórico longitudinal persistente implementado. A exportação cria arquivos por ação do usuário, e o compartilhamento passa a depender do destino escolhido. Para pesquisa, o armazenamento institucional, a identificação dos participantes, os acessos e o prazo de retenção precisam ser definidos no protocolo.

## Participação proposta para os alunos de Psicologia

A colaboração pode começar pela revisão conceitual do rastreio e pela avaliação da comunicação do aplicativo. Os alunos, sob supervisão, podem verificar se instruções e resultados são compreensíveis, se a expressão “possibilidade aumentada” é interpretada adequadamente e se o relatório facilita uma conversa com o profissional sem induzir conclusões indevidas.

Outra frente é a construção do protocolo de pesquisa: definição da população adulta, critérios de participação, roteiro de aplicação, registro de fatores como sono, uso de substâncias e medicação, e procedimentos de acolhimento e encaminhamento. Essas variáveis são propostas para discussão metodológica; não se afirma que já sejam coletadas pelo aplicativo.

Os alunos também podem participar de testes de usabilidade, entrevistas sobre a experiência de uso, categorização de dificuldades e análise qualitativa da compreensão dos resultados. Atividades com participantes e eventual aplicação de instrumentos devem seguir as condições de supervisão e as autorizações institucionais pertinentes. A formação acadêmica dos alunos e a responsabilidade dos supervisores precisam orientar a distribuição das tarefas.

Propomos que Gustavo concentre o desenvolvimento e a documentação técnica, que a orientação acadêmica coordene o desenho do estudo e que a supervisão em Psicologia acompanhe os instrumentos e a interação com participantes. Essa divisão é uma proposta para deliberação, sem atribuir compromissos ainda não acordados à Cintia, à coordenadora ou aos alunos.

## Estudo piloto proposto

O primeiro estudo pode avaliar viabilidade operacional e compreensão dos resultados em adultos. Antes da coleta, a equipe deve definir a pergunta principal, o método de recrutamento, o tamanho da amostra e o plano de análise. Não há, neste documento, uma amostra já aprovada ou um cronograma de recrutamento confirmado.

Indicadores úteis incluem proporção de sessões concluídas, proporção de épocas aproveitáveis, necessidade de reposicionar o sensor, falhas de conexão, tempo para concluir o fluxo e capacidade de explicar corretamente o resultado do rastreio. Entrevistas breves podem revelar se o participante distingue a qualidade do sinal, a descrição das bandas e a possibilidade aumentada indicada pelo ASRS.

Uma investigação posterior de associação entre características do EEG e sintomas deve ser formulada separadamente, com hipóteses previamente definidas, controle de confundidores e análise compatível com o tamanho da amostra. Avaliar desempenho diagnóstico exigiria um desenho próprio e uma referência clínica independente. Comparar apenas EEG com a pontuação do ASRS não comprova capacidade de diagnosticar TDAH.

## Maturidade e próximos marcos

Já existem no código o fluxo de demonstração e conexão, a coleta guiada, o traçado ao vivo, a análise espectral, o questionário adulto e a exportação de relatório. Há testes automatizados e melhorias técnicas em andamento. A existência dessas funções no repositório não equivale à homologação do conjunto sensor e celular nem à validação clínica do produto.

O próximo marco técnico é confirmar em bancada a frequência efetiva, o comportamento das perdas, a qualidade do sinal e as transições entre etapas. Depois, a equipe deve realizar uma sessão completa no aparelho da apresentação e conferir se os arquivos exportados reproduzem os resultados exibidos.

O próximo marco acadêmico é pactuar a participação da Psicologia e consolidar o protocolo. Antes de iniciar pesquisa com participantes, a equipe deverá encaminhar o estudo às instâncias institucionais aplicáveis e definir consentimento, confidencialidade e manejo de resultados. A aprovação no PROBIC é um contexto de fomento, e não uma declaração de que essas outras etapas já foram concluídas.

Para uma disponibilização além do protótipo, ainda será necessário consolidar a gestão de versões, a assinatura de distribuição do Android, as regras de armazenamento e a avaliação do enquadramento aplicável à finalidade pretendida. Não se presume isenção regulatória pelo uso da palavra “possibilidade”.

## Pauta sugerida para a reunião

1. Apresentar o objetivo do projeto e demonstrar o fluxo, identificando quando os dados forem simulados.
2. Explicar de onde vêm a indicação de possibilidade aumentada, a qualidade da coleta e as medidas espectrais.
3. Discutir as contribuições dos alunos de Psicologia e a supervisão de cada atividade.
4. Definir a pergunta prioritária do piloto e os requisitos para iniciar o trabalho com participantes.
5. Acordar responsáveis pelos próximos documentos, pela homologação técnica e por uma reunião de acompanhamento.

Uma forma breve de apresentar o projeto é: “Estamos desenvolvendo um aplicativo que acompanha o sinal cerebral com o BrainLink, aplica um rastreio de sintomas de TDAH em adultos e organiza um relatório para consulta. A possibilidade aumentada é indicada pelo questionário, e o EEG descreve a sessão. Queremos a contribuição da Psicologia para construir o protocolo e avaliar como as pessoas compreendem e utilizam essas informações.”

## Referências e base técnica

[1] NeuroSky. ThinkGear Communications Protocol. Seções RAW Wave Value e CODE Definitions. https://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol

[2] Harvard Medical School e National Comorbidity Survey. ASRS v1.1 de seis questões em português brasileiro. https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/6Q_Portuguese%20%28for%20Brazil%29_final.pdf

[3] Harvard Medical School e National Comorbidity Survey. Atualização da pontuação do ASRS v1.1 de seis questões. Referência adotada pelo projeto. https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/ASRS_v1.1_screener%286Q%29_scoring_update.pdf

Base de implementação consultada em 30 de setembro de 2026: README.md, FRONTEND_INTEGRATION.md, lib/services/eeg_spectrum_analyzer.dart e documentação técnica no diretório vault do Projeto BrainLink. A aprovação para bolsa PROBIC e a conversa com o orientador e a coordenadora compõem o contexto acadêmico informado por Gustavo Bezerra.
