

# esse script define e coordena a lógica do jogo. O jogador destruiu linhas? O 
# game_manager.gd calcula os pontos e chama os sinais para outros scripts executarem
# suas próprias lógicas. Não coordena física e nem interface visual.

extends Node

@export var fase: Fase

@export var multiplicador_tempo_fixacao: float = 2.0

@onready var tabuleiro: TileMapLayer = $TabuleiroTileMap
@onready var hud: CanvasLayer = $TabuleiroTileMap/HUD

# variáveis lógicas
var pontuacao: int = 0
var meta: int = 0
var aumento_meta: bool = true
var velocidade_atual: float = 1.0
var recompensa_por_linha: int = 100

func _ready():
	tabuleiro.linhas_destruidas.connect(_on_linhas_destruidas)
	tabuleiro.fim_de_jogo.connect(_on_fim_de_jogo)
	tabuleiro.proxima_peca_sorteada.connect(hud.atualizar_proxima_peca)
	tabuleiro.peca_armazenada_alterada.connect(hud.atualizar_peca_armazenada)
	
	hud.solicitou_novo_jogo.connect(iniciar_novo_jogo)
	
	iniciar_novo_jogo()

func iniciar_novo_jogo():
	pontuacao = 0
	meta = fase.meta
	velocidade_atual = fase.velocidade_inicial
	aumento_meta = true
	
	# o HUD reseta os visuais
	hud.atualizar_pontuacao(pontuacao)
	hud.atualizar_meta(meta)
	hud.esconder_tela_derrota()
	hud.limpar_peca_armazenada()
	
	# dá início ao tabuleiro
	tabuleiro.velocidade = velocidade_atual
	tabuleiro.total_etapas_fixacao = multiplicador_tempo_fixacao * tabuleiro.total_etapas
	tabuleiro.novo_jogo()


func _on_linhas_destruidas(qtd: int):
	pontuacao += recompensa_por_linha * qtd
	if pontuacao >= meta:
		meta *= 2 if aumento_meta else 2.5
		aumento_meta = not aumento_meta
	
	velocidade_atual += fase.aceleracao * qtd
	
	hud.atualizar_pontuacao(pontuacao)
	hud.atualizar_meta(meta)
	tabuleiro.velocidade = velocidade_atual
	tabuleiro.total_etapas_fixacao = multiplicador_tempo_fixacao * tabuleiro.total_etapas
	
	if qtd == 4:
		# placeholder
		print("TETRIS")


func _on_fim_de_jogo():
	hud.mostrar_tela_derrota()
