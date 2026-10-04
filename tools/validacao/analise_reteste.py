"""Confiabilidade teste-reteste de um "BrainLink simulado" em EEG de pesquisa.

Dados: OpenNeuro ds004148 (Wang et al., Sci Data 2022, doi 10.1038/s41597-022-01607-9):
60 adultos, 3 sessões (sessão 2 até 90 min depois da 1; sessão 3 cerca de um mês
depois), 5 min de olhos abertos e 5 min de olhos fechados, 61 canais, 500 Hz.

Cada registro é convertido no que um BrainLink veria:
  fp1_tp9 : Fp1 com referência perto da orelha esquerda (montagem do Pro/MindWave)
  fp1_f7  : Fp1 − F7, derivação bipolar só na testa (montagem descrita para o Lite)
  oz      : Oz com a referência original do registro (FCz) — alfa posterior,
            usado como comparação "padrão-ouro" local. (Oz contra as mastoides
            foi descartado: TP9/TP10 também captam alfa posterior e cancelam
            parte dele.)
e passa por bl.simulate_brainlink (512 Hz, passa-alta de 2ª ordem em 2 Hz —
medido no BrainLink Pro —, quantização ThinkGear).

Protocolos comparados:
  app_atual : 1 min EO + 1 min EC (o que o app faz hoje)
  proposto  : 2 min EO + 1 min EC
  longo     : 5 min EO + 5 min EC (referência)

Uso: python analise_reteste.py <pasta com .npz extraídos> <participants.tsv> <saida.json>
"""

import json, sys, os
from concurrent.futures import ProcessPoolExecutor

import numpy as np

import brainlink_lab as bl

DATA, PART, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
DERIVS = ("fp1_tp9", "fp1_f7", "oz")
PROTOCOLS = {"app_atual": (60, 60), "proposto": (120, 60), "longo": (298, 298)}


def features(sub, ses):
    out = {}
    try:
        EO = np.load(f"{DATA}/sub-{sub:02d}_ses{ses}_eyesopen.npz")
        EC = np.load(f"{DATA}/sub-{sub:02d}_ses{ses}_eyesclosed.npz")
    except FileNotFoundError:
        return sub, ses, None
    fs_in = float(EO["fs"])
    for d in DERIVS:
        eo, fs = bl.simulate_brainlink(EO[d].astype(float), fs_in)
        ec, _ = bl.simulate_brainlink(EC[d].astype(float), fs_in)
        skip = 2 * fs
        for proto, (t_eo, t_ec) in PROTOCOLS.items():
            xo = eo[skip:skip + int(t_eo * fs)]
            xc = ec[skip:skip + int(t_ec * fs)]
            po = bl.proposed_pipeline(xo, fs, eyes_closed=False)
            pc = bl.proposed_pipeline(xc, fs, eyes_closed=True)
            ao, ac = bl.app_pipeline(xo, fs), bl.app_pipeline(xc, fs)
            out[f"{d}|{proto}"] = {
                "eo": po.summary(), "ec": pc.summary(),
                "alpha_react_db": bl.alpha_reactivity_db(po, pc),
                "app_eo_accept": ao.accepted_fraction, "app_ec_accept": ac.accepted_fraction,
                "app_theta_gt_beta_both": (None if ao.theta_above_beta is None or ac.theta_above_beta is None
                                           else bool(ao.theta_above_beta and ac.theta_above_beta)),
                "app_ln_tbr_ec": (float(np.log(ac.relative["theta"] / ac.relative["beta"]))
                                  if ac.accepted else None),
                "app_alpha_change_pp": (ac.relative["alpha"] - ao.relative["alpha"]
                                        if ao.accepted and ac.accepted else None),
            }
    return sub, ses, out


if __name__ == "__main__":
    jobs = [(s, ses) for s in range(1, 61) for ses in (1, 2, 3)]
    res = {}
    with ProcessPoolExecutor(max(1, os.cpu_count() - 1)) as ex:
        for sub, ses, out in ex.map(features, *zip(*jobs)):
            if out is not None:
                res[f"{sub}|{ses}"] = out
            print(sub, ses, "ok" if out else "faltando", flush=True)
    # questionários por sessão (sonolência KSS e ARSQ "Discontinuity of Mind")
    import csv
    q = {}
    with open(PART) as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            sid = int(r["participant_id"].split("-")[1])
            for ses in (1, 2, 3):
                kss = r.get(f"KSS_session{ses}")
                dom = next((v for k, v in r.items() if k and "Discontinuity of Mind" in k
                            and k.strip().endswith(f"session{ses}")), None)
                q[f"{sid}|{ses}"] = {"kss": kss, "discontinuity": dom}
    json.dump({"features": res, "questionarios": q}, open(OUT, "w"))
    print("salvo", OUT)
