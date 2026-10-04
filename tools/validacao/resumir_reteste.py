import json, numpy as np, sys
import brainlink_lab as bl  # uso: python resumir_reteste.py entrada.json saida.json
D=json.load(open(sys.argv[1])); F=D['features']; Q=D['questionarios']
def get(sub,ses,key,path):
    r=F.get(f'{sub}|{ses}',{}).get(key)
    if r is None: return np.nan
    v=r
    for p in path.split('.'):
        v=v.get(p) if isinstance(v,dict) else None
        if v is None: return np.nan
    try: return float(v)
    except: return np.nan
out={}
def P(k,v): out[k]=v; print(k,v)
feats=[('ec.iaf','IAF (EC)',None),('ec.exponent','expoente EC',None),('eo.exponent','expoente EO',None),
       ('ec.abs_power.alpha','log alfa EC',np.log10),('ec.rel_power.alpha','alfa relativo EC',None),
       ('alpha_react_db','reatividade alfa dB',None),('eo.blinks_per_min','piscadas/min EO',None),
       ('ec.alpha_peak_power','altura pico alfa EC',None),('app_ln_tbr_ec','ln TBR (app) EC',None),('app_alpha_change_pp','mudança alfa rel (app) pp',None)]
for d in ('oz','fp1_tp9','fp1_f7'):
    for proto in ('app_atual','proposto','longo'):
        key=f'{d}|{proto}'
        for path,label,tr in feats:
            if 'blinks' in path and d=='oz': continue
            for pair,name in (((1,2),'curto'),((1,3),'1mes')):
                M=np.array([[get(s,p,key,path) for p in pair] for s in range(1,61)])
                if tr: M=tr(M)
                e=bl.icc_with_ci(M,n_boot=1000)
                out.setdefault('icc',{}).setdefault(key,{}).setdefault(label,{})[name]=[round(e[0],2),round(e[1],2),round(e[2],2),e[3]]
        est={c:f"{int(np.nansum([get(s,ses,key,c+'.estimable') for s in range(1,61) for ses in (1,2,3)]))}/{sum(1 for s in range(1,61) for ses in (1,2,3) if f'{s}|{ses}' in F)}" for c in ('eo','ec')}
        tb=[get(s,ses,key,'app_theta_gt_beta_both') for s in range(1,61) for ses in (1,2,3)]
        acc=[get(s,ses,key,'app_eo_accept') for s in range(1,61) for ses in (1,2,3)]
        out.setdefault('estimable',{})[key]=est
        out.setdefault('app',{})[key]={'theta_gt_beta_both':f'{int(np.nansum(tb))}/{int(np.sum(~np.isnan(tb)))}','eo_accept_median':round(float(np.nanmedian(acc)),2)}
# print compact table
for d in ('oz','fp1_tp9','fp1_f7'):
    for proto in ('app_atual','proposto','longo'):
        key=f'{d}|{proto}'; print('\n==',key, out['estimable'][key], out['app'][key])
        for lab,v in out['icc'][key].items(): print(f'   {lab:28s} curto {v["curto"]}  1mes {v["1mes"]}')
# convergent: IAF fp1 vs oz same session, proposto
for d in ('fp1_tp9','fp1_f7'):
    a=[];b=[]
    for s in range(1,61):
        for ses in (1,2,3):
            x=get(s,ses,f'{d}|proposto','ec.iaf'); y=get(s,ses,'oz|proposto','ec.iaf')
            if not np.isnan(x) and not np.isnan(y): a.append(x); b.append(y)
    a=np.array(a);b=np.array(b); dd=a-b
    out[f'IAF_{d}_vs_oz']=dict(n=len(a),r=round(float(np.corrcoef(a,b)[0,1]),2),mean_diff=round(float(dd.mean()),2),loa=[round(float(dd.mean()-1.96*dd.std()),2),round(float(dd.mean()+1.96*dd.std()),2)])
    print('IAF',d,'vs oz',out[f'IAF_{d}_vs_oz'])
    ra=[get(s,ses,f'{d}|proposto','alpha_react_db') for s in range(1,61) for ses in (1,2,3)]; ra=np.array(ra)
    out[f'react_{d}']=dict(median=round(float(np.nanmedian(ra)),2),gt0=f'{int(np.nansum(ra>0))}/{int(np.sum(~np.isnan(ra)))}')
    print('reactivity',d,out[f'react_{d}'])
    bp=np.array([get(s,ses,f'{d}|proposto','eo.blinks_per_min') for s in range(1,61) for ses in (1,2,3)])
    print('blinks/min',d,np.nanmedian(bp).round(1), np.nanpercentile(bp,[25,75]).round(1))
    out[f'blinks_{d}']=[round(float(np.nanmedian(bp)),1)]+[round(float(v),1) for v in np.nanpercentile(bp,[25,75])]
# within-person association with sleepiness (KSS) -- exploratory
def wp(key,path):
    xs=[];ys=[]
    for s in range(1,61):
        vals=[(get(s,ses,key,path), Q.get(f'{s}|{ses}',{}).get('kss')) for ses in (1,2,3)]
        vals=[(a,float(b)) for a,b in vals if not np.isnan(a) and b not in (None,'n/a','')]
        if len(vals)<2: continue
        a=np.array([v[0] for v in vals]); b=np.array([v[1] for v in vals])
        xs+=list(a-a.mean()); ys+=list(b-b.mean())
    xs=np.array(xs); ys=np.array(ys); r=np.corrcoef(xs,ys)[0,1]; return round(float(r),2), len(xs)
for path,lab in (('eo.rel_power.alpha','alfa rel EO'),('eo.rel_power.theta','theta rel EO'),('eo.blinks_per_min','piscadas/min EO'),('ec.abs_power.alpha','alfa EC'),('eo.exponent','expoente EO')):
    r=wp('fp1_tp9|proposto',path); out.setdefault('kss_within',{})[lab]=r; print('KSS within-person',lab,r)
json.dump(out,open(sys.argv[2],'w'),indent=1)
