
extends CanvasLayer

signal solicitou_novo_jogo

@export var tabuleiro: TileMapLayer

@export var recompensa: int = 100
@export var aceleracao: float = 0.25

var pontuacao: int = 0

@onready var label_perdeu: Label = $Perdeu
@onready var label_pontuacao: Label = %LabelPontuação
@onready var botao_novo_jogo: Button = $"Botão novo jogo"

func _ready() -> void:
	_conectar_os_signals()

func _conectar_os_signals():
	if tabuleiro:
		tabuleiro.jogo_iniciado.connect(_on_jogo_iniciado)
		tabuleiro.fim_de_jogo.connect(_on_fim_de_jogo)
		tabuleiro.linhas_destruidas.connect(_on_linhas_destruidas)
		solicitou_novo_jogo.connect(tabuleiro.novo_jogo)
	
	botao_novo_jogo.pressed.connect(func(): solicitou_novo_jogo.emit())


func _on_jogo_iniciado():
	label_perdeu.hide()
	botao_novo_jogo.hide()
	pontuacao = 0
	label_pontuacao.text = str(pontuacao)
	
	if tabuleiro:
		tabuleiro.velocidade = 1.0


func _on_fim_de_jogo():
	label_perdeu.show()
	botao_novo_jogo.show()


func _on_linhas_destruidas(qtd: int):
	pontuacao += recompensa * qtd
	label_pontuacao.text = str(pontuacao)
	
	if tabuleiro:
		tabuleiro.velocidade += aceleracao * qtd
		print("Velocidade: ", tabuleiro.velocidade)
