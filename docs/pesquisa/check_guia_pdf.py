"""QA estrutural e folhas de contato para revisao visual do guia."""
from pathlib import Path
import json, re
from pypdf import PdfReader
import pdfplumber
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
TMP=ROOT/'tmp'/'pdfs'
PDF=ROOT/'output'/'pdf'/'BrainLink_Guia_Completo_Ilustrado_EEG_Aperiodico.pdf'
reader=PdfReader(str(PDF))
assert len(reader.pages)==59
texts=[]
links=0
with pdfplumber.open(PDF) as doc:
    for i,p in enumerate(doc.pages,1):
        t=p.extract_text() or ''
        assert len(t)>300,(i,'missing text')
        assert f'{i:02d} / 59' in t,(i,'footer missing')
        assert '\ufffd' not in t,(i,'replacement character')
        outside=[ch for ch in p.chars if ch.get('text','').strip() and (ch['x0']<0 or ch['x1']>p.width+.5 or ch['top']<0 or ch['bottom']>p.height+.5)]
        assert not outside,(i,'text beyond page')
        texts.append(t)
for p in reader.pages:
    links+=sum(a.get_object().get('/Subtype')=='/Link' for a in p.get('/Annots',[]))
assert links>=70,links
imgs=sorted(TMP.glob('guia-page-*.png'))
assert len(imgs)==59,len(imgs)
font=ImageFont.truetype('C:/Windows/Fonts/calibrib.ttf',18)
for batch in range(0,len(imgs),6):
    sheet=Image.new('RGB',(1300,1840),'#dbe3e8')
    draw=ImageDraw.Draw(sheet)
    for offset,path in enumerate(imgs[batch:batch+6]):
        im=Image.open(path).convert('RGB')
        im.thumbnail((620,550))
        col=offset%2;row=offset//2
        x=col*650+(650-im.width)//2;y=row*610+32
        sheet.paste(im,(x,y))
        draw.text((col*650+20,row*610+8),f'Página {batch+offset+1:02d}',font=font,fill='#153451')
    sheet.save(TMP/f'guia-contact-{batch//6+1:02d}.png')
summary={'pages':len(texts),'words':sum(len(re.findall(r'\b\w+\b',t)) for t in texts),'links':links,'rendered_pages':len(imgs),'structural_checks':'passed'}
(TMP/'guia_qa.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False))
