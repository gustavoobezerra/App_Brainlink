import json, numpy as np, sys
import brainlink_lab as bl  # uso: python resumir_brainlink_pro.py entrada.json saida.json
R=json.load(open(sys.argv[1]))
def col(k):
    out=[]
    for r in R:
        v=r
        for kk in k.split('.'):
            v=v.get(kk) if isinstance(v,dict) else None
            if v is None: break
        out.append(np.nan if v is None else (float(v) if not isinstance(v,(dict,list)) else np.nan))
    return np.array(out,float)
out={}
def P(k,v): out[k]=v; print(k,':',v)
for dev in ('BLP','MW2'):
    h=col(f'{dev}_cued_hits'); n=col(f'{dev}_cued_n'); m=~np.isnan(h)
    P(f'{dev}_sens', dict(hits=int(np.nansum(h)),n=int(np.nansum(n)),sens=round(float(np.nansum(h)/np.nansum(n)),3),subj_median=round(float(np.median(h[m]/n[m])),2),subj_min=round(float(np.min(h[m]/n[m])),2),n_subj=int(m.sum()),subj_ge90=int(np.sum(h[m]/n[m]>=0.9))))
    fp=col(f'{dev}_false_per_min_EC'); P(f'{dev}_false_EC_per_min', dict(median=round(float(np.nanmedian(fp)),2),mean=round(float(np.nanmean(fp)),2),max=round(float(np.nanmax(fp)),2),n=int(np.sum(~np.isnan(fp)))))
ja=col('BLP_jaw_auc'); P('jaw_auc',dict(median=round(float(np.nanmedian(ja)),3),q25=round(float(np.nanpercentile(ja,25)),3),min=round(float(np.nanmin(ja)),3),n=int(np.sum(~np.isnan(ja))),ge08=int(np.sum(ja>=0.8))))
for task,cond in (('MVO','EO'),('MVC','EC'),('EB','EC'),('BT','EC')):
    af=col(f'app_{task}_pre.accepted_frac'); tb=col(f'app_{task}_pre.theta_gt_beta')
    rel=[round(float(np.nanmedian(col(f'app_{task}_pre.relative.{b}'))),1) for b in ('delta','theta','alpha','beta')]
    P(f'app_{task}_pre_{cond}', dict(accepted_frac_median=round(float(np.nanmedian(af)),2), theta_gt_beta=f'{int(np.nansum(tb))}/{int(np.sum(~np.isnan(tb)))}', rel_median_dtab=rel))
for k,cond in (('new_MVO_pre','EO 1min'),('new_MVO_2min','EO 2min'),('new_MVC_pre','EC'),('new_EB_pre','EC'),('new_BT_pre','EC')):
    est=col(f'{k}.estimable'); cs=col(f'{k}.seconds_clean'); bpm=col(f'{k}.blinks_per_min')
    d=dict(cond=cond,estimable=f'{int(np.nansum(est))}/{int(np.sum(~np.isnan(est)))}',clean_s_median=round(float(np.nanmedian(cs)),0))
    for f in ('exponent','r2','iaf'):
        v=col(f'{k}.{f}'); 
        if np.sum(~np.isnan(v)): d[f]=[round(float(np.nanmedian(v)),2),round(float(np.nanpercentile(v,25)),2),round(float(np.nanpercentile(v,75)),2),int(np.sum(~np.isnan(v)))]
    tp=col(f'{k}.theta_peak'); d['theta_peak']=f'{int(np.nansum(tp))}/{int(np.sum(~np.isnan(tp)))}'
    if cond.startswith('EO'): d['blinks_per_min']=[round(float(np.nanmedian(bpm)),1),round(float(np.nanpercentile(bpm,25)),1),round(float(np.nanpercentile(bpm,75)),1)]
    rs={r:col(f'{k}.reasons.{r}') for r in ('transporte','piscada','amplitude','plano','emg')}; tot=col(f'{k}.epochs_total')
    d['rejeicao']={r:round(float(np.nansum(v)/np.nansum(tot)),3) for r,v in rs.items()}
    P(k,d)
for k in ('new_alpha_react_db_1min','new_alpha_react_db_2min','DSI_Fp1_alpha_react_db_2min','DSI_O_alpha_react_db_2min'):
    a=col(k); n=int(np.sum(~np.isnan(a)))
    P(k, dict(median=round(float(np.nanmedian(a)),2) if n else None, q25=round(float(np.nanpercentile(a,25)),2) if n else None, gt0=f'{int(np.nansum(a>0))}/{n}', gt3=int(np.nansum(a>3))))
apc=col('app_alpha_rel_change_pp'); P('app_alpha_rel_change_pp',dict(median=round(float(np.nanmedian(apc)),1),gt0=f'{int(np.nansum(apc>0))}/{int(np.sum(~np.isnan(apc)))}'))
ib=col('new_MVC_pre.iaf')
for lab in ('DSI_Fp1','DSI_O'):
    io=col(f'{lab}_EC.iaf'); m=~np.isnan(ib)&~np.isnan(io); d=ib[m]-io[m]
    P(f'IAF_BLP_vs_{lab}', dict(n=int(m.sum()),mean_diff=round(float(d.mean()),2),abs_mean=round(float(np.abs(d).mean()),2),sd=round(float(d.std(ddof=1)),2),loa=[round(float(d.mean()-1.96*d.std(ddof=1)),2),round(float(d.mean()+1.96*d.std(ddof=1)),2)],r=round(float(np.corrcoef(ib[m],io[m])[0,1]),2)))
def icc(keys,f,tr=lambda v:v):
    M=tr(np.column_stack([col(f'{k}.{f}') for k in keys])); e=bl.icc_with_ci(M); return [round(e[0],2),round(e[1],2),round(e[2],2),e[3]]
EC3=['new_EB_pre','new_BT_pre','new_MVC_pre']
for f,tr in (('iaf',lambda v:v),('exponent',lambda v:v),('abs_power.alpha',np.log10),('rel_power.alpha',lambda v:v),('rel_power.theta',lambda v:v),('alpha_peak_power',lambda v:v)):
    P(f'ICC_EC_3blocos_{f}', icc(EC3,f,tr))
    P(f'ICC_EC_pre_pos_MVC_{f}', icc(['new_MVC_pre','new_MVC_post'],f,tr))
for f,tr in (('blinks_per_min',lambda v:v),('exponent',lambda v:v),('abs_power.alpha',np.log10)):
    P(f'ICC_EO_pre_pos_MVO_{f}', icc(['new_MVO_pre','new_MVO_post'],f,tr))
# TBR app EC reliability
def tbr(task,lab):
    return col(f'app_{task}_{lab}.relative.theta')/col(f'app_{task}_{lab}.relative.beta')
M=np.column_stack([np.log(tbr(t,'pre')) for t in ('EB','BT','MVC')]); e=bl.icc_with_ci(M); P('ICC_EC_3blocos_lnTBR_app',[round(e[0],2),round(e[1],2),round(e[2],2),e[3]])
json.dump(out,open(sys.argv[2],'w'),indent=1)
