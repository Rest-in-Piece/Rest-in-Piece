

# esse script SÓ deve tratar questões relacionadas à atualização da interface.
# O jogador pontuou? O hud.gd atualiza o label com os pontos atuais. Questões
# de lógica, como acionar vitória / derrota, devem ser tratadas em outro lugar.

extends CanvasLayer

signal solicitou_novo_jogo

@onready var label_perdeu: Label = $Perdeu
@onready var label_pontuacao: Label = %LabelPontuação
@onready var label_meta: Label = %LabelMeta
@onready var botao_novo_jogo: Button = $"Botão novo jogo"
@onready var tile_map_proxima_peca: TileMapLayer = $ProximaPecaTileMap


func _ready() -> void:
	botao_novo_jogo.pressed.connect(func(): solicitou_novo_jogo.emit())

func atualizar_pontuacao(valor: int):
	label_pontuacao.text = str(valor)

func atualizar_meta(valor: int):
	label_meta.text = str(valor)

func esconder_tela_derrota():
	label_perdeu.hide()
	botao_novo_jogo.hide()

func mostrar_tela_derrota():
	label_perdeu.show()
	botao_novo_jogo.show()


func atualizar_proxima_peca(peca: Peca, atlas_coords: Vector2i):
	tile_map_proxima_peca.clear()
	var pos_central = Vector2i(0, 0)
	for bloco in peca.angulos["0"]:
		tile_map_proxima_peca.set_cell(pos_central + bloco, 0, atlas_coords)
