class_name Fase
extends Resource

@export var meta: int = 400
# AQUI
## quantas peças o jogador pode posicionar nesta fase (antes era "blocos_maximos")
@export var pecas_maximas: int = 50
@export var velocidade_inicial: float = 4.0
@export var aceleracao: float = 0.1

@export_category("Fixação da peça")
## limite de etapas que a peça espera no chão antes de travar. 50 etapas é o tempo
## que leva para cair uma peça; 100 etapas é duas vezes mais demorado
@export var total_etapas_fixacao: float = 100.0
## quantas vezes mover/rotacionar no chão reinicia o tempo de fixação
@export var max_resets_fixacao: int = 15

# AQUI
@export_category("Pontuação")
## fichas que TODO spin concede, com ou sem linhas destruídas
@export var fichas_base_spin: int = 50
## multiplicador somado em TODO spin
@export var multiplicador_base_spin: float = 1.0
