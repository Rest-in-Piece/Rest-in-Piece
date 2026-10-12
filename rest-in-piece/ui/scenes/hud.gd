# esse script SÓ deve tratar questões relacionadas à atualização da interface.
# O jogador pontuou? O hud.gd atualiza o label com os pontos atuais. Questões
# de lógica, como acionar vitória / derrota, devem ser tratadas em outro lugar.

extends CanvasLayer

signal solicitou_novo_jogo

@onready var label_perdeu: Label = $Perdeu
@onready var label_venceu: Label = $Venceu
@onready var label_pontuacao: Label = %LabelPontuação
@onready var label_meta: Label = %LabelMeta
@onready var label_pecas: Label = %LabelPecas
@onready var botao_novo_jogo: Button = $"Botão novo jogo"
@onready var tile_map_proxima_peca: TileMapLayer = $ProximaPecaTileMap
@onready var tile_map_peca_armazenada: TileMapLayer = $PecaArmazenadaTileMap


func _ready() -> void:
	botao_novo_jogo.pressed.connect(_on_botao_novo_jogo_pressed)

func _on_botao_novo_jogo_pressed():
	solicitou_novo_jogo.emit()

func atualizar_pontuacao(valor: int):
	label_pontuacao.text = str(valor)

func atualizar_meta(valor: int):
	label_meta.text = str(valor)

func atualizar_pecas(posicionadas: int, maximas: int):
	label_pecas.text = "%d / %d" % [posicionadas, maximas]

func esconder_telas_de_fim():
	label_perdeu.hide()
	label_venceu.hide()
	botao_novo_jogo.hide()

func mostrar_tela_derrota():
	label_perdeu.show()
	botao_novo_jogo.show()

func mostrar_tela_vitoria():
	label_venceu.show()
	botao_novo_jogo.show()


func atualizar_proxima_peca(peca: Peca, atlas_coords: Vector2i):
	tile_map_proxima_peca.clear()
	var pos_central = Vector2i(0, 0)
	for bloco in peca.angulos["0"]:
		tile_map_proxima_peca.set_cell(pos_central + bloco, 0, atlas_coords)


func atualizar_peca_armazenada(peca: Peca, atlas_coords: Vector2i):
	tile_map_peca_armazenada.clear()
	if peca == null:
		return
	var pos_central = Vector2i(0, 0)
	for bloco in peca.angulos["0"]:
		tile_map_peca_armazenada.set_cell(pos_central + bloco, 0, atlas_coords)


func limpar_peca_armazenada():
	tile_map_peca_armazenada.clear()
