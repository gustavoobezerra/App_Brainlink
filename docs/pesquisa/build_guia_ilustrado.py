"""Guia didatico BrainLink. Gera PDF vetorial e manifesto de revisao."""
from pathlib import Path
import math, json, re
from xml.sax.saxutils import escape
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'output' / 'pdf'
TMP = ROOT / 'tmp' / 'pdfs'
OUT.mkdir(parents=True, exist_ok=True)
TMP.mkdir(parents=True, exist_ok=True)
for name, filename in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Italic','calibrii.ttf'),('Mono','consola.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(Path('C:/Windows/Fonts') / filename)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='Bold', italic='Italic', boldItalic='Bold')
W,H=A4
M=48
CW=W-2*M
NAVY=colors.HexColor('#153451'); TEAL=colors.HexColor('#007F83')
ORANGE=colors.HexColor('#D67A20'); INK=colors.HexColor('#263A4B')
MUTED=colors.HexColor('#566A7A'); PALE=colors.HexColor('#EEF5F8')
RED=colors.HexColor('#B34E48'); GRID=colors.HexColor('#D9E3E9')
styles={
    'p':ParagraphStyle('p',fontName='Body',fontSize=11.2,leading=15.1,textColor=INK,spaceAfter=8),
    'h':ParagraphStyle('h',fontName='Bold',fontSize=12.3,leading=16,textColor=NAVY,spaceBefore=4,spaceAfter=5),
    'small':ParagraphStyle('small',fontName='Body',fontSize=9.2,leading=12.2,textColor=MUTED,spaceAfter=5),
    'eq':ParagraphStyle('eq',fontName='Mono',fontSize=10.2,leading=14.2,textColor=NAVY,spaceAfter=6),
    'title':ParagraphStyle('title',fontName='Bold',fontSize=25,leading=28,textColor=NAVY),
    'cell':ParagraphStyle('cell',fontName='Body',fontSize=10.1,leading=13.2,textColor=INK),
    'call':ParagraphStyle('call',fontName='Body',fontSize=11,leading=14.5,textColor=NAVY),
    'toc':ParagraphStyle('toc',fontName='Body',fontSize=10.8,leading=14,textColor=INK,spaceAfter=5),
}
PAGES=[]
def page(title, part, *blocks):
    PAGES.append(dict(title=title, part=part, blocks=list(blocks)))
def p(t): return ('p',t)
def h(t): return ('h',t)
def note(t): return ('call',t)
def eq(t): return ('eq',escape(t).replace('\n','<br/>'))
def fig(kind, caption='', height=164): return ('fig',kind,caption,height)
def table(headers,rows,widths=None): return ('table',headers,rows,widths)
def source(t): return ('small',t)

def text(c,x,y,t,size=10,color=INK,font='Body'):
    c.setFillColor(color);c.setFont(font,size);c.drawString(x,y,t)
def center(c,x,y,t,size=10,color=INK,font='Body'):
    c.setFillColor(color);c.setFont(font,size);c.drawCentredString(x,y,t)
def arrow(c,x1,y1,x2,y2,color=TEAL):
    c.setStrokeColor(color);c.setFillColor(color);c.setLineWidth(1.5);c.line(x1,y1,x2,y2)
    a=math.atan2(y2-y1,x2-x1);r=5
    path=c.beginPath();path.moveTo(x2,y2);path.lineTo(x2-r*math.cos(a-.5),y2-r*math.sin(a-.5));path.lineTo(x2-r*math.cos(a+.5),y2-r*math.sin(a+.5));path.close();c.drawPath(path,fill=1,stroke=0)
def box(c,x,y,w,hh,label,fill=PALE,size=10):
    c.setFillColor(fill);c.setStrokeColor(GRID);c.roundRect(x,y,w,hh,7,fill=1,stroke=1)
    lines=label.split('\n')
    for j,line in enumerate(lines): center(c,x+w/2,y+hh/2+(len(lines)-1)*6-j*12-3,line,size,NAVY,'Bold')
def curve(c,points,color=TEAL,width=1.8,dash=None):
    c.setStrokeColor(color);c.setLineWidth(width);c.setDash(dash or [])
    path=c.beginPath();path.moveTo(*points[0])
    for xy in points[1:]:path.lineTo(*xy)
    c.drawPath(path);c.setDash([])
def axes(c,hh,xlabel='Frequência (Hz)',ylabel='Potência ilustrativa'):
    x0=42;y0=30;x1=CW-18;y1=hh-27
    c.setStrokeColor(GRID);c.setLineWidth(.6)
    for n in range(1,4):c.line(x0,y0+(y1-y0)*n/4,x1,y0+(y1-y0)*n/4)
    c.setStrokeColor(MUTED);c.line(x0,y0,x1,y0);c.line(x0,y0,x0,y1)
    center(c,(x0+x1)/2,6,xlabel,9,MUTED);text(c,x0,y1+10,ylabel,9,MUTED)
    return x0,y0,x1,y1

def draw_figure(c,kind,hh):
    c.saveState()
    if kind=='route':
        for x,label in [(0,'Contato\nna testa'),(133,'Aparelho +\nBluetooth'),(266,'App recebe\nnúmeros'),(399,'Relatório\nda sessão')]:
            box(c,x,hh-66,100,48,label)
        for x in (102,235,368):arrow(c,x,hh-42,x+28,hh-42)
        box(c,50,12,170,44,'EEG: descreve o sinal');box(c,280,12,170,44,'ASRS: pontua respostas')
        text(c,8,hh-92,'Duas fontes de informação, com cálculos próprios.',10,MUTED)
    elif kind=='head':
        c.setStrokeColor(NAVY);c.setLineWidth(2);c.ellipse(36,12,170,hh-5)
        c.line(90,65,105,47);c.line(105,47,116,63)
        for xx,label in [(62,'A'),(103,'B'),(144,'T')]:
            c.setFillColor(TEAL);c.circle(xx,hh-47,9,fill=1,stroke=0);center(c,xx,hh-50,label,9,colors.white,'Bold')
        arrow(c,175,hh-48,225,hh-48)
        box(c,240,hh-77,230,54,'Um canal = diferença entre\ndois pontos de medição')
        text(c,238,36,'Terra/referência: funções elétricas.',10,MUTED)
        text(c,238,19,'Desenho não fixa posições anatômicas.',9,MUTED)
    elif kind in ('waves','sampling','fft'):
        x0,y0,x1,y1=axes(c,hh,'Tempo (s)' if kind!='fft' else 'Tempo à esquerda | frequência à direita','Sinais sintéticos')
        if kind=='fft':
            mid=(x0+x1)/2-20
            pts=[(x0+(mid-x0)*i/220,80+23*math.sin(i/220*10*math.pi)+10*math.sin(i/220*28*math.pi)) for i in range(221)]
            curve(c,pts);arrow(c,mid+10,85,mid+50,85)
            for x,a,label in [(mid+88,60,'5 Hz'),(mid+156,30,'14 Hz')]:
                c.setFillColor(ORANGE);c.rect(x,31,12,a,fill=1,stroke=0);center(c,x+6,16,label,9)
        else:
            for row,freq in [(0,3),(1,8)]:
                base=y0+(y1-y0)*(.23+.48*row)
                amplitude=(y1-y0)*.13
                pts=[(x0+(x1-x0)*i/300,base+amplitude*math.sin(2*math.pi*freq*i/300)) for i in range(301)]
                curve(c,pts,TEAL if row==0 else ORANGE)
                if kind=='sampling':
                    for i in range(0,301,12):
                        c.setFillColor(TEAL if row==0 else ORANGE);c.circle(*pts[i],2.2,fill=1,stroke=0)
                text(c,x0+4,base+amplitude+5,f'{freq} ciclos no mesmo intervalo',9,MUTED)
            for fraction,label in [(0,'0'),(.5,'0,5'),(1,'1')]:center(c,x0+(x1-x0)*fraction,y0-12,label,8,MUTED)
    elif kind=='buffers':
        text(c,6,hh-17,'Amostras produzidas em ritmo regular',10,NAVY,'Bold')
        for i in range(22):c.setFillColor(TEAL);c.circle(14+i*21,hh-42,3,fill=1,stroke=0)
        arrow(c,250,hh-60,250,75)
        text(c,6,54,'Lotes chegam em grupos, com atrasos variáveis',10,NAVY,'Bold')
        for x in [20,37,54,71,150,167,184,201,360,377,394,411]:
            c.setFillColor(ORANGE);c.rect(x,15,9,20,fill=1,stroke=0)
    elif kind=='overlap':
        unit=(CW-80)/3
        for i in range(4):
            xx=48+i*unit/2;yy=hh-45-i*29
            box(c,xx,yy,unit,23,f'Época {i+1}',size=9)
        text(c,48,5,'A mesma amostra aparece em janelas vizinhas.',10,MUTED)
    elif kind=='bands':
        x=10;scale=(CW-20)/29
        for a,b,label,col in [(1,4,'Delta',NAVY),(4,8,'Theta',TEAL),(8,13,'Alfa',ORANGE),(13,30,'Beta',MUTED)]:
            width=(b-a)*scale;c.setFillColor(col);c.rect(x,45,width,65,fill=1,stroke=0)
            center(c,x+width/2,76,label,10,colors.white,'Bold');text(c,x,25,str(a)+' Hz',9,MUTED);x+=width
        text(c,CW-42,25,'30 Hz',9,MUTED)
        text(c,10,hh-18,'As faixas são compartimentos de frequência.',10,NAVY,'Bold')
    elif kind in ('spectrum','log','tbr','offset','fit','alpha'):
        logx=kind in ('log','offset')
        x0,y0,x1,y1=axes(c,hh,'Frequência (Hz; escala logarítmica)' if logx else 'Frequência (Hz)','log10 da potência' if kind!='tbr' else 'Potência linear ilustrativa')
        fs=[1+29*i/300 for i in range(301)]
        def xp(f):return x0+(x1-x0)*(math.log(f)/math.log(30) if logx else (f-1)/29)
        def yp(v):return y0+(y1-y0)*v/4
        bg=[3.6-1.7*math.log10(f) for f in fs]
        if kind=='tbr':
            vals=[70/(f*f) for f in fs]
            curve(c,[(xp(f),y0+(y1-y0)*min(v/70,1)) for f,v in zip(fs,vals)])
            for a,b,col in [(4,8,TEAL),(13,30,ORANGE)]:
                c.setFillColor(col);c.setFillAlpha(.15);c.rect(xp(a),y0,xp(b)-xp(a),y1-y0,fill=1,stroke=0);c.setFillAlpha(1)
            text(c,x0+80,y1-13,'Fundo C/f²; nenhum pico',10,NAVY)
        elif kind=='offset':
            for vals,col in [(bg,TEAL),([v+.45 for v in bg],ORANGE),([3.6-2.25*math.log10(f) for f in fs],RED)]:curve(c,[(xp(f),yp(v)) for f,v in zip(fs,vals)],col)
            text(c,x0+195,y1-10,'Laranja: nível maior',9,ORANGE)
            text(c,x0+195,y1-25,'Vermelho: queda mais íngreme',9,RED)
        elif kind=='log':
            curve(c,[(xp(f),yp(v)) for f,v in zip(fs,bg)])
            text(c,x0+190,y1-10,'Reta no gráfico log-log',10,NAVY)
        else:
            curve(c,[(xp(f),yp(v)) for f,v in zip(fs,bg)],MUTED,1.4,[3,3])
            for peak,col in [(10,TEAL)]+([(11.5,ORANGE)] if kind=='alpha' else []):
                vals=[v+.95*math.exp(-.5*((f-peak)/1.25)**2) for f,v in zip(fs,bg)]
                if kind=='fit':vals=[v+.1*math.sin(f*4)+.08*math.sin(f*9) for f,v in zip(fs,vals)]
                curve(c,[(xp(f),yp(v)) for f,v in zip(fs,vals)],col)
            text(c,x0+205,y1-12,'Tracejado: fundo ajustado',9,MUTED)
        if not logx:
            for f in [1,4,8,13,20,30]:center(c,xp(f),y0-12,str(f),8,MUTED)
        else:
            for f in [1,2,4,8,16,30]:center(c,xp(f),y0-12,str(f),8,MUTED)
    elif kind=='task':
        for i,(label,col) in enumerate([('Repouso',PALE),('Tarefa',colors.HexColor('#DDF2EE')),('Recuperação',PALE)]):box(c,i*168,65,155,55,label,col,11)
        arrow(c,157,91,165,91);arrow(c,325,91,333,91)
        text(c,8,35,'Medir mudanças entre etapas e desempenho na tarefa.',10,MUTED)
        text(c,8,16,'Duração e regras precisam ser fixadas antes da pesquisa.',10,MUTED)
    elif kind=='models':
        for i,label in enumerate(['ASRS','ASRS + EEG','ASRS + tarefa','ASRS + EEG + tarefa']):box(c,i*125,80,116,53,label.replace(' + ',' +\n'),size=9)
        for i in range(4):arrow(c,i*125+58,77,i*125+58,48)
        box(c,55,3,390,40,'Comparar com avaliação clínica independente')
    elif kind=='leak':
        box(c,2,hh-66,125,46,'Uma pessoa\n100 janelas')
        arrow(c,130,hh-42,202,hh-42)
        box(c,210,hh-66,130,46,'Treino\nou teste')
        text(c,5,62,'Todas as janelas e visitas da pessoa ficam juntas.',11,TEAL,'Bold')
        text(c,5,36,'Espalhar a mesma pessoa nos dois grupos facilita',10,MUTED)
        text(c,5,20,'reconhecer sua assinatura, sem aprender a condição.',10,MUTED)
    elif kind=='stairs':
        for i,label in enumerate(['Medição correta','Medida repetível','Ganho clínico']):
            box(c,i*168,20+i*37,155,48,label,size=10)
            if i<2:arrow(c,i*168+156,45+i*37,(i+1)*168+8,64+i*37)
    elif kind=='cartoon':
        for i,(label,quote) in enumerate([('Sensor','Eu trouxe números.'),('Matemática','Eu organizei os números.'),('Pesquisa','Eu testo o que significam.')]):
            xx=20+i*168;c.setStrokeColor(NAVY);c.circle(xx+55,hh-49,16);c.line(xx+55,hh-66,xx+55,35);c.line(xx+55,67,xx+28,50);c.line(xx+55,67,xx+83,50)
            center(c,xx+55,hh-14,label,11,NAVY,'Bold');center(c,xx+55,8,quote,8.6,TEAL)
    c.restoreState()

def make_block(block):
    kind=block[0]
    if kind in ('p','h','small','eq','toc'):
        q=Paragraph(block[1],styles[kind]);_,height=q.wrap(CW,1000)
        return height+styles[kind].spaceAfter+(styles[kind].spaceBefore or 0),q
    if kind=='call':
        q=Paragraph(block[1],styles['call']);_,height=q.wrap(CW-24,1000)
        return height+28,q
    if kind=='fig':
        q=Paragraph(block[2] or 'Desenho esquemático. Valores e curvas apenas ilustrativos.',styles['small']);_,cap=q.wrap(CW,1000)
        return block[3]+cap+14,q
    if kind=='table':
        widths=[CW*v for v in block[3]] if block[3] else [CW/len(block[1])]*len(block[1])
        cells=[[Paragraph('<b>'+v+'</b>',styles['cell']) for v in block[1]]]+[[Paragraph(str(v),styles['cell']) for v in row] for row in block[2]]
        q=Table(cells,colWidths=widths,hAlign='LEFT')
        q.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),PALE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),('LINEBELOW',(0,0),(-1,0),1,TEAL),('LINEBELOW',(0,1),(-1,-1),.4,GRID)]))
        _,height=q.wrap(CW,1000);return height+12,q
    raise ValueError(kind)

def build():
    target=OUT/'BrainLink_Guia_Completo_Ilustrado_EEG_Aperiodico.pdf'
    c=canvas.Canvas(str(target),pagesize=A4,pageCompression=1)
    c.setTitle('BrainLink explicado do zero: EEG, componente aperiódico e melhorias')
    c.setAuthor('Projeto BrainLink | Material didático preparado para Gustavo Bezerra')
    c.setSubject('Estado do código em 03/10/2026, conceitos, exemplos e propostas de pesquisa')
    audit=[]
    for idx,item in enumerate(PAGES,1):
        c.bookmarkPage(f'p{idx}');c.addOutlineEntry(item['title'],f'p{idx}',0,False)
        c.setFillColor(TEAL);c.rect(0,H-9,W,9,fill=1,stroke=0)
        text(c,M,H-39,'BRAINLINK / GUIA ILUSTRADO',9,TEAL,'Bold')
        c.setFont('Body',9);c.setFillColor(MUTED);c.drawRightString(W-M,H-39,'03 OUT 2026')
        text(c,M,H-70,item['part'].upper(),9,MUTED,'Bold')
        title=Paragraph(item['title'],styles['title']);_,th=title.wrap(CW,1000);title.drawOn(c,M,H-87-th)
        y=H-101-th
        for block in item['blocks']:
            height,obj=make_block(block)
            if y-height<59:raise RuntimeError(f'Page {idx} ({item["title"]}) overflow: y={y:.1f}, block={block[0]}, h={height:.1f}')
            if block[0]=='fig':
                c.saveState();c.translate(M,y-block[3]);draw_figure(c,block[1],block[3]);c.restoreState()
                _,cap=obj.wrap(CW,1000);obj.drawOn(c,M,y-block[3]-cap-3)
            elif block[0]=='call':
                c.setFillColor(PALE);c.roundRect(M,y-height+7,CW,height-9,6,fill=1,stroke=0)
                c.setFillColor(TEAL);c.rect(M,y-height+7,3,height-9,fill=1,stroke=0)
                _,ph=obj.wrap(CW-24,1000);obj.drawOn(c,M+12,y-10-ph)
            else:
                _,ph=obj.wrap(CW,1000);obj.drawOn(c,M,y-ph-(styles[block[0]].spaceBefore or 0) if block[0] in styles else y-ph)
            y-=height
        c.setStrokeColor(GRID);c.line(M,43,W-M,43)
        text(c,M,27,'EEG descritivo + rastreio ASRS | propostas identificadas no texto',8,MUTED)
        c.setFillColor(MUTED);c.setFont('Bold',9);c.drawRightString(W-M,27,f'{idx:02d} / {len(PAGES):02d}')
        audit.append({'page':idx,'title':item['title'],'bottom_y':round(y,1)})
        c.showPage()
    c.save()
    (TMP/'guia_layout_manifest.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pdf':str(target),'pages':len(PAGES),'lowest_content_y':min(i['bottom_y'] for i in audit)},ensure_ascii=False))

# Conteúdo abaixo. Cada página é uma pequena aula, com paginação controlada.
page('BrainLink explicado do zero','Guia para entender, discutir e decidir',
    p('Como um contato na testa vira números, como esses números viram um espectro e por que a parte <b>aperiódica</b> muda a interpretação das chamadas ondas cerebrais.'),
    fig('spectrum','Capa: espectro sintético com um pico sobre um fundo inclinado. Não representa um participante.',210),
    p('Este guia acompanha o projeto atual e explica as melhorias propostas, uma por uma. Você não precisa saber neurologia, programação, estatística ou matemática avançada. As fórmulas aparecem depois da ideia, acompanhadas de exemplos.'),
    note('<b>A pergunta central:</b> podemos medir melhor o EEG e demonstrar que essa informação acrescenta algo ao rastreio de TDAH já feito pelo ASRS?'),
    p('Preparado para <b>Gustavo Bezerra</b>. Base: código local e pesquisa consultados em 3 de outubro de 2026. Os exemplos de pessoas e números são fictícios. As propostas de melhoria não foram implementadas durante a elaboração deste material.'),
    source('Material didático e de planejamento científico. O ASRS indica resultado de rastreio; o EEG atual descreve a coleta. A leitura deste guia não habilita diagnóstico por headset.'))

page('Como aproveitar este guia','Antes de começar',
    p('Leia na ordem se quiser construir o entendimento desde o início. Para uma reunião, use o sumário e volte aos exemplos quando aparecer um termo desconhecido. Os desenhos são esquemáticos: tornam uma relação visível, mas não reproduzem a anatomia ou um exame real.'),
    h('Três expressões que você encontrará'),
    p('<b>Hoje:</b> comportamento encontrado no código do projeto. Ler o código confirma o que foi programado; não confirma sozinho que todo aparelho executa aquilo corretamente.'),
    p('<b>Proposta:</b> mudança que sugerimos construir ou comparar. Uma proposta ainda precisa de implementação e verificação.'),
    p('<b>Hipótese:</b> explicação ou previsão que pode ser testada e pode estar errada. Exemplo: separar o fundo pode tornar uma medida mais estável. Só os dados dirão se isso acontece.'),
    fig('stairs','Cada degrau exige uma verificação diferente. Um resultado no primeiro não garante o último.',148),
    p('<b>Analogia recorrente:</b> imagine uma paisagem com terreno e montanhas. O terreno ajuda a explicar o fundo do espectro; as montanhas ajudam a explicar seus picos. Quando a analogia tiver um limite, ele será informado.'),
    note('Nenhum conhecimento prévio é exigido. Se uma frase parecer difícil, o problema a resolver é a explicação, não a capacidade do leitor.'))

page('Onde está cada assunto','Sumário navegável - primeira metade')
page('Onde está cada assunto','Sumário navegável - segunda metade')

page('O projeto inteiro em uma página','01 / A visão geral',
    p('<b>TDAH</b> significa Transtorno de Déficit de Atenção com Hiperatividade. O BrainLink reúne uma <b>medição elétrica</b>, feita por um aparelho encostado na pele, e um <b>questionário</b> respondido pela pessoa. O aplicativo organiza os resultados para registro e conversa com um profissional.'),
    fig('route','Fluxo geral. A presença dos dois resultados no mesmo documento não significa que um entre no cálculo do outro.'),
    p('<b>EEG</b> significa eletroencefalograma ou eletroencefalografia, conforme o contexto: o registro ou a técnica de medir diferenças de potencial elétrico relacionadas à atividade cerebral. O aparelho também pode captar interferências de olhos, músculos e contato.'),
    p('<b>ASRS</b> é um instrumento de autorrelato: a pessoa informa com que frequência encontra determinadas dificuldades. O app usa sua versão de seis perguntas para adultos e calcula uma pontuação pelas respostas.'),
    p('Hoje, o EEG permite descrever bandas de frequência em duas etapas. O ASRS determina se o ponto de corte do rastreio foi atingido. A expressão <b>possibilidade aumentada no ASRS</b> vem desse segundo caminho.'),
    note('A melhoria pretendida tem duas partes: tornar a medição mais verificável e investigar se características do EEG acrescentam informação útil. Essas duas perguntas precisam de respostas próprias.'),
    source('Estado atual: fontes de código C1-C6, listadas ao final.'))

page('O que o contato na testa percebe','02 / Da eletricidade ao número',
    p('Células nervosas se comunicam por processos elétricos e químicos. Quando muitas células contribuem para campos elétricos, parte dessa atividade pode ser medida na superfície da cabeça. O registro superficial é uma mistura; ele não lê um pensamento específico.'),
    p('Um <b>eletrodo</b> é um contato que participa da medição elétrica. Um <b>amplificador</b> aumenta um sinal pequeno para o circuito conseguir tratá-lo. Um <b>conversor analógico-digital</b> transforma uma grandeza elétrica contínua em uma sequência de números.'),
    eq('Diferença elétrica -> amplificação -> conversão -> números'),
    p('Pense em uma régua que mede a altura de uma superfície muitas vezes por segundo. Cada medida vira um número. Ao colocar os números em ordem, obtemos um desenho que sobe e desce. No EEG, a grandeza medida é elétrica, não altura.'),
    h('Por que a unidade é tão pequena?'),
    p('O <b>volt</b> é uma unidade de diferença de potencial elétrico. Um <b>microvolt</b>, escrito µV, é um milionésimo de volt. A escala ajuda a descrever sinais pequenos. Um valor grande no gráfico pode vir de uma piscada ou movimento e não de uma atividade cerebral mais forte.'),
    note('O que chega primeiro ao app são contagens digitais. Para chamar essas contagens de microvolts, precisamos conhecer a escala e o ganho do equipamento. O código usa um fator ThinkGear; a confirmação física do modelo continua necessária.'),
    source('Conversão de unidade: documentação NeuroSky [3]. Implementação: C2.'))

page('Três contatos não são três canais','03 / Montagem e referência',
    p('Uma tensão é medida <b>entre pontos</b>. A palavra <b>canal</b> identifica um sinal de medição independente. Três contatos físicos podem servir a um único canal, com funções de medição, referência e terra.'),
    fig('head','Esquema funcional; letras A, B e T apenas diferenciam contatos. Não são uma instrução de posicionamento.'),
    p('<b>Referência</b> é o ponto usado na comparação elétrica. <b>Terra</b> participa do funcionamento e estabilidade do circuito. A função exata depende do desenho do aparelho. Alterar a referência pode alterar o traçado e seu espectro.'),
    p('A fabricante descreve três contatos na testa para Lite, SE e Tune. Um estudo com Lite descreve uma derivação bipolar F7-Fp1. Esses códigos são nomes de posições em um sistema de localização sobre a cabeça; não é necessário decorá-los para entender o problema.'),
    p('A explicação anterior de um contato na orelha não deve ser generalizada ao Lite. Existem versões Pro e acessórios com outras montagens. O primeiro passo prático é identificar o modelo e a montagem que realmente serão usados.'),
    note('Analogia: três fios ligados a um termômetro não significam três temperaturas medidas. Da mesma forma, um canal frontal não permite desenhar sozinho um mapa de atividade de todo o cérebro.'),
    source('Fontes: FAQ Macrotellect [1]; estudo de montagem Lite [2].'))

page('Sinal bruto, índices prontos e som','04 / Três coisas que parecem uma só',
    p('<b>Sinal bruto</b>, ou raw, é a sequência de amostras entregue pelo aparelho antes da análise espectral feita pelo nosso aplicativo. “Bruto” aqui não significa necessariamente que nenhum filtro eletrônico já foi aplicado pelo equipamento.'),
    p('<b>SDK</b> é um conjunto de ferramentas de software fornecido para conversar com o dispositivo. Além do raw, ele entrega índices próprios, como “atenção” e “meditação”, e estimativas de potência por banda. Esses índices usam critérios do fabricante.'),
    table(['Caminho','O que representa'],[
        ['Raw -> análise do app','Amostras usadas para calcular o espectro descrito neste guia.'],
        ['Índices do SDK','Resumos proprietários; não são uma porcentagem clínica de atenção ou TDAH.'],
        ['Som do celular','Aviso de troca de etapa ou término da sessão.']],[.33,.67]),
    p('No fluxo auditado, <b>não há gravação de voz ou ambiente</b>. O celular emite um alerta e vibra. A coleta cerebral ocorre pelos contatos elétricos, não pelo microfone. Essa distinção corrige a ambiguidade da expressão “captação de áudio”.'),
    p('Imagine um restaurante: o raw são os ingredientes que recebemos para preparar nossa análise; o índice do fabricante é um prato já preparado, com receita própria. Misturar os dois sem identificar a origem torna difícil saber de onde veio o resultado.'),
    note('Hoje o relatório identifica os índices como proprietários. Uma nota 80 em “atenção” do aparelho não deve ser lida como 80% de capacidade de atenção.'),
    source('Verificação: C1, C4 e C6.'))

page('512 Hz, 128 e a velocidade da coleta','05 / O que significa amostrar',
    p('<b>Amostra</b> é uma medida em um instante. <b>Frequência de amostragem</b> é quantas medidas o aparelho produz por segundo. Hertz, ou Hz, significa “por segundo” quando descreve essa taxa.'),
    eq('512 Hz = 512 medidas por segundo\n1 / 512 segundo = aproximadamente 1,95 milissegundo'),
    p('Um <b>milissegundo</b> é um milésimo de segundo. Registrar 512 pontos por segundo não significa que o cérebro esteja oscilando a 512 Hz. A câmera pode tirar 60 fotos por segundo de uma pessoa que dá apenas dois passos nesse intervalo.'),
    fig('sampling','Pontos são amostras sobre sinais inventados. O desenho é didático e não usa 512 pontos visíveis.',148),
    p('O app está configurado para 512 Hz. No protocolo, <b>CODE_RAW = 128</b> é o número que identifica um tipo de mensagem, também escrito 0x80. É como o número de uma linha de ônibus: ele não informa a velocidade do ônibus.'),
    p('Existem módulos ThinkGear com taxas diferentes. Por isso, documentação do módulo e medição física devem confirmar a taxa real. Se o software presumir uma taxa errada, o eixo de frequência também ficará errado.'),
    source('Protocolo e variantes: [3]. Configuração local: C1-C2.'))

page('Amostragem não é horário de entrega','06 / Bluetooth, lotes e atrasos',
    p('O Android reúne 512 amostras em um <b>lote</b>, isto é, um pacote de números, antes de enviá-las ao Flutter, a tecnologia usada na interface. Isso reduz o trabalho de enviar centenas de mensagens pequenas.'),
    fig('buffers','A produção pode ser regular e a chegada irregular. As duas linhas não representam medidas reais.'),
    p('<b>Buffer</b> é uma área temporária de armazenamento. <b>Latência</b> é o atraso entre produzir e receber um dado. <b>Jitter</b> é a variação desse atraso. O Bluetooth e o processamento do celular podem fazer um lote chegar mais tarde que outro.'),
    eq('Taxa observada no app = 512 / intervalo entre lotes (s)'),
    p('Se um lote leva 1 segundo para chegar após o anterior, a estimativa é 512 Hz. Se leva 1,2 segundo, ela cai para aproximadamente 427 Hz. Isso pode significar atraso de entrega; não prova, sozinho, que o conversor mudou de velocidade.'),
    p('<b>Hoje:</b> o app verifica desvio de até 15% por lote. <b>Proposta:</b> combinar intervalos maiores, contagem acumulada e indicadores de perda. Isso pode reduzir rejeições causadas apenas por transporte irregular.'),
    note('É a diferença entre o ritmo de uma fábrica e o horário em que os caminhões chegam. Uma entrega atrasada não prova que a fábrica passou a produzir mais devagar.'),
    source('Verificação: C1-C2. A melhoria ainda requer teste com aparelho.'))

page('Como a sessão acontece hoje','07 / O protocolo atual',
    p('<b>Protocolo</b> é uma receita de coleta: o que a pessoa faz, em que ordem e por quanto tempo. Mantê-lo estável ajuda a interpretar diferenças entre sessões.'),
    table(['Etapa','No aparelho real'],[
        ['Preparação','Conectar; observar contato adequado por 3 segundos; verificar incompatibilidade detectada de cadência.'],
        ['Olhos abertos','Coletar por 60 segundos.'],
        ['Transição','Emitir aviso sonoro e vibração; mudar a orientação.'],
        ['Olhos fechados','Coletar por mais 60 segundos.'],
        ['Resultado','Calcular qualidade e análise; registrar ASRS separadamente.']],[.27,.73]),
    p('A demonstração usa etapas de oito segundos e critérios reduzidos. Ela serve para demonstrar o fluxo e não deve ser confundida com uma coleta de hardware adequada para pesquisa.'),
    p('O código invalida a coleta em situações como desconexão, erro do fluxo bruto ou saída do app do primeiro plano. Também descarta lote identificado como atravessando a transição entre olhos abertos e fechados.'),
    p('Essa identificação usa o horário de fechamento do lote no Android e a taxa presumida. Portanto, ela tem a limitação de transporte explicada na página anterior. O tempo marcado pelo cronômetro não garante, por si só, igual quantidade de sinal aproveitável.'),
    note('Dois minutos de relógio e dois minutos de EEG limpo são coisas diferentes. Para pesquisa, queremos registrar os dois.'),
    source('Estado atual: C4.'))

page('Qualidade: o que aceitamos e rejeitamos','08 / Artefatos e limites',
    p('<b>Artefato</b> é uma contribuição indesejada para a análise pretendida: piscada, movimento, contração muscular, contato instável ou interferência elétrica. Um artefato pode ser perfeitamente real e grande; apenas não representa o fenômeno cerebral que queremos estudar.'),
    p('O app já rejeita trechos com contato ruim, lotes incompletos, perdas locais, sequência incompatível, cadência incompatível, saturação e algumas amplitudes extremas. <b>Saturação</b> ocorre quando a medição encosta no limite representável e perde a forma original.'),
    table(['Regra atual','Tradução simples'],[
        ['poorSignal até 50','Índice do SDK em que menor costuma indicar melhor contato.'],
        ['Módulo até 150 µV','Evitar pontos com magnitude muito elevada.'],
        ['Pico a pico até 200 µV','Limitar distância entre maior e menor valor da janela.'],
        ['Desvio padrão mínimo 0,5 µV','Evitar um traçado quase parado, chamado sinal plano.']],[.42,.58]),
    p('<b>Desvio padrão</b> resume o espalhamento dos valores em torno da média. Um sinal quase constante tem espalhamento pequeno. Esses cortes dependem da conversão de unidade presumida e precisam ser testados no módulo real.'),
    p('Passar nos limites não prova ausência de piscadas ou músculo. A proposta é gravar situações controladas, anotar os artefatos e medir quanto o algoritmo realmente detecta e quanto sinal útil descarta.'),
    note('A nota de qualidade 0-100 da interface e a porcentagem de épocas aceitas são cálculos diferentes. Nenhum dos dois é uma nota de saúde ou inteligência.'),
    source('Limiares de implementação: C2-C4; não são limites clínicos universais.'))

page('Por que cortar o sinal em pedaços','09 / Épocas, janelas e sobreposição',
    p('Uma <b>época</b> é um trecho de duração definida. O app analisa trechos de um segundo, com 512 amostras. A próxima época começa meio segundo depois. Por isso, épocas vizinhas compartilham metade dos pontos.'),
    fig('overlap','Cada caixa representa um trecho de um segundo; os inícios estão separados por meio segundo.',166),
    p('<b>Sobreposição de 50%</b> significa esse compartilhamento. A vantagem é aproveitar diferentes recortes da sequência. O limite é que os recortes não são observações completamente independentes.'),
    eq('20 épocas consecutivas:\n1 segundo + 19 × 0,5 segundo = 10,5 segundos únicos'),
    p('Hoje a análise exige pelo menos 20 épocas aceitas em cada etapa e aproveitamento mínimo de 50% em cada etapa. Esse mínimo não equivale a 20 segundos independentes. Se há buracos, o tempo único depende da posição dos trechos aceitos.'),
    p('Imagine fotografias de uma rua: duas fotos com metade da paisagem repetida não mostram duas ruas inteiramente novas. Contar fotos é diferente de medir a extensão única da rua.'),
    note('Proposta: informar duração única válida, tamanho dos trechos contínuos e fração rejeitada. Nunca colar dois pedaços distantes e fingir que eram um trecho contínuo.'),
    source('Implementação: C3.'))

page('Preparar o traçado para fazer a conta','10 / Média, tendência e janela Hann',
    p('Antes de calcular frequências, o app faz três preparações. A <b>média</b> é a soma dos valores dividida pela quantidade deles. Subtrair a média recentraliza o trecho ao redor de zero.'),
    p('A <b>tendência linear</b> é uma subida ou descida aproximadamente reta ao longo do tempo. Retirá-la ajuda a evitar que uma inclinação lenta domine parte da análise. Essa operação é chamada <b>detrending</b>.'),
    p('A <b>janela Hann</b> multiplica o trecho por pesos: perto de zero nas pontas e maiores no meio. É como abaixar gradualmente o volume no começo e no fim de uma gravação para evitar um corte brusco.'),
    eq('Ponto preparado = (ponto original - média - tendência) × peso'),
    h('Por que isso ajuda?'),
    p('A transformação de frequências interpreta o trecho de uma maneira em que bordas abruptas podem espalhar energia por frequências vizinhas. Esse espalhamento é chamado <b>vazamento espectral</b>. Hann reduz parte desse efeito, mas também alarga picos e muda a escala da energia.'),
    note('<b>Distinção essencial:</b> remover uma reta do traçado ao longo do tempo não é separar o componente aperiódico do espectro. Uma coisa atua nos pontos temporais; a outra descreve como a potência varia com a frequência.'),
    p('Hoje essas três preparações já existem. A proposta de normalizar a potência deve levar em conta a energia dos pesos aplicados. Simplesmente colocar um novo nome no algoritmo não corrige a escala.'),
    source('Código C3; referência de processamento e normalização [4].'))

page('Frequência e amplitude sem mistério','11 / Duas perguntas diferentes',
    p('<b>Frequência</b> pergunta quantas repetições acontecem por segundo. <b>Amplitude</b> descreve o tamanho de uma variação. Uma onda pode ser rápida e pequena, ou lenta e grande.'),
    fig('waves','Mesmo intervalo de tempo, duas quantidades de ciclos. Curvas artificiais, com amplitude semelhante.',168),
    p('Em um balanço de parque, a frequência está ligada a quantas idas e voltas ocorrem no mesmo tempo; a amplitude, ao quanto o balanço se afasta do meio. A analogia ajuda a separar velocidade de repetição e tamanho.'),
    p('Um <b>ciclo</b> é uma repetição completa. Dez ciclos em um segundo correspondem a 10 Hz. Esse número descreve o ritmo, não se ele é bom, ruim, atento ou desatento.'),
    p('O EEG real é uma mistura irregular de muitas contribuições. Não costuma parecer uma senoide perfeita, aquela curva suave de livro escolar. A análise de frequências permite descrever parte dessa mistura mesmo quando não vemos uma onda isolada a olho nu.'),
    note('Uma banda ter potência não prova que existe uma oscilação bem definida naquela banda. Para falar em pico oscilatório identificável, precisamos observar sua relação com o fundo e com o ruído da medição.'))

page('FFT: olhar a mesma mistura de outro jeito','12 / Do tempo para a frequência',
    p('No <b>domínio do tempo</b>, o gráfico mostra como o valor muda a cada instante. No <b>domínio da frequência</b>, mostra quanto diferentes ritmos contribuem para descrever aquele trecho.'),
    p('<b>FFT</b> significa transformada rápida de Fourier. É um algoritmo eficiente para calcular essa representação em frequências. Ele não identifica TDAH; faz uma transformação matemática.'),
    fig('fft','Mistura sintética à esquerda; duas contribuições destacadas à direita. A figura simplifica o resultado real.',155),
    p('Analogia: você escuta uma banda tocando junta. A transformação ajuda a descrever graves e agudos da mistura. Ela não conta automaticamente quem é o músico, qual sua intenção ou se ele cometeu um erro.'),
    p('Cada posição calculada no eixo de frequência é chamada <b>bin</b>, como uma divisória de uma régua. O espaçamento depende do tempo realmente observado:'),
    eq('Espaçamento entre bins = taxa de amostragem / pontos\n512 / 512 = 1 Hz; 512 / 2048 = 0,25 Hz'),
    p('2048 pontos a 512 Hz duram quatro segundos. Observar por mais tempo permite um grid mais fino, mas mistura mudanças ocorridas dentro desses quatro segundos. Adicionar zeros ao final, chamado <b>zero-padding</b>, suaviza a apresentação sem criar dados novos.'),
    source('O espaçamento não equivale sozinho à resolução efetiva: a janela e o ruído também importam. [4]'))

page('As bandas são gavetas de frequência','13 / Delta, theta, alfa e beta',
    p('Uma <b>banda</b> é um intervalo de frequências. O app soma a potência dentro de quatro intervalos. Os nomes facilitam a conversa; não são quatro substâncias diferentes circulando na cabeça.'),
    fig('bands','Faixas implementadas. A borda superior de cada intervalo é exclusiva.',155),
    table(['Banda','Regra atual','Exemplo de frequência incluída'],[
        ['Delta','1 até menos de 4 Hz','3 Hz'],['Theta','4 até menos de 8 Hz','6 Hz'],['Alfa','8 até menos de 13 Hz','10 Hz'],['Beta','13 até menos de 30 Hz','20 Hz']],[.20,.40,.40]),
    p('O valor exatamente 8 Hz entra em alfa, não em theta. Um pico de 12 Hz continua na faixa alfa implementada. Picos têm largura: parte de uma elevação pode alcançar uma banda vizinha.'),
    p('É tentador colar etiquetas como “theta = distração” e “beta = atenção”. Essas equivalências são simplificações excessivas. As bandas mudam com várias condições, e o fundo do espectro também contribui para sua potência.'),
    note('Analogia: classificar músicas por duração não revela automaticamente se elas são alegres ou tristes. Organizar números em faixas é diferente de descobrir seu significado clínico.'),
    source('Bandas e somas: C3. O uso de limites diferentes entre estudos exige cuidado na comparação.'))

page('Potência e PSD: como colocar uma régua','14 / Unidades e normalização',
    p('<b>Potência do sinal</b> resume a magnitude quadrática de suas variações. Se multiplicarmos toda a amplitude por dois, sua potência cresce por um fator de quatro. Não é uma nota de desempenho cerebral.'),
    p('<b>PSD</b>, densidade espectral de potência, indica potência por unidade de frequência. Com amplitude calibrada em µV, a unidade da PSD é µV²/Hz. Ao somar a área de uma banda, a unidade passa a µV².'),
    eq('PSD[k] = c[k] × |FFT(pontos × pesos)[k]|²\n         / (fs × soma dos pesos²)\nPotência da banda = soma(PSD[k] × passo em Hz)'),
    p('<b>fs</b> é a taxa de amostragem. <b>k</b> identifica um bin. As barras indicam magnitude. <b>c[k]</b> vale 2 nos bins positivos internos quando mostramos apenas metade do espectro; nas extremidades especiais vale 1. Isso contabiliza a energia da representação de frequências negativas.'),
    p('Hoje o código calcula magnitude da FFT ao quadrado e soma bins, mas não aplica essa normalização completa. O nome interno “absoluteBands” não garante potência calibrada. A melhoria é tornar unidades e comparações verificáveis.'),
    p('Analogia: uma balança pode mostrar números consistentes e ainda não estar em gramas. A calibração liga o número a uma unidade conhecida. Se ambos os lados de uma razão recebem o mesmo fator, ele cancela; por isso a correção pode preservar percentuais atuais.'),
    note('Para verificar: usar sinais matemáticos conhecidos e comparar com uma implementação de referência, mantendo os mesmos pesos, recortes e regras. Confirmar também o ganho físico do aparelho.'),
    source('Normalização de referência: SciPy Welch [4]. Estado atual: C2-C3.'))

page('Porcentagem pode aumentar sem a banda aumentar','15 / Absoluto versus relativo',
    p('<b>Potência absoluta</b> é a quantidade atribuída a uma banda em uma escala definida. <b>Potência relativa</b> é a participação dessa banda no total escolhido. O denominador, isto é, o número pelo qual dividimos, muda o significado da porcentagem.'),
    table(['Exemplo fictício','Situação A','Situação B'],[
        ['Theta','10 unidades','10 unidades'],['Beta','20 unidades','20 unidades'],['Alfa','70 unidades','30 unidades'],['Total das bandas do exemplo','100 unidades','60 unidades'],['Theta / total','10%','16,7%']],[.48,.26,.26]),
    p('Theta permaneceu em 10 unidades. Só alfa caiu. Mesmo assim, a porcentagem de theta subiu. Para facilitar a conta, este exemplo considera apenas três bandas; o app inclui delta no total de 1 até menos de 30 Hz.'),
    eq('Participação de theta = potência theta / total × 100'),
    p('Analogia: você tem dez maçãs. Se a cesta contém também noventa outras frutas, maçãs são 10%. Se alguém retira quarenta outras frutas, continuam existindo dez maçãs, mas sua participação sobe para 16,7%.'),
    p('<b>Hoje:</b> o relatório mostra porcentagens. <b>Proposta:</b> manter o denominador explícito e, quando a escala estiver confirmada, apresentar também potência absoluta e contexto. Isso evita dizer que uma atividade aumentou apenas porque sua fatia ficou maior.'),
    note('Ao ler “theta aumentou”, pergunte: aumentou em quantidade, em porcentagem do total, em relação a beta ou em relação ao fundo? São perguntas diferentes.'))

page('A média também precisa de uma receita','16 / Duas agregações, dois resultados',
    p('<b>Agregar</b> significa juntar várias medidas em um resumo. O app calcula percentuais em cada época aceita e depois tira a média desses percentuais. Outra opção seria somar as potências primeiro e só então calcular a porcentagem.'),
    table(['Época fictícia','Theta','Total','Theta relativo'],[
        ['A','10','20','50%'],['B','10','100','10%']],[.28,.22,.22,.28]),
    eq('Média dos percentuais = (50% + 10%) / 2 = 30%\nPercentual agregado = (10 + 10) / (20 + 100) = 16,7%'),
    p('Na primeira receita, cada época tem o mesmo peso na média final. Na segunda, uma época com maior potência total influencia mais o resultado. Nenhuma receita é automaticamente a resposta correta para toda pergunta.'),
    h('E a mediana?'),
    p('A <b>mediana</b> é o valor do meio depois de ordenar os resultados. Para 10, 11 e 100, a média é 40,3 e a mediana é 11. Por isso, a mediana pode resistir melhor a valores extremos. Resistir melhor não significa reconhecer todo artefato.'),
    p('O método de <b>Welch</b> resume estimativas espectrais feitas em janelas, frequentemente sobrepostas. O app já tem uma estrutura semelhante. Propomos comparar a normalização, o tamanho das janelas e formas de agregação, incluindo mediana com ajuste adequado.'),
    note('A receita precisa acompanhar o número. Duas equipes podem usar o rótulo “potência relativa média” e produzir quantidades diferentes se não descreverem a ordem das operações.'),
    source('Agregação atual: C3. Média e mediana espectrais: [4].'))

page('O que theta maior que beta significa hoje','17 / Uma descrição, três saídas',
    p('O código compara a média da porcentagem de theta com a de beta em olhos abertos e repete a comparação em olhos fechados. Ele não transforma essa observação em um percentual de chance.'),
    eq('Observado = theta > beta em olhos abertos\n            E theta > beta em olhos fechados'),
    table(['Dados fictícios','Olhos abertos','Olhos fechados'],[
        ['Theta','25%','30%'],['Beta','20%','18%'],['Theta maior?','Sim','Sim']],[.38,.31,.31]),
    p('Neste exemplo, o texto informa que a combinação foi observada nas duas etapas. Se uma comparação falhar, informa que não foi observada nas duas. Se a coleta for insuficiente, a comparação fica indisponível.'),
    p('<b>TBR</b> é a sigla em inglês para razão theta/beta: potência de theta dividida pela de beta. Quando o denominador é positivo, theta maior que beta equivale a uma razão maior que 1 para aquelas quantidades. A implementação atual exibe a observação, não um classificador clínico TBR.'),
    p('A descrição pode ser matematicamente correta e clinicamente pouco específica. <b>Especificidade</b>, que veremos adiante, envolve distinguir quem tem a condição de quem não tem; uma relação presente em muitos estados não resolve essa tarefa sozinha.'),
    note('A proposta é reduzir a importância interpretativa dessa frase e explicar os componentes medidos. O resultado ASRS continua independente, inclusive quando as duas observações parecem apontar para o mesmo lado.'),
    source('Implementação: C3 e C6. Limites clínicos da razão: [8].'))

page('Periódico e aperiódico: terreno e montanhas','18 / A ideia central do guia',
    p('<b>Periódico</b> descreve algo que se repete com um ritmo. No EEG, uma oscilação suficientemente organizada pode aparecer como um <b>pico</b> no espectro: uma elevação localizada em certas frequências.'),
    p('<b>Aperiódico</b> descreve atividade sem um único período regular predominante. No espectro, parte dessa atividade aparece como um fundo distribuído por muitas frequências, frequentemente com mais potência nas baixas frequências.'),
    fig('spectrum','Analogia visual: a curva tracejada é o terreno; a elevação localizada lembra uma montanha.',176),
    p('Imagine duas montanhas iguais construídas sobre terrenos diferentes. Medir apenas a altura em relação ao nível do mar mistura altura da montanha e elevação do terreno. Para saber o tamanho da montanha, precisamos considerar o chão ao redor.'),
    p('Da mesma forma, uma banda pode ter potência porque contém um pico, porque o fundo está mais alto ali, ou pelos dois motivos. Separar esses aspectos ajuda a descrever a origem matemática da mudança.'),
    note('O fundo aperiódico não é sinônimo de sujeira a apagar. Ele pode carregar informação fisiológica. O registro também contém interferências, e elas podem modificar o fundo estimado. O modelo não resolve essa distinção sozinho.'),
    source('Conceito e métodos existentes: [5]-[7].'))

page('A inclinação sem medo do logaritmo','19 / Por que aparece 1/f',
    p('Uma forma simples de representar o fundo é <b>S(f) = C / f^chi</b>. Aqui, S é potência por frequência; f é frequência; C controla o nível; e chi, pronunciado “qui”, controla a rapidez da queda. O símbolo ^ significa elevar a uma potência.'),
    eq('Exemplo com C = 100 e chi = 2:\nS(1) = 100; S(2) = 25; S(4) = 6,25; S(8) = 1,5625'),
    p('A frequência dobra e a potência cai quatro vezes nesse exemplo. <b>Logaritmo</b> é uma maneira de representar multiplicações como distâncias regulares. No log de base 10, 1 vira 0, 10 vira 1 e 100 vira 2.'),
    fig('log','A reta aparece quando os dois eixos usam escala logarítmica. No eixo linear, 1/f² é uma curva.',153),
    eq('log10 S(f) = b - chi × log10 f\nb = log10 C'),
    p('Nesse gráfico <b>log-log</b>, a inclinação da reta é -chi. Com chi = 2, a inclinação é -2. Um expoente maior produz queda mais íngreme no modelo. Não é correto desenhar essa reta em eixos lineares e chamar de mesma relação.'),
    note('O expoente é uma característica do espectro ajustado. Ele não vem com uma tradução automática do tipo “2 significa TDAH” ou “3 significa pior atenção”.'))

page('A conta de 2,87, passo a passo','20 / Theta/beta sem nenhum pico',
    p('Vamos usar um fundo ideal <b>S(f) = C/f²</b>, sem montanha theta e sem montanha beta. <b>Integrar</b> significa somar uma área sob a curva. É a versão contínua de somar pequenos retângulos de potência.'),
    fig('tbr','As regiões coloridas indicam theta e beta. Há potência nas bandas mesmo sem picos.',145),
    eq('Theta = C × (1/4 - 1/8) = 0,125 × C\nBeta = C × (1/13 - 1/30) = 0,04359 × C\nTheta/beta = 0,125 / 0,04359 = aproximadamente 2,87'),
    p('O C cancela porque multiplica os dois lados. Assim, uma razão acima de 1 pode aparecer sem um pico theta aumentado. O exemplo demonstra um problema de interpretação; não define o que acontece em toda pessoa.'),
    table(['Expoente do fundo','Razão theta/beta por área'],[
        ['1,0','0,829'],['1,5','1,545'],['2,0','2,868'],['2,5','5,299']],[.5,.5]),
    note('Valores calculados por integração contínua e pelas bordas indicadas. A soma discreta de bins e a preparação do app podem produzir números diferentes. A tabela não é uma escala de TDAH.'),
    source('Demonstração didática de um problema já estudado; não é descoberta do projeto. Referência [7].'))

page('Nível, inclinação, posição e largura','21 / Quatro mudanças diferentes',
    p('Dizer “a potência mudou” ainda deixa várias explicações possíveis. O fundo pode subir inteiro; a queda pode ficar mais inclinada; um pico pode crescer; ou pode se deslocar entre frequências.'),
    fig('offset','Exemplos de mudança de nível e inclinação em eixos log-log. Curvas sintéticas.',164),
    table(['Nome','O que muda','Analogia'],[
        ['Offset','Nível do fundo no modelo','Elevar o terreno inteiro.'],['Expoente','Rapidez da queda','Inclinar mais a encosta.'],['Frequência central','Posição do pico no eixo','Mover a montanha para o lado.'],['Largura','Espalhamento do pico','Transformar um pico estreito em morro largo.']],[.25,.42,.33]),
    p('No modelo simples, multiplicar todo o espectro pelo mesmo fator altera o nível e preserva uma razão entre bandas. Mudar a inclinação modifica frequências baixas e altas de maneira diferente e pode alterar bastante theta/beta.'),
    p('Um pico alfa mais largo também pode invadir frequências vizinhas. Por isso, ajustar o fundo não elimina toda ambiguidade. Precisamos olhar posição, largura e qualidade do ajuste.'),
    note('Proposta para pesquisa: medir poucos componentes claramente definidos, em vez de comprimir toda mudança em uma única razão. Mais números só ajudam quando sabemos o que cada um representa.'))

page('Como separar os componentes na prática','22 / Métodos que já existem',
    p('<b>FOOOF/specparam</b> é uma família de ferramentas que ajusta um modelo ao espectro. Na forma simples, estima um fundo e picos. <b>Ajustar</b> significa procurar parâmetros cuja curva se aproxime dos dados segundo um critério matemático.'),
    eq('log10 PSD = fundo aperiódico + picos ajustados'),
    p('Essa soma é feita na escala logarítmica do modelo. Um pico pode ser descrito por uma curva em forma de sino, chamada <b>gaussiana</b>. Sua altura nessa escala não é, automaticamente, potência em µV².'),
    p('<b>IRASA</b> é outra abordagem: reamostra o sinal usando fatores diferentes para ajudar a distinguir a parte fractal das oscilações. Reamostrar significa representar a sequência em outra taxa. O método combina esses resultados segundo uma receita própria.'),
    p('IRASA foi publicado online em 2015, com volume de 2016. O trabalho de FOOOF é de 2020. Portanto, separar fundo e picos é conhecimento existente. Nosso trabalho possível é adaptar, comparar e validar a aplicação ao sinal disponível.'),
    h('O que a ferramenta entrega?'),
    p('Ela fornece estimativas: expoente, nível e características dos picos, conforme o método. Não entrega necessariamente duas ondas temporais puras, uma cerebral periódica e outra cerebral aperiódica, perfeitamente separadas de todos os artefatos.'),
    note('Começar por uma implementação de referência fora do app permite verificar resultados antes de criar uma versão para celular. Também permite registrar a versão e as configurações usadas.'),
    source('Métodos originais: IRASA [5] e parametrização [6].'))

page('Quando a curva bonita engana','23 / Erro de ajuste e sobreajuste',
    p('<b>Erro de ajuste</b> resume a diferença entre o modelo e os pontos observados. Um erro pequeno é desejável, mas não prova que a explicação do modelo seja fisiologicamente correta.'),
    fig('fit','Curva sintética com oscilações de ruído sobre um pico. Nem toda ondulação merece um pico no modelo.',158),
    p('<b>Sobreajuste</b> acontece quando um modelo flexível acompanha detalhes acidentais. Imagine desenhar uma estrada que faz uma curva para desviar de cada pedrinha. Ela se adapta perfeitamente àquela fotografia, mas perde utilidade quando as pedrinhas mudam.'),
    p('<b>R²</b> é um indicador de ajuste frequentemente apresentado. Um valor alto pode coexistir com parâmetros instáveis. Devemos verificar se o expoente e os picos continuam semelhantes com pequenos ajustes razoáveis na análise e em novas sessões.'),
    p('Também existe um modelo com <b>joelho</b>, uma mudança de curvatura no fundo. Ele oferece mais flexibilidade, mas exige informação suficiente para estimar seus parâmetros. Não devemos escolher a versão mais complicada só porque existe.'),
    p('A posição frontal, a faixa limitada, filtros e músculos podem dificultar a estimativa. Se não houver um pico confiável, o resultado adequado é “não estimável”. Forçar o maior ponto a receber o nome de pico cria informação artificial.'),
    note('A proposta inclui critérios de ajuste, estabilidade e resultado ausente. Um algoritmo que sempre devolve um número pode parecer completo e ainda assim ser menos honesto sobre a medição.'))

page('Uma razão ajustada: hipótese para comparar','24 / A fórmula sugerida e seus limites',
    p('Uma candidata experimental é comparar a razão observada com a razão que o próprio fundo ajustado produziria nas mesmas bandas. Isso deriva de ideias existentes; não é apresentada como invenção científica.'),
    eq('D = ln(theta/beta observado)\n    - ln(theta/beta previsto pelo fundo)'),
    p('<b>ln</b> é o logaritmo natural. Para esta conta, basta entender: ln(1) = 0; números acima de 1 têm ln positivo; números entre 0 e 1 têm ln negativo. Subtrair os logaritmos equivale a tomar o logaritmo da divisão entre as duas razões.'),
    table(['Exemplo fictício','Razão observada','Razão do fundo','D'],[
        ['Só fundo, ajuste perfeito','2,87','2,87','0'],['Observado 50% maior','4,305','2,87','ln(1,5) = 0,405'],['Observado menor','1,435','2,87','ln(0,5) = -0,693']],[.34,.22,.22,.22]),
    p('D positivo significa razão observada maior que a prevista pelo fundo. D zero significa igualdade. Nenhum desses sinais significa TDAH. A conta também continua comprimindo alterações de theta, beta e do ajuste em um único número.'),
    p('Para testar, usar a mesma escala, bordas e agregação nos dois termos; rejeitar ajustes inadequados; comparar com o TBR bruto e com componentes separados. Se D apenas amplificar erros ou não acrescentar informação, descartamos a hipótese.'),
    note('Esta fórmula não está no app, não possui ponto de corte clínico proposto e não deve alterar o ASRS. É um experimento de análise, com possibilidade explícita de resultado negativo.'))

page('O pico alfa de cada pessoa','25 / Frequência alfa individual',
    p('<b>Frequência alfa individual</b>, ou IAF na sigla inglesa, é uma estimativa da posição característica de um pico alfa identificável. Ela pode ser mais informativa que dizer apenas “somamos tudo de 8 a 13 Hz”.'),
    fig('alpha','Dois picos sintéticos em posições diferentes. O desenho não estabelece uma direção de TDAH.',164),
    p('Pense em uma estação de rádio. Saber que ela fica dentro de uma faixa é diferente de localizar sua frequência central. Mas, se só há chiado, escolher o ponto mais alto do chiado não identifica uma estação real.'),
    p('Uma opção é estimar o centro do pico ajustado. Outra é o <b>centro de gravidade</b>: uma média das frequências, dando mais peso àquelas com maior componente alfa estimado. <b>Peso</b> aqui significa influência na média, não massa física.'),
    eq('Centro de gravidade = soma(frequência × peso) / soma(pesos)'),
    p('Com dois picos, essa média pode cair entre eles. Portanto, centro de gravidade e posição do maior pico não são necessariamente a mesma medida. O método deve dizer qual foi usado.'),
    note('Hoje o app soma a banda fixa. A proposta é testar IAF apenas quando houver sinal adequado e pico identificável. Ausência de pico frontal confiável não equivale a TDAH e não torna automaticamente toda a coleta inválida.'),
    source('Estimativa de pico e parametrização: [6].'))

page('O que muda quando a pessoa fecha os olhos','26 / Reatividade alfa',
    p('<b>Reatividade</b> é mudança de uma medida entre condições. O app já compara alfa de olhos fechados com alfa de olhos abertos. A medida atual usa mudança percentual das somas espectrais internas.'),
    eq('Mudança atual = (alfa fechado - alfa aberto)\n                / alfa aberto × 100'),
    p('Se alfa passa de 10 para 20 unidades, a mudança é +100%. Se volta de 20 para 10, é -50%. Percentuais dependem do ponto de partida, por isso aumentos e quedas inversos não são simétricos.'),
    p('Uma alternativa para comparar é expressar a razão em <b>decibéis</b>, abreviados dB. Aqui, dB é uma escala logarítmica de razão de potências; não significa volume de som do celular.'),
    eq('Reatividade em dB = 10 × log10(alfa fechado/alfa aberto)\nDobrar: aproximadamente +3,01 dB\nReduzir à metade: aproximadamente -3,01 dB'),
    p('Hoje o texto do relatório usa limites de ±20% para dizer que alfa aumentou, diminuiu ou ficou semelhante. São regras de descrição implementadas, não limites clínicos universais. A proposta é estudar precisão e repetibilidade antes de transformar pequenas diferenças em conclusões.'),
    p('A resposta pode depender do local de medição e da qualidade. Não observar aumento no canal frontal não prova que a pessoa não tem resposta em outras regiões, nem que tem TDAH.'),
    note('A pergunta útil é “quanto mudou nesta montagem e com que confiança?”. O número precisa do contexto da coleta e da qualidade do sinal.'),
    source('Estado atual: C3 e C6. Estudo de aparelho e resposta alfa: [11].'))

page('Adicionar uma tarefa de atenção','27 / A hipótese de resposta dinâmica',
    p('<b>Dinâmica</b> significa mudança ao longo do tempo ou entre condições. Em vez de perguntar apenas como o sinal está parado, podemos investigar como ele muda quando a pessoa precisa responder a estímulos.'),
    fig('task','Protocolo candidato; ainda não implementado como estudo validado no app.',162),
    p('Um <b>estímulo</b> é algo apresentado: uma figura, letra ou som. Uma tarefa <b>go/no-go</b>, por exemplo, pede resposta em alguns estímulos e ausência de resposta em outros. Isso cria medidas de tempo, omissões e respostas inadequadas.'),
    p('O repouso antes fornece uma referência; a tarefa impõe uma demanda; a recuperação mostra o que acontece depois. Comparar essas fases pode reduzir parte das diferenças estáveis entre pessoas. Ainda permanecem sono, aprendizagem, motivação e montagem.'),
    p('<b>Hipótese:</b> a mudança de algumas características do EEG, combinada ao desempenho, pode ser mais informativa que o repouso isolado. Estudos exploratórios motivam testar essa pergunta; não estabelecem desempenho para o BrainLink Lite.'),
    note('Uma tarefa feita no aplicativo não se torna equivalente a um teste comercial ou instrumento validado por ter aparência semelhante. Regras, estímulos, duração e interpretação precisam ser descritos e avaliados.'),
    source('Pista de EEG frontal em tarefa: [12]. Contraponto clínico: [13].'))

page('Como medir o desempenho da tarefa','28 / Tempo, erros e variabilidade',
    p('<b>Tempo de resposta</b> é o intervalo entre apresentar o estímulo e registrar a ação. <b>Omissão</b> é deixar de responder quando a regra pedia. <b>Comissão</b> é responder quando a regra pedia para não responder.'),
    table(['Medida','Exemplo fictício','Conta'],[
        ['Omissões','8 alvos sem resposta entre 100 alvos','8/100 = 8%'],['Comissões','5 respostas entre 50 não alvos','5/50 = 10%'],['Tempo típico','Respostas corretas ordenadas','Mediana dos tempos'],['Variabilidade','Quão diferentes são os tempos','Desvio padrão ou medida robusta']],[.25,.44,.31]),
    p('Uma pessoa pode ter média de 500 milissegundos com respostas quase sempre próximas disso. Outra pode alternar 200 e 800 milissegundos e ter a mesma média. A <b>variabilidade</b> mostra essa diferença de consistência.'),
    eq('CV dos tempos = desvio padrão / média\nExemplo: 100 ms / 500 ms = 0,20 = 20%'),
    p('<b>CV</b> é coeficiente de variação. Ele relaciona o espalhamento ao tamanho da média. Não deve ser interpretado sem verificar antecipações, falhas de toque, quantidade de respostas e critérios de exclusão.'),
    p('Para EEG, uma mudança simples pode ser “característica durante a tarefa menos característica no repouso”. Antes de medir, é preciso decidir qual característica, qual trecho e qual comparação responderão à pergunta.'),
    note('Erros de tarefa não pertencem exclusivamente ao TDAH. Pessoas cansadas, ansiosas ou sem entender a regra também podem errar. A pesquisa deve incluir participantes com queixas semelhantes, além de controles saudáveis.'))

page('Por que milissegundos exigem outra preparação','29 / Sincronização e ERP',
    p('Há uma diferença entre comparar blocos de um minuto e medir uma resposta cerebral 300 milissegundos depois de cada estímulo. A segunda pergunta exige saber com precisão quando o estímulo apareceu e quando cada amostra foi captada.'),
    p('<b>ERP</b> é a sigla inglesa para potencial relacionado a evento. Em geral, alinha-se o EEG a muitos eventos e resume-se o sinal para estudar padrões associados a eles. N2 e P3 são nomes usados para alguns componentes dessa resposta.'),
    eq('Tempo relevante = instante da amostra - instante do evento'),
    p('Imagine fotografar o momento em que alguém bate palmas, mas com câmeras que atrasam de maneira variável. Se você alinhar as fotos apenas pelo horário em que chegaram ao computador, o movimento parecerá borrado.'),
    p('Hoje, o horário do lote marca seu fechamento no Android. Ele não informa diretamente o instante de cada amostra no chip. A tela também pode ter atraso entre o comando do software e a aparição real do estímulo.'),
    h('O que seria necessário?'),
    p('Medir os atrasos, sua variação, o início real dos estímulos e a correspondência temporal com o EEG. Isso pode exigir instrumentação adicional. <b>Instrumentação</b> é usar ferramentas e medições específicas para verificar o sistema físico.'),
    note('Prioridade proposta: começar por mudanças em blocos. Só estudar ERP depois de demonstrar sincronização adequada. A disponibilidade de uma fórmula de ERP não resolve a falta de relógios alinhados.'),
    source('Limite temporal observado no código: C1-C2 e C4.'))

page('ASRS: de onde sai a possibilidade aumentada','30 / O questionário e sua pontuação',
    p('O <b>ASRS v1.1 de seis perguntas</b> é um instrumento de rastreio de sintomas em adultos. <b>Rastreio</b> significa procurar indícios que podem justificar avaliação mais aprofundada. A resposta descreve a percepção da pessoa, considerando o período orientado pelo instrumento.'),
    p('No app, as respostas recebem de 0 a 4 pontos: nunca, raramente, algumas vezes, frequentemente e muito frequentemente. As seis respostas são somadas. O máximo é 24 e o corte implementado é 14.'),
    eq('Exemplo fictício: 3 + 2 + 3 + 2 + 3 + 2 = 15 pontos\n15 >= 14: ponto de corte atingido'),
    table(['Soma','Faixa usada no código'],[
        ['0 a 9','Faixa inferior de rastreio'],['10 a 13','Próximo ao ponto de corte'],['14 a 17','Faixa de rastreio atingida'],['18 a 24','Faixa superior de rastreio']],[.28,.72]),
    p('Essa regra de soma consta na atualização oficial de pontuação de 28/02/2024. Ela é diferente do método antigo de contar respostas em determinadas caixas. Não se deve misturar as duas receitas.'),
    p('O EEG, a qualidade e o índice de atenção do fabricante não entram nessa soma. Um valor de 15/24 também não significa 62,5% de chance. É uma pontuação na escala; transformar em probabilidade exige outra validação.'),
    note('A mensagem pode continuar sendo “possibilidade aumentada no ASRS”, com origem identificada. Abaixo do corte não significa exclusão de TDAH; acima dele não estabelece diagnóstico.'),
    source('Fonte oficial de pontuação [9]; implementação C5. O desempenho clínico do produto completo não decorre apenas de usar a conta correta.'))

page('O que o profissional recebe hoje','31 / Relatório e limites do arquivo',
    p('O exportador atual cria arquivos <b>HTML</b> e <b>TXT</b>. HTML é um documento que o navegador apresenta com formatação; TXT é texto simples. Este guia em PDF é um material separado e não significa que o app passou a exportar PDF nativamente.'),
    table(['Parte do relatório atual','O que comunica'],[
        ['Identificação da sessão','Data, duração e origem da coleta.'],['Qualidade','Nota de contato/continuidade e aproveitamento de épocas.'],['Índices do fabricante','Médias disponíveis, identificadas como proprietárias.'],['EEG descritivo','Percentuais por banda em cada fase, mudança alfa e comparação theta/beta.'],['ASRS','Respostas, pontuação, faixa e orientação de rastreio.']],[.34,.66]),
    p('Quando o EEG é insuficiente, as bandas não são exibidas como se fossem válidas. A origem do ASRS continua separada. O texto histórico sobre theta/beta pode, porém, incentivar uma leitura maior do que os dados sustentam; a revisão de linguagem deve tornar seu alcance inequívoco.'),
    p('O relatório não contém o traçado bruto completo para recalcular tudo depois. <b>Reprocessar</b> significa voltar às amostras e aplicar novamente uma análise, talvez corrigida. Um resumo final não substitui esse arquivo de pesquisa.'),
    note('Proposta: permitir um registro técnico reprocessável, com amostras, qualidade, tempos, modelo do aparelho, montagem e versão do método. O acesso e a retenção desses dados precisam fazer parte do desenho do estudo.'),
    source('Exportação e persistência: C1, C4 e C6.'))

page('Hoje e proposta: aquisição e matemática','32 / Comparação direta',
    table(['Tema','Hoje, verificado no código','Melhoria proposta e motivo'],[
        ['Taxa','Configuração 512 Hz; teste de cadência por lote.','Homologar no aparelho e distinguir atraso de perda; evita eixo de frequência errado e rejeição indevida.'],
        ['Montagem e ganho','Modelo de conversão ThinkGear presumido.','Registrar modelo, referência, filtros e ganho; dá significado à amplitude.'],
        ['Tempo aproveitado','Conta épocas aceitas e rejeitadas.','Medir segundos únicos e continuidade; evita tratar sobreposição como tempo novo.'],
        ['Potência','Soma magnitude da FFT ao quadrado.','Normalizar PSD e integrar bandas; melhora unidades e comparabilidade.'],
        ['Janelas','1 segundo, passo de 0,5 segundo.','Comparar 1, 2, 4 e 8 segundos; equilibrar detalhe espectral e mudança temporal.'],
        ['Agregação','Média dos percentuais por época.','Comparar alternativas com objetivo explícito; evita resumos ambíguos.']],[.19,.35,.46]),
    p('Essas mudanças são principalmente de <b>engenharia de medição</b>: fazer com que o número represente aquilo que diz representar. Algumas podem preservar os percentuais atuais; outras podem mudar o resultado ao alterar a receita.'),
    note('Um ajuste técnico deve ser testado por fidelidade e estabilidade. Escolher a configuração porque deu a separação clínica mais bonita no conjunto de teste contamina a avaliação.'))

page('Hoje e proposta: interpretação e pesquisa','33 / Comparação direta',
    table(['Tema','Hoje','Proposta e pergunta a responder'],[
        ['Fundo','Não separado do espectro.','Estimar fundo e picos: melhora a interpretação e a estabilidade?'],
        ['Alfa','Banda fixa e mudança percentual.','Comparar pico individual e reatividade em dB, quando estimáveis.'],
        ['Theta/beta','Observação theta > beta nas duas etapas.','Contextualizar e comparar com componentes separados; não assumir marcador universal.'],
        ['Condições','Olhos abertos e fechados.','Investigar resposta a tarefa e recuperação, com regras padronizadas.'],
        ['TDAH','Rastreio ASRS calculado pelas respostas.','Testar se EEG acrescenta informação frente a avaliação independente.'],
        ['Arquivo','Resumo HTML/TXT.','Guardar pesquisa reprocessável e metadados, com finalidade e acesso definidos.']],[.19,.34,.47]),
    p('<b>Metadados</b> são informações sobre a coleta: quando, como, com qual aparelho e qual versão do método. Sem eles, duas medidas diferentes podem parecer comparáveis apenas porque usam o mesmo nome.'),
    p('A separação periódica/aperiódica é uma técnica existente. A eventual contribuição do projeto estará na implementação confiável, no protocolo viável e na evidência obtida com o público e o equipamento usados.'),
    note('Não há garantia de que uma característica mais bem medida seja útil para TDAH. Um resultado científico válido pode mostrar que o EEG não acrescenta ganho ao rastreio nessa configuração.'))

page('Uma sessão fictícia, acompanhada do início','34 / Exemplo completo - parte 1',
    p('Conheça Ana, personagem inventada apenas para acompanhar os números. Ela usa o aparelho na montagem documentada e realiza 60 segundos de olhos abertos e 60 de olhos fechados. Nada nesta história representa um diagnóstico real.'),
    p('Suponha que uma fase forneça exatamente 60 segundos contínuos a 512 Hz, sem descarte na borda. Teremos 30.720 amostras. Com janelas de um segundo e passo de meio segundo:'),
    eq('Número de janelas = 1 + (60 - 1) / 0,5 = 119'),
    p('Na prática, atrasos, lotes de transição e perdas podem mudar esse total. Vamos imaginar que a análise aceite 100 das 119 épocas em olhos abertos e 90 das 119 em olhos fechados.'),
    table(['Condição fictícia','Aceitas','Aproveitamento'],[
        ['Olhos abertos','100 de 119','84,0%'],['Olhos fechados','90 de 119','75,6%']],[.44,.26,.30]),
    p('Ambas passam nos critérios atuais de pelo menos 20 épocas e 50% de aceitação. Isso permite descrição técnica segundo as regras do app. Não prova ausência completa de artefatos.'),
    p('Agora imagine uma piscada relativamente pequena que passa pelos limites. Ela ainda pode alterar o espectro. Por isso propomos comparar a rejeição automática com anotações de eventos e exemplos controlados.'),
    note('Pergunta de conferência: 100 épocas aceitas equivalem a 100 segundos limpos? Não. Elas se sobrepõem, e o tempo único depende de onde cada uma está. Essa é uma melhoria de registro proposta.'))

page('O mesmo relatório, lido com cuidado','35 / Exemplo completo - parte 2',
    p('Continuando a sessão fictícia, suponha que o resumo atual apresente os valores abaixo. São porcentagens inventadas, não o resultado de um arquivo EEG de Ana.'),
    table(['Banda','Olhos abertos','Olhos fechados'],[
        ['Delta','20%','15%'],['Theta','30%','25%'],['Alfa','25%','40%'],['Beta','25%','20%'],['Total','100%','100%']],[.4,.3,.3]),
    p('Theta é maior que beta nas duas fases. O código pode registrar essa observação. Ainda não sabemos quanto disso veio do fundo, de um pico ou de artefatos. E porcentagem alfa maior não basta para calcular a mudança de potência absoluta.'),
    p('Agora suponha um pipeline futuro calibrado, aplicado às mesmas condições, que estime alfa em 8 e 16 µV². Esses valores hipotéticos são uma informação adicional, não deduzida da tabela de percentuais.'),
    eq('Mudança alfa = (16 - 8) / 8 × 100 = +100%\nReatividade alfa = 10 × log10(16/8) = +3,01 dB'),
    p('Ana também responde ao ASRS e soma 15 pontos. O corte foi atingido pelo questionário. Se um ajuste espectral futuro atribuir boa parte de theta ao fundo, isso não subtrai pontos do ASRS nem “desfaz” o resultado.'),
    note('Leitura adequada: há um resultado de rastreio que pede contextualização profissional e há uma descrição técnica da sessão. Para transformar características EEG em informação clínica adicional, precisamos do estudo descrito nas próximas páginas.'))

page('Como seria um modelo combinado','36 / Aprender com exemplos rotulados',
    p('Um <b>modelo preditivo</b> relaciona entradas a um resultado de interesse. As entradas podem incluir ASRS, algumas características EEG e medidas da tarefa. <b>Característica</b>, ou feature, é um número definido a partir dos dados, como expoente ou tempo mediano.'),
    fig('models','Comparações planejadas. O resultado de referência precisa vir de avaliação independente.',162),
    p('<b>Rótulo</b> é o resultado usado para ensinar e avaliar o modelo, por exemplo uma classificação clínica obtida segundo protocolo. Se usarmos o próprio ASRS como rótulo, podemos estudar associação com sintomas; isso não demonstra ganho diagnóstico além do ASRS.'),
    p('Uma <b>regressão logística</b> combina entradas para estimar uma probabilidade entre 0 e 1. Seus <b>coeficientes</b> são pesos aprendidos a partir dos dados, e não números escolhidos para dar uma aparência científica.'),
    eq('Entradas -> combinação com pesos aprendidos -> estimativa'),
    p('<b>Regularização</b> limita a complexidade dos pesos para reduzir ajustes excessivos. Começar com poucas características e um método simples facilita entender falhas e comparar com o questionário sozinho.'),
    note('Não há pesos definidos nem modelo clínico treinado neste guia. A qualidade do sinal deve decidir se uma medida pode ser usada, sem virar um bônus de “pontos TDAH”.'))

page('Como evitar uma acurácia de fachada','37 / Treino, teste e vazamento',
    p('<b>Treino</b> é o conjunto de exemplos usado para ajustar o modelo. <b>Teste</b> é um conjunto reservado para avaliar seu comportamento em dados que não participaram dessas decisões.'),
    fig('leak','Separação por participante: nenhuma janela ou visita da mesma pessoa deve atravessar essa fronteira.',163),
    p('<b>Vazamento de informação</b> acontece quando o processo usa, mesmo indiretamente, informação que deveria estar reservada à avaliação. Um caso frequente é colocar janelas da mesma pessoa no treino e no teste.'),
    p('Analogia: um aluno treina com trechos da prova e depois é elogiado por reconhecer as mesmas frases. O resultado mede familiaridade com aquela prova, não domínio do assunto em perguntas novas.'),
    p('A separação precisa acontecer por pessoa, incluindo todas as suas visitas. Escolher características, preencher dados faltantes, normalizar e ajustar parâmetros deve usar apenas o treino. <b>Validação aninhada</b> organiza uma divisão interna para escolhas e uma externa para avaliação.'),
    p('Uma <b>validação externa</b> usa outro contexto ou amostra para testar um modelo já fixado. Treinar tudo de novo no novo conjunto responde a outra pergunta. Precisamos registrar quais decisões foram feitas antes de ver o resultado final.'),
    note('Um estudo recente com EEG de TDAH mostrou queda importante quando a separação passou de janelas para participantes. Muitos pedaços de poucas pessoas não substituem muitas pessoas independentes.'),
    source('Exemplo metodológico: [14].'))

page('Sensibilidade, especificidade e os quatro resultados','38 / Como contar acertos e erros',
    p('Para explicar, imagine uma referência clínica e uma saída experimental positiva ou negativa. O modelo pode acertar ou errar nos dois grupos. Os números abaixo são fictícios.'),
    table(['Resultado do modelo','Referência: TDAH','Referência: sem TDAH'],[
        ['Positivo','40 verdadeiros positivos','10 falsos positivos'],['Negativo','10 falsos negativos','40 verdadeiros negativos']],[.38,.31,.31]),
    p('<b>Verdadeiro positivo</b>: o modelo sinaliza e a referência confirma a condição. <b>Falso positivo</b>: o modelo sinaliza em alguém sem a condição pela referência. Os negativos seguem a mesma lógica.'),
    eq('Sensibilidade = 40 / (40 + 10) = 80%\nEspecificidade = 40 / (40 + 10) = 80%\nAcurácia = (40 + 40) / 100 = 80%'),
    p('<b>Sensibilidade</b> é a proporção identificada entre quem tem a condição. <b>Especificidade</b> é a proporção corretamente negativa entre quem não tem. <b>Acurácia</b> é a proporção total de acertos; pode esconder desequilíbrio entre os grupos.'),
    p('<b>AUC</b> resume como um escore ordena positivos e negativos ao variar o limite de decisão. Um valor maior indica melhor ordenação naquele conjunto, mas não garante que as probabilidades sejam corretas nem que o exame ajude na prática.'),
    note('Também precisamos de intervalos de incerteza. Acertar 8 de 10 e acertar 800 de 1000 dão 80%, mas a precisão da estimativa é muito diferente. Nenhum dos valores desta página é desempenho medido do BrainLink.'))

page('80% de sensibilidade não é 80% de chance','39 / A importância da população',
    p('<b>Prevalência</b> é a proporção de pessoas com a condição na população considerada. Ela afeta a interpretação de um resultado positivo. Vamos manter sensibilidade e especificidade hipotéticas de 80%.'),
    table(['Em 1.000 pessoas','Prevalência 5%','Prevalência 25%'],[
        ['Com a condição','50','250'],['Verdadeiros positivos (80%)','40','200'],['Sem a condição','950','750'],['Falsos positivos (20%)','190','150'],['Todos os positivos','230','350'],['Condição entre os positivos','40/230 = 17,4%','200/350 = 57,1%']],[.48,.26,.26]),
    p('A proporção da última linha é o <b>valor preditivo positivo</b>, ou VPP. Quando existem muitas pessoas sem a condição, mesmo uma taxa moderada de falso positivo pode gerar muitos resultados positivos incorretos.'),
    eq('VPP = verdadeiros positivos / todos os positivos'),
    p('Analogia: um alarme que toca para bicicletas e às vezes para carrinhos terá resultados diferentes em um estacionamento de bicicletas e em um depósito cheio de carrinhos. A população atendida muda a interpretação do toque.'),
    p('Por isso, testar metade de casos e metade de controles e divulgar apenas “80% de acerto” não autoriza dizer que uma pessoa positiva tem 80% de chance. Precisamos avaliar a população e o uso pretendidos.'),
    note('As prevalências de 5% e 25% são escolhas didáticas, não estimativas locais do projeto. A tabela ilustra uma conta; não valida um classificador.'))

page('O EEG acrescentou algo de verdade?','40 / Ganho, calibração e cobertura',
    p('A comparação principal não é “nosso modelo acerta mais do que um sorteio?”. É “ele acrescenta informação útil ao que já sabemos pelo ASRS e pelo contexto definido no protocolo?”.'),
    p('<b>Ganho incremental</b> é essa melhora adicional. Se o questionário sozinho tem o mesmo desempenho do modelo com EEG, o sensor pode não estar acrescentando utilidade para aquela decisão, apesar de medir um sinal interessante.'),
    p('<b>Calibração de probabilidade</b> pergunta se as estimativas combinam com a frequência real dos resultados. Entre muitos participantes semelhantes aos quais o modelo atribui 30%, esperaríamos aproximadamente 30% positivos pela referência, dentro da incerteza do estudo.'),
    p('Isso é diferente da calibração física em microvolts. Uma cuida da escala da medição; a outra cuida do significado das probabilidades previstas.'),
    p('<b>Cobertura</b> é a proporção de pessoas para quem o sistema consegue produzir uma saída utilizável. Se o método se abstém em 40 de 100 pessoas e acerta bastante nas 60 restantes, precisamos divulgar os dois fatos.'),
    eq('Cobertura = resultados utilizáveis / participantes avaliados'),
    p('<b>Benefício prático</b> depende do uso: a informação muda uma decisão de maneira útil, considerando os erros? Uma pequena melhora na ordenação não garante vantagem para a pessoa ou o profissional.'),
    note('O estudo deve registrar casos inconclusivos e grupos em que o método falha. Esconder esses participantes para elevar acurácia dá uma visão incompleta do produto.'),
    source('Desenho recomendado: avaliação independente e limites apontados em [8].'))

page('Uma medida repetível ainda pode estar errada','41 / Confiabilidade e fatores de confusão',
    p('<b>Repetibilidade</b> é obter resultados próximos ao repetir a medição em condições semelhantes. <b>Validade</b> é a medida representar adequadamente aquilo que pretende representar. Uma balança sempre cinco quilos acima do correto pode ser muito repetível e estar errada.'),
    p('No projeto, queremos estudar repetição na mesma sessão, no mesmo dia e em dias diferentes. Cada comparação responde a uma pergunta: ruído imediato, reposicionamento e variação do estado da pessoa, por exemplo.'),
    table(['Fator','Por que registrar'],[
        ['Sono e cansaço','Podem mudar estado, desempenho e características do EEG.'],['Medicação e cafeína','Podem estar associadas às medidas e ao grupo estudado.'],['Horário e ambiente','Alteram condições da coleta e da tarefa.'],['Montagem e operador','Podem mudar contato, amplitude e quantidade de artefatos.']],[.35,.65]),
    p('<b>Fator de confusão</b> é algo que pode explicar parte da associação que atribuímos ao fenômeno de interesse. Se um grupo foi medido descansado pela manhã e outro exausto à noite, fica difícil atribuir a diferença ao diagnóstico.'),
    p('Uma linha de base pessoal compara a pessoa consigo mesma e reduz algumas diferenças entre indivíduos. Ela não elimina mudanças de sono, contato ou medicação. Também não define, sozinha, o que é clinicamente normal.'),
    note('As condições devem ser registradas, não alteradas por conta própria para “melhorar” o teste. O protocolo de pesquisa e os profissionais responsáveis definem como lidar com elas.'))

page('O que aprender com dados públicos','42 / Começar sem inventar desempenho',
    p('Um <b>dataset</b> é um conjunto organizado de dados. Bases públicas permitem testar programas e hipóteses antes de coletar novos participantes. A pergunta precisa combinar com aquilo que a base realmente contém.'),
    table(['Base identificada','Uso possível','Limite principal'],[
        ['Aparelhos de consumo / Lee 2026','Testar espectro, resposta alfa e artefatos.','Inclui BrainLink Pro e adultos saudáveis; não valida Lite para TDAH.'],
        ['ADHD121','Estudar generalização e efeito de usar poucos canais.','Crianças, tarefa e montagem multicanal diferentes.'],
        ['OpenNeuro adulto','Explorar tarefas e associação com autorrelato.','Checklist não equivale a diagnóstico independente; conferir sobreposição entre versões.']],[.27,.34,.39]),
    p('<b>Generalização</b> é o comportamento do método em pessoas ou condições novas. O resultado de crianças com um aparelho de laboratório não se transfere automaticamente para adultos com um headset frontal.'),
    p('Selecionar Fp1 de uma base não reproduz necessariamente a derivação bipolar do Lite. Referência, ganho, filtros e tarefa fazem parte do sinal. O rótulo do arquivo também precisa ser entendido: sintoma, rastreio e diagnóstico são coisas diferentes.'),
    note('Neste levantamento, identificamos bases e documentação. Não baixamos e treinamos modelos nos grandes conjuntos EEG. Esse trabalho ainda é um experimento a executar, com escolhas registradas antes de avaliar o teste.'),
    source('Bases e estudos: [10]-[11], [15]-[16].'))

page('Uma ordem prática para melhorar o projeto','43 / Entregas e critérios de avanço',
    table(['Passo','Entrega concreta','Como saber se avançou'],[
        ['1. Homologar aquisição','Registro do aparelho, montagem, taxa, ganho, filtros e transporte.','Contagens, tempo e amplitudes coerentes com medições de referência.'],
        ['2. Conferir matemática','PSD de referência, testes com sinais conhecidos e comparação de janelas.','Erro técnico quantificado; unidades e receita documentadas.'],
        ['3. Estudar repetição','Sessões repetidas e análise de perdas/artefatos.','Estabilidade suficiente e cobertura aceitável para a pergunta.'],
        ['4. Comparar características','Fundo, picos, alfa e alternativas, com poucas escolhas.','Estimativas robustas; critérios para não estimável.'],
        ['5. Investigar tarefa','Protocolo fixo, tempos e desempenho verificados.','Dados confiáveis e tolerabilidade documentada.'],
        ['6. Testar utilidade','ASRS versus modelos ampliados, com referência independente.','Ganho relevante fora da amostra, com calibração e cobertura.']],[.21,.40,.39]),
    p('<b>Homologar</b>, neste guia, significa verificar tecnicamente as características do sistema usado. Não significa obter automaticamente registro regulatório ou autorização clínica.'),
    note('A prioridade sugerida é resolver aquisição e escala antes de multiplicar índices. Depois, usar evidência para decidir quais características merecem permanecer. Uma hipótese sem ganho deve poder sair do plano.'))

page('Onde a Psicologia pode contribuir','44 / Pessoas, instrumentos e contexto',
    p('A participação da Psicologia pode ajudar a transformar uma coleta tecnicamente possível em um estudo compreensível e bem conduzido. Os papéis precisam acompanhar a formação, supervisão e responsabilidade de cada participante da equipe.'),
    table(['Frente','Contribuição possível'],[
        ['Compreensão','Verificar se instruções e resultados são entendidos como pretendido.'],['Protocolo','Discutir tarefa, carga, cansaço, aprendizagem e contexto das respostas.'],['Instrumentos','Conferir aplicação, linguagem, atribuição e método de pontuação.'],['Pesquisa com pessoas','Apoiar recrutamento, entrevistas e acompanhamento sob supervisão.'],['Interpretação','Contextualizar sintomas, prejuízos e alternativas explicativas.']],[.31,.69]),
    p('<b>Consentimento informado</b> é a compreensão e aceitação da participação nas condições explicadas. <b>TCLE</b> é o documento de consentimento livre e esclarecido usado no contexto apropriado. O estudo deve esclarecer finalidade, procedimentos, dados coletados e limites dos resultados.'),
    p('Aprovação de bolsa PROBIC e aprovação do protocolo com participantes respondem a questões diferentes. A equipe e a instituição precisam confirmar a tramitação aplicável antes do recrutamento e da coleta de pesquisa.'),
    p('No desenho dos dados, usar identificadores de pesquisa, definir acesso e tempo de guarda e evitar incluir informações pessoais desnecessárias. Isso também melhora organização e rastreabilidade.'),
    note('Um estudante pode contribuir muito para o projeto dentro de atividades supervisionadas. Sua participação não deve ser descrita como autorização automática para emitir diagnóstico ou validar um índice experimental.'))

page('Outras contas: quando vale explorar','45 / Complexidade sem mágica',
    p('<b>Complexidade</b> pode descrever irregularidade ou diversidade de um sinal, mas não existe uma única conta que capture tudo isso. Diferentes medidas respondem a perguntas diferentes.'),
    p('Uma opção é a <b>entropia espectral</b>: ela resume quão distribuída está a potência entre os bins. Se quase toda a potência estiver concentrada em poucos bins, a medida tende a ser menor. Se estiver mais espalhada, tende a ser maior.'),
    eq('p[k] = potência do bin / potência total\nH = - soma(p[k] × ln(p[k])) / ln(K)'),
    p('<b>K</b> é a quantidade de bins usados; <b>p[k]</b> é a participação de cada um. Pela convenção matemática, um termo com participação zero contribui com zero. Essa normalização permite uma escala de 0 a 1 sob as condições da fórmula.'),
    p('Analogia: uma caixa quase inteira de uma única cor tem baixa diversidade; uma caixa distribuída entre muitas cores tem diversidade maior. Isso não informa se a caixa é melhor. Da mesma forma, ruído pode espalhar potência e aumentar a entropia.'),
    p('A faixa de frequência, o tamanho da janela e o processamento afetam o valor. Entropia espectral não é a mesma coisa que entropia de permutação ou multiescala, que analisam outras propriedades.'),
    note('Esta é uma hipótese secundária. Só vale adicioná-la se trouxer ganho independente após controlar qualidade e escolhas analíticas. Calcular centenas de índices em poucas pessoas aumenta a chance de encontrar coincidências.'),
    source('Fórmula apresentada como explicação matemática e candidata exploratória; sem corte ou eficácia clínica estabelecida neste projeto.'))

page('Uma paródia: o julgamento do theta','46 / Humor para fixar a ideia',
    p('<b>Cena fictícia: Tribunal das Ondas.</b> O promotor entra apontando para um gráfico: “Theta está maior que beta! Caso encerrado!”.'),
    p('O advogado do fundo aperiódico se levanta: “Excelência, meu cliente inclinou o terreno. Nenhuma montanha theta precisou crescer”. A testemunha Piscada acrescenta: “Eu também apareço no registro, e às vezes ninguém me percebe”.'),
    p('A juíza Estatística pergunta: “Em quantas pessoas novas vocês testaram? Separaram pessoas ou só picotaram as mesmas gravações?”. O promotor olha para uma pilha de cem janelas da mesma pessoa e fica em silêncio.'),
    fig('cartoon','Personagens didáticos. O julgamento é uma criação humorística, não descrição de um processo clínico.',171),
    p('O ASRS entra com seis respostas: “Minha pontuação veio do questionário”. A juíza decide: “Registrem o que cada medida realmente diz e investiguem o que ela acrescenta”.'),
    h('O que a brincadeira ensina'),
    p('Uma relação entre bandas pode ter várias causas. Uma coleta pode conter artefatos. Um teste pode parecer melhor por vazamento. E colocar duas informações lado a lado não demonstra que uma confirme a outra.'),
    note('Frase para lembrar: antes de declarar que uma montanha cresceu, confira o terreno, a régua e de onde você está olhando.'))

page('Dúvidas que costumam sobrar','47 / Perguntas diretas',
    h('Se o aperiódico já é conhecido, qual seria nossa contribuição?'),
    p('Aplicar métodos existentes com aquisição documentada, verificar confiabilidade no aparelho disponível e estudar utilidade no público pretendido. Isso pode ser uma contribuição válida mesmo sem inventar uma nova fórmula.'),
    h('Basta trocar theta/beta pelo expoente?'),
    p('Não. O expoente também depende da medição, do ajuste e do estado. A proposta é comparar componentes e testar sua utilidade. Nenhum recebeu um corte clínico neste guia.'),
    h('Qualidade alta significa que o resultado é verdadeiro?'),
    p('Significa que os critérios usados avaliaram favoravelmente a coleta. Esses critérios também precisam ser validados e não garantem especificidade para TDAH.'),
    h('O médico vê uma “onda de TDAH”?'),
    p('O relatório atual contém descrições espectrais e o rastreio ASRS. Não há uma onda individual validada nesse aparelho que determine TDAH. A avaliação clínica considera história, sintomas, prejuízos e outras explicações.'),
    h('Mais canais resolveriam tudo?'),
    p('Mais canais permitem outras análises espaciais, mas também aumentam montagem, custo e complexidade. Continuam exigindo protocolo e validação. Não se pode simular um mapa cerebral acrescentando gráficos a um único canal.'),
    h('Podemos prometer melhora de eficácia agora?'),
    p('Podemos apontar falhas de escala e oportunidades de medição. O aumento de eficácia clínica dependerá dos resultados dos estudos. Se o ganho não aparecer, esse limite deve orientar o produto.'),
    source('Limites clínicos: [8].'))

page('Dicionário de bolso: do aparelho ao espectro','48 / Consulte quando travar',
    table(['Termo','Explicação em linguagem direta'],[
        ['Amostra','Uma medida do sinal em um instante.'],['Taxa de amostragem','Quantidade de amostras produzidas por segundo.'],['Hz','Hertz: repetições por segundo; o contexto diz se são ciclos ou amostras.'],['µV','Microvolt: um milionésimo de volt.'],['Canal','Uma sequência independente de medição elétrica.'],['Montagem','Organização dos contatos e referências usados para medir.'],['SDK','Ferramentas fornecidas para o software conversar com o aparelho.'],['Raw','Sequência bruta entregue ao app; pode já ter passado por eletrônica e filtros.'],['Buffer / lote','Armazenamento temporário / grupo de amostras enviado junto.'],['Latência / jitter','Atraso de entrega / variação desse atraso.'],['Época / janela','Trecho delimitado para uma análise. “Janela” também pode nomear pesos.'],['FFT','Cálculo eficiente da representação por frequências.'],['Bin','Uma posição ou divisória no eixo de frequências.'],['PSD','Potência por unidade de frequência; depende de escala correta.'],['Banda','Intervalo de frequências cujas potências são resumidas.']],[.32,.68]),
    source('Os conceitos aparecem com exemplos nas páginas anteriores. Este quadro é uma consulta rápida, não uma nova receita de análise.'))

page('Dicionário de bolso: interpretação e pesquisa','49 / Consulte quando travar',
    table(['Termo','Explicação em linguagem direta'],[
        ['Periódico / aperiódico','Com um ritmo de repetição / sem um período regular único predominante.'],['Pico','Elevação localizada no espectro, avaliada em relação ao fundo.'],['Expoente / offset','Parâmetro da queda / parâmetro do nível no modelo do fundo.'],['IAF','Estimativa da frequência característica de alfa, quando identificável.'],['TBR','Potência theta dividida pela potência beta, com receita explícita.'],['Artefato','Contribuição que atrapalha a análise pretendida, como piscada ou músculo.'],['Rastreio','Busca de indícios para orientar avaliação mais completa.'],['Feature','Característica numérica usada na análise, como expoente ou tempo mediano.'],['Rótulo','Resultado de referência usado para avaliar ou treinar o modelo.'],['Sobreajuste','Adaptação excessiva a detalhes acidentais de um conjunto.'],['Vazamento','Uso indevido de informação que deveria estar reservada à avaliação.'],['Sensibilidade / especificidade','Acerto entre os casos / acerto entre os não casos.'],['VPP','Proporção realmente positiva pela referência entre saídas positivas.'],['Calibração','Pode significar escala física ou concordância de probabilidades; identificar o contexto.'],['Ganho incremental','Informação útil acrescentada ao que já existia.'],['Cobertura','Proporção de pessoas para quem o sistema consegue produzir resultado utilizável.']],[.32,.68]))

def ref(num,title,desc,url,label='Abrir fonte'):
    return p(f'<b>[{num}] {title}</b><br/>{desc} <a href="{escape(url, {chr(34): "&quot;"})}" color="#007F83">{label}</a>.')

page('Fontes: aquisição e processamento','50 / Referências comentadas - 1',
    ref(1,'Macrotellect. FAQs on BrainLink Usage.','Documentação do fabricante para diferenças de montagem entre modelos. Não é evidência de eficácia para TDAH.','https://macrotellect.tawk.help/article/faqs-on-brainlink-usage'),
    ref(2,'Japaridze e colaboradores. Epilepsia, 2023; publicação online em 2022.','Automated detection of absence seizures using a wearable electroencephalographic device: a phase 3 validation study. DOI 10.1111/epi.17200. Usado para montagem e exemplo de validação do Lite em outra finalidade; não transfere desempenho para TDAH.','https://doi.org/10.1111/epi.17200'),
    ref(3,'NeuroSky. ThinkGear Communications Protocol.','Documentação para códigos de mensagem, amostras e variantes de módulo. CODE_RAW 0x80 não é uma taxa de 128 Hz.','https://developer.neurosky.com/docs/doku.php?id=thinkgear_communications_protocol'),
    p('<b>Complemento de [3]: conversão raw para tensão.</b> A documentação fornece a conversão da família de hardware; confirmar a compatibilidade do módulo usado. <a href="https://support.neurosky.com/kb/science/how-to-convert-raw-values-to-voltage" color="#007F83">Abrir documentação de conversão</a>.'),
    ref(4,'SciPy. scipy.signal.welch.','Referência de implementação para densidade espectral, escala, janela e agregação. Usada para orientar comparação técnica; não é um algoritmo diagnóstico.','https://docs.scipy.org/doc/scipy/reference/generated/scipy.signal.welch.html'),
    note('As fórmulas e analogias deste guia são explicações didáticas. As referências permitem verificar métodos e pressupostos; o código do projeto é a fonte para o comportamento atual.'))

page('Fontes: periodicidade e razões','51 / Referências comentadas - 2',
    ref(5,'Wen H, Liu Z. Brain Topography, 2016; online em 2015.','Separating Fractal and Oscillatory Components in the Power Spectrum of Neurophysiological Signal. DOI 10.1007/s10548-015-0448-0. Artigo original do IRASA.','https://pubmed.ncbi.nlm.nih.gov/26318848/'),
    ref(6,'Donoghue e colaboradores. Nature Neuroscience, 2020.','Parameterizing neural power spectra into periodic and aperiodic components. DOI 10.1038/s41593-020-00744-x. Método de parametrização de fundo e picos, base do FOOOF/specparam.','https://pmc.ncbi.nlm.nih.gov/articles/PMC8106550/'),
    ref(7,'Donoghue T, Dominguez J, Voytek B. eNeuro, 2020.','Electrophysiological Frequency Band Ratio Measures Conflate Periodic and Aperiodic Neural Activity. DOI 10.1523/ENEURO.0192-20.2020. Referência específica para ambiguidades das razões entre bandas.','https://pmc.ncbi.nlm.nih.gov/articles/PMC7768281/'),
    p('Esses trabalhos são anteriores ao projeto e sustentam a correção conceitual pedida: o papel do fundo e sua separação não são descobertas nossas. Uma aplicação ao Lite precisa respeitar as limitações de montagem, filtros, duração e artefatos.'),
    p('A fórmula D apresentada no guia é uma candidata de comparação inspirada nesse problema. Não fizemos uma investigação de patente ou de originalidade exaustiva e não afirmamos que ela seja inédita.'),
    note('Quanto ao acesso: a pesquisa consultou textos HTML, métodos, resumos e PDFs conforme disponíveis. Algumas páginas apresentaram bloqueios. As notas em docs/pesquisa registram limites de leitura por estudo; não se afirma leitura integral de toda referência.'))

page('Fontes: TDAH, ASRS e tarefa','52 / Referências comentadas - 3',
    ref(8,'Gloss e colaboradores. American Academy of Neurology, 2016.','Practice advisory: The utility of EEG theta/beta power ratio in ADHD diagnosis. DOI 10.1212/WNL.0000000000003265. Orientação sobre limites de uso diagnóstico da razão.','https://pubmed.ncbi.nlm.nih.gov/27760867/'),
    ref(9,'ASRS v1.1 Screener. Scoring update, 28/02/2024.','Nota oficial de pontuação hospedada pela Harvard: soma 0-24, corte 14 e faixas. Conteúdo recuperado pelo índice oficial; abertura direta do PDF sofreu timeout.','https://www.hcp.med.harvard.edu/ncs/ftpdir/adhd/ASRS_v1.1_screener%286Q%29_scoring_update.pdf'),
    ref(10,'Kiiski e colaboradores. European Journal of Neuroscience, 2020.','EEG spectral power, but not theta/beta ratio, is a neuromarker for adult ADHD. DOI 10.1111/ejn.14645. Estudo adulto com resultados que não devem ser transferidos ao canal único do Lite; acesso parcial na pesquisa.','https://doi.org/10.1111/ejn.14645'),
    ref(12,'Shahaf e colaboradores. Frontiers in Human Neuroscience, 2018.','Estudo exploratório de índice frontal e tarefas, com amostra pequena. DOI 10.3389/fnhum.2018.00032. Motiva hipótese, sem validar nosso algoritmo.','https://doi.org/10.3389/fnhum.2018.00032'),
    ref(13,'Brunkhorst-Kanaan e colaboradores. Frontiers in Psychiatry, 2020.','Estudo em pessoas encaminhadas para avaliação, mostrando limites discriminativos das medidas de tarefa. DOI 10.3389/fpsyt.2020.00216. Ajuda a justificar controles clínicos.','https://doi.org/10.3389/fpsyt.2020.00216'))

page('Fontes: aparelhos, dados e avaliação','53 / Referências comentadas - 4',
    ref(11,'Lee e colaboradores. Scientific Reports, 2026.','Avaliação de BrainLink Pro em adultos saudáveis e comparação de medidas EEG. DOI 10.1038/s41598-026-39056-8. Não equivale a estudo de TDAH no Lite.','https://www.nature.com/articles/s41598-026-39056-8'),
    p('<b>Dados de [11]:</b> descrição em Scientific Data, DOI 10.1038/s41597-026-06962-5. <a href="https://figshare.com/articles/dataset/EEG_dataset_of_consumer-_and_research-grade_systems/30162868" color="#007F83">Dataset no Figshare</a>. Foram consultadas documentação e descrição; não foi treinado modelo nesse conjunto nesta pesquisa.'),
    ref(14,'Aggul. Frontiers in Neuroinformatics, 29/09/2026.','DOI 10.3389/fninf.2026.1930795. Comparação de divisões por janela e por participante em EEG de TDAH; usada para ilustrar risco de vazamento e generalização.','https://doi.org/10.3389/fninf.2026.1930795'),
    ref(15,'Nasrabadi e colaboradores. Dataset EEG ADHD/Control, IEEE DataPort.','DOI 10.21227/rzfh-zn36. Base pediátrica multicanal, conhecida como ADHD121. Sua população e aquisição diferem do projeto adulto frontal.','https://doi.org/10.21227/rzfh-zn36'),
    ref(16,'OpenNeuro. Dataset ds006018.','Repositório de dados adultos consultado como candidato. Conferir campos clínicos, tarefas, canais, licença e relação com ds005863 antes de usar.','https://github.com/OpenNeuroDatasets/ds006018'),
    note('Uma base pública pode verificar código sem responder à pergunta clínica final. É necessário explicar a finalidade de cada teste e evitar anunciar um desempenho de outro equipamento como desempenho do nosso produto.'))

page('De onde veio a descrição do app','54 / Rastreabilidade e estado da evidência',
    p('Checkout auditado: <b>app_Brainlink</b>, em 03/10/2026. As linhas são referências da cópia local nessa data e podem mudar. Esta verificação leu código; não realizou nova sessão física nem demonstrou eficácia clínica.'),
    table(['Código','Arquivo e pontos consultados'],[
        ['C1','MainActivity.java, em android/app/src/main/java/com/brainlink/app/. Lotes: 51 e 620-674; eventos: 528-545; filtro: 580-593.'],
        ['C2','lib/data/models/raw_batch.dart. Taxa e cadência: 45-63; conversão: 66-67; interpretação temporal no modelo.'],
        ['C3','lib/services/eeg_spectrum_analyzer.dart. Bandas: 5-9; validade: 97-101; comparação: 119-133; agregação: 213-268; preparo/FFT: 340-370.'],
        ['C4','lib/ui/screens/home_screen.dart. Durações: 147-150; contato: 355-365; coleta: 476-531; classificação de lote: 637-669; som: 773-778.'],
        ['C5','lib/data/models/asrs_screener_6.dart. Respostas: 2-7; corte: 54-56; pontuação/faixas: 86-102.'],
        ['C6','lib/services/guided_collection_report_exporter.dart. Exportação: 113-127; blocos de EEG, ASRS e orientação ao profissional.']],[.12,.88]),
    p('A auditoria identificou implementação e limites. A pesquisa identificou métodos existentes, fontes e hipóteses. Neste trabalho não houve alteração no app, treinamento de classificador ou nova estimativa de desempenho em participantes.'),
    note('O PDF descreve o estado encontrado, não uma promessa de versão futura já pronta. As melhorias continuam propostas até implementação e verificação correspondentes.'))

page('Como explicar o projeto na reunião','55 / Uma fala possível e três decisões',
    p('“Nosso aplicativo reúne um rastreio de sintomas por questionário e uma coleta elétrica frontal. Hoje ele descreve a distribuição do sinal em bandas durante olhos abertos e fechados. O resultado de possibilidade aumentada vem do ASRS.”'),
    p('“Queremos melhorar a qualidade da medição e separar melhor o que vem do fundo espectral e o que aparece como pico. Essa separação usa métodos já conhecidos. Depois queremos testar se a resposta durante uma tarefa acrescenta informação ao questionário em adultos.”'),
    p('“Para isso, precisamos confirmar as características do aparelho, validar os cálculos e conduzir um estudo com referência independente. O projeto poderá demonstrar benefício ou delimitar em quais situações o EEG não acrescenta informação.”'),
    fig('stairs','Sequência de compromisso: primeiro medir corretamente; depois demonstrar estabilidade; por fim testar utilidade.',145),
    h('Decisões úteis para a equipe'),
    p('<b>1.</b> Qual equipamento e montagem serão usados e quem pode ajudar a homologar o sinal?<br/><b>2.</b> Quem participará do desenho da tarefa, aplicação dos instrumentos e avaliação independente?<br/><b>3.</b> Qual será a primeira pergunta de pesquisa, com um resultado que permita avançar ou abandonar a hipótese?'),
    note('A contribuição mais defensável é uma cadeia de evidências: sabemos o que medimos, sabemos quando a medida é confiável e testamos se ela ajuda. Cada conclusão deve permanecer do tamanho dos dados que a sustentam.'))

# Preenche o sumário depois que a numeração final é conhecida.
entries=[(i,x['title']) for i,x in enumerate(PAGES,1) if i>=5]
mid=(len(entries)+1)//2
for idx,part in [(2,entries[:mid]),(3,entries[mid:])]:
    PAGES[idx]['blocks']=[('toc',f'<a href="#p{n}" color="#007F83"><b>{n:02d}</b>  {escape(title)}</a>') for n,title in part]
    PAGES[idx]['blocks'].append(source('Clique no assunto para ir à página. Também há marcadores no painel de navegação do PDF.'))

if __name__=='__main__':
    # Confere exemplos numéricos antes da publicação.
    assert abs((1/4-1/8)/(1/13-1/30)-2.8676470588235294)<1e-10
    assert 1+19*.5==10.5
    assert 1+(60-1)/.5==119
    assert abs(40/230*100-17.391304347826086)<1e-10
    build()
