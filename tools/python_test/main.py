"""Utilitário experimental para leitura serial do BrainLink em ambiente Windows."""

from BrainLinkParser import BrainLinkParser
from cushy_serial import CushySerial


PORTA_BRAINLINK = "COM4"
BAUDRATE_BRAINLINK = 57600
BANDAS_EEG = (
    "delta",
    "theta",
    "lowAlpha",
    "highAlpha",
    "lowBeta",
    "highBeta",
    "lowGamma",
    "highGamma",
)


def on_raw_data(_raw_data):
    """Recebe amostras brutas reservadas para processamento posterior."""


def on_eeg_data(data):
    """Normaliza e apresenta uma amostra decodificada pelo parser."""
    total = sum(getattr(data, band) for band in BANDAS_EEG)

    if data.attention == 0 and data.meditation == 0:
        print("Sensor sem contato com a pele ou indisponível.")
        return

    if total == 0:
        print("Amostra sem energia de banda; normalização indisponível.")
        return

    print(f"Atenção: {data.attention} | Meditação: {data.meditation}")
    percentages = " | ".join(
        f"{band}: {getattr(data, band) / total * 100:.2f}%"
        for band in BANDAS_EEG
    )
    print(f"Bandas relativas: {percentages}")


parser = BrainLinkParser(on_eeg_data, on_raw_data)
brainlink_serial = CushySerial(PORTA_BRAINLINK, BAUDRATE_BRAINLINK)


@brainlink_serial.on_message()
def handle_serial_message(message: bytes):
    """Encaminha ao parser os bytes recebidos pela porta serial."""
    parser.parse(message)
