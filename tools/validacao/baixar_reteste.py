"""Baixa do OpenNeuro (ds004148) os registros de olhos abertos e fechados e guarda
só as derivações usadas (Fp1-TP9, Fp1-F7, Fp2-TP10, Oz-mastoides, Oz).

Uso: python baixar_reteste.py <pasta_destino>   (~13 GB baixados, ~1 GB guardados)
"""
import numpy as np, urllib.request, os, sys, concurrent.futures as cf
BASE='https://s3.amazonaws.com/openneuro.org/ds004148'
OUT=sys.argv[1]
names=None
def chans():
    h=urllib.request.urlopen(f'{BASE}/sub-01/ses-session1/eeg/sub-01_ses-session1_task-eyesclosed_eeg.vhdr').read().decode()
    return [l.split('=')[1].split(',')[0] for l in h.splitlines() if l.startswith('Ch') and '=' in l]
names=chans(); idx={n:i for i,n in enumerate(names)}
def job(args):
    s,ses,task=args
    out=f'{OUT}/sub-{s:02d}_ses{ses}_{task}.npz'
    if os.path.exists(out): return out
    url=f'{BASE}/sub-{s:02d}/ses-session{ses}/eeg/sub-{s:02d}_ses-session{ses}_task-{task}_eeg.eeg'
    try:
        raw=urllib.request.urlopen(url,timeout=120).read()
    except Exception as e:
        return f'ERR {url} {e}'
    x=np.frombuffer(raw,dtype='<f4').reshape(-1,len(names))
    g=lambda n:x[:,idx[n]].astype(np.float32)
    np.savez_compressed(out,
        fp1_tp9=g('Fp1')-g('TP9'),          # Fp1 referenciado perto da orelha esquerda
        fp1_f7=g('Fp1')-g('F7'),            # derivação bipolar frontal (Lite segundo Japaridze)
        fp2_tp10=g('Fp2')-g('TP10'),
        oz_tp=g('Oz')-(g('TP9')+g('TP10'))/2,
        oz=g('Oz'),                          # Oz com a referência original (FCz)
        fs=500)
    return out
jobs=[(s,ses,t) for s in range(1,61) for ses in (1,2,3) for t in ('eyesclosed','eyesopen')]
with cf.ThreadPoolExecutor(6) as ex:
    for r in ex.map(job,jobs):
        print(r,flush=True)
print('DONE')
