
# esse script define e coordena a lógica do jogo. O jogador destruiu linhas? O 
# game_manager.gd calcula os pontos e chama os sinais para outros scripts executarem
# suas próprias lógicas. Não coordena física e nem interface visual.

extends Node

@export var fase: Fase

## relíquias que o jogador já começa a partida (útil pra testar no editor)
@export var reliquias_iniciais: Array[Reliquia]

@onready var tabuleiro: TileMapLayer = $TabuleiroTileMap
@onready var hud: CanvasLayer = $TabuleiroTileMap/HUD

# variáveis lógicas
var pontuacao: int = 0
var meta: int = 0
var aumento_meta: bool = true
var velocidade_atual: float = 1.0
var recompensa_por_linha: int = 100

var gerenciador_reliquias: GerenciadorDeReliquias = GerenciadorDeReliquias.new()

# peças que o jogador possui na partida. Começa com as peças do tabuleiro e cresce com
# recompensas e lojas
var bolsa_de_pecas: Array[Peca] = []

# informações da jogada atual, consumidas quando a peça trava
var linhas_pendentes: int = 0
var tipo_spin_pendente: String = ""

func _ready():
	tabuleiro.linhas_destruidas.connect(_on_linhas_destruidas)
	tabuleiro.fim_de_jogo.connect(_on_fim_de_jogo)
	tabuleiro.proxima_peca_sorteada.connect(hud.atualizar_proxima_peca)
	tabuleiro.peca_armazenada_alterada.connect(hud.atualizar_peca_armazenada)
	tabuleiro.spin_realizado.connect(_on_spin_realizado)
	tabuleiro.peca_travada.connect(_on_peca_travada)
	gerenciador_reliquias.reliquias_alteradas.connect(_aplicar_regras)
	
	hud.solicitou_novo_jogo.connect(iniciar_novo_jogo)
	
	iniciar_novo_jogo()

func iniciar_novo_jogo():
	pontuacao = 0
	meta = fase.meta
	velocidade_atual = fase.velocidade_inicial
	aumento_meta = true
	linhas_pendentes = 0
	tipo_spin_pendente = ""
	
	# a bolsa precisa ser resetada antes das relíquias, que disparam o recálculo
	bolsa_de_pecas = tabuleiro.pecas.duplicate()
	
	gerenciador_reliquias.limpar()
	for reliquia in reliquias_iniciais:
		gerenciador_reliquias.adquirir(reliquia)
	
	# o HUD reseta os visuais
	hud.atualizar_pontuacao(pontuacao)
	hud.atualizar_meta(meta)
	hud.esconder_tela_derrota()
	hud.limpar_peca_armazenada()
	
	# dá início ao tabuleiro
	_aplicar_regras()
	tabuleiro.novo_jogo()


# monta as regras em vigor (Fase + relíquias) e entrega pro tabuleiro
func _aplicar_regras():
	var regras := RegrasJogo.criar_a_partir_da_fase(fase, velocidade_atual)
	gerenciador_reliquias.aplicar_regras(regras)
	tabuleiro.aplicar_regras(regras)
	
	var pecas_do_saco: Array[Peca] = bolsa_de_pecas.duplicate()
	gerenciador_reliquias.aplicar_pecas_sorteaveis(pecas_do_saco)
	tabuleiro.pecas_do_saco = pecas_do_saco


# usada por recompensas de fim de batalha e lojas. A peça passa a ser sorteável no
# próximo reabastecimento do saco do tabuleiro (a próxima batalha já a inclui)
func adicionar_peca_a_bolsa(peca: Peca, copias: int = 1):
	for i in range(copias):
		bolsa_de_pecas.append(peca)
	_aplicar_regras()


func _on_linhas_destruidas(qtd: int):
	# a pontuação é calculada em _on_peca_travada, aqui só guardamos a informação
	linhas_pendentes = qtd
	
	velocidade_atual += fase.aceleracao * qtd
	_aplicar_regras()
	
	if qtd == 4:
		# placeholder
		print("TETRIS")


func _on_spin_realizado(tipo_spin: String):
	tipo_spin_pendente = tipo_spin


# toda peça que trava gera uma pontuação, com ou sem linhas destruídas
func _on_peca_travada(peca: Peca):
	var contexto := ContextoPontuacao.new()
	contexto.peca = peca
	contexto.linhas_destruidas = linhas_pendentes
	contexto.tipo_spin = tipo_spin_pendente
	contexto.pontos = recompensa_por_linha * linhas_pendentes
	
	linhas_pendentes = 0
	tipo_spin_pendente = ""
	
	gerenciador_reliquias.processar_pontuacao(contexto)
	
	AutoBus.jogada_resolvida.emit(contexto)
	
	var pontos: int = contexto.obter_pontuacao_final()
	if pontos <= 0:
		return
	
	pontuacao += pontos
	_verificar_meta()
	
	hud.atualizar_pontuacao(pontuacao)
	hud.atualizar_meta(meta)


# com multiplicadores, uma única jogada pode passar de várias metas, por isso o while
func _verificar_meta():
	while pontuacao >= meta:
		meta *= 2 if aumento_meta else 2.5
		aumento_meta = not aumento_meta


func _on_fim_de_jogo():
	hud.mostrar_tela_derrota()
	AutoBus.partida_encerrada.emit(pontuacao)
