from cushy_serial import CushySerial  # comunicação serial com o BrainLink
from BrainLinkParser import BrainLinkParser  # decodificação dos pacotes EEG

PORTA_BRAINLINK = 'COM4'     # ajuste conforme seu ambiente
BAUDRATE_BRAINLINK = 57600   # velocidade típica do BrainLink

def onRaw(raw):
    """
    Callback para dados brutos do BrainLink.
    Use este espaço para pré-processamento (ex.: filtros, FFT, logs).
    """
    # TODO: implementar análise de frequência se necessário
    return


def onEEG(data):
    """
    Callback para dados decodificados do BrainLink.
    - Normaliza bandas em porcentagem.
    - Lida com ausência de contato (atenção e meditação = 0).
    - Envia o nível de atenção ao Arduino.
    """
    # Soma das bandas para normalização
    total = (
        data.delta + data.theta + data.lowAlpha + data.highAlpha +
        data.lowBeta + data.highBeta + data.lowGamma + data.highGamma
    )

    # Checa contanto/sinal válido
    if data.attention == 0 and data.meditation == 0:
        print("⚠️ Sensor desconectado ou sem contato com a pele. ⚠️")
        return

    # Protege contra divisão por zero
    if total == 0:
        print("⚠️ Sinal EEG sem energia nas bandas (total = 0). Normalização indisponível.")

    else:
        # Normaliza e imprime porcentagens com duas casas
        print(f"atenção: {data.attention} | meditação: {data.meditation}")
        print(
            "Ondas (%): "
            f"delta {data.delta / total * 100:.2f} | "
            f"theta {data.theta / total * 100:.2f} | "
            f"lowAlpha {data.lowAlpha / total * 100:.2f} | "
            f"highAlpha {data.highAlpha / total * 100:.2f} | "
            f"lowBeta {data.lowBeta / total * 100:.2f} | "
            f"highBeta {data.highBeta / total * 100:.2f} | "
            f"lowGamma {data.lowGamma / total * 100:.2f} | "
            f"highGamma {data.highGamma / total * 100:.2f}"
        )

# Cria o parser do BrainLink
parser = BrainLinkParser(onEEG, onRaw)

brainlink_serial = CushySerial(PORTA_BRAINLINK, BAUDRATE_BRAINLINK)

@brainlink_serial.on_message()
def handle_serial_message(msg: bytes):
    """
    Recebe bytes da porta do BrainLink e entrega para o parser.
    """
    parser.parse(msg)
