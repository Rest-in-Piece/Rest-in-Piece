

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

var gerenciador_reliquias: GerenciadorDeReliquias = GerenciadorDeReliquias.new()

# peças que o jogador possui na partida. Cada elemento é uma CÓPIA, pra que buffs
# permanentes de uma peça não afetem as outras do mesmo tipo (nem o arquivo .tres)
var bolsa_de_pecas: Array[Peca] = []

var peca_armazenada: Peca

# informações da jogada atual, consumidas quando a peça trava
var linhas_pendentes: Array[LinhaPontuada] = []
var tipo_spin_pendente: String = ""

func _ready():
	tabuleiro.linhas_destruidas.connect(_on_linhas_destruidas)
	tabuleiro.fim_de_jogo.connect(_on_fim_de_jogo)
	tabuleiro.proxima_peca_sorteada.connect(hud.atualizar_proxima_peca)
	tabuleiro.peca_armazenada_alterada.connect(hud.atualizar_peca_armazenada)
	tabuleiro.peca_armazenada_alterada.connect(_on_peca_armazenada_alterada)
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
	linhas_pendentes = []
	tipo_spin_pendente = ""
	peca_armazenada = null
	
	bolsa_de_pecas.clear()
	for peca_inicial in tabuleiro.pecas:
		bolsa_de_pecas.append(peca_inicial.duplicate() as Peca)
	
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
	
	var pecas_sorteaveis: Array[Peca] = bolsa_de_pecas.duplicate()
	gerenciador_reliquias.aplicar_pecas_sorteaveis(pecas_sorteaveis)
	tabuleiro.pecas_sorteaveis = pecas_sorteaveis


# usada por recompensas de fim de batalha e lojas. Cada cópia é uma peça independente
func adicionar_peca_a_bolsa(peca: Peca, copias: int = 1):
	for i in range(copias):
		bolsa_de_pecas.append(peca.duplicate() as Peca)
	_aplicar_regras()


func _on_linhas_destruidas(linhas: Array[LinhaPontuada]):
	# a pontuação é calculada em _on_peca_travada, aqui só guardamos a informação
	linhas_pendentes = linhas
	
	velocidade_atual += fase.aceleracao * linhas.size()
	_aplicar_regras()
	
	if linhas.size() == 4:
		# placeholder
		print("TETRIS")


func _on_spin_realizado(tipo_spin: String):
	tipo_spin_pendente = tipo_spin


func _on_peca_armazenada_alterada(peca: Peca, _atlas_coords: Vector2i):
	peca_armazenada = peca
	gerenciador_reliquias.processar_armazenamento(peca)


# toda peça que trava gera uma pontuação, com ou sem linhas destruídas
func _on_peca_travada(peca: Peca, casas_hard_drop: int):
	var contexto := ContextoPontuacao.new()
	contexto.peca = peca
	contexto.peca_armazenada = peca_armazenada
	contexto.linhas = linhas_pendentes
	contexto.tipo_spin = tipo_spin_pendente
	contexto.casas_hard_drop = casas_hard_drop
	
	linhas_pendentes = []
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
