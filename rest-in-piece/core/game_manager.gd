

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

# regras em vigor (Fase + relíquias), recriadas em _aplicar_regras
var regras_atuais: RegrasJogo

# peças que o jogador possui na partida. Cada elemento é uma CÓPIA, pra que buffs
# permanentes de uma peça não afetem as outras do mesmo tipo (nem o arquivo .tres)
var bolsa_de_pecas: Array[Peca] = []
# a bolsa depois de as relíquias alterarem uma cópia (de onde o tabuleiro sorteia)
var pecas_do_saco_atual: Array[Peca] = []

var peca_armazenada: Peca

# limite de peças da fase
var pecas_posicionadas: int = 0
var pecas_extras_da_partida: int = 0  # somadas ao limite por efeitos (ex: relíquias)


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
	tabuleiro.peca_travando.connect(gerenciador_reliquias.processar_travamento)
	tabuleiro.peca_travada.connect(_on_peca_travada)
	gerenciador_reliquias.reliquias_alteradas.connect(_aplicar_regras)
	gerenciador_reliquias.reliquias_alteradas.connect(_atualizar_hud_reliquias)
	
	hud.solicitou_novo_jogo.connect(iniciar_novo_jogo)
	
	iniciar_novo_jogo()


func _process(delta: float):
	if not tabuleiro.jogo_rodando or gerenciador_reliquias.reliquias.is_empty():
		return
	
	var contexto := ContextoDeTempo.new()
	contexto.delta = delta
	contexto.peca_atual = tabuleiro.peca
	contexto.pecas_do_saco = pecas_do_saco_atual
	contexto.peca_apoiada = not tabuleiro.pode_mover(Vector2i.DOWN)
	
	gerenciador_reliquias.processar_tempo(contexto)
	
	_aplicar_substituicao_de_peca(contexto)


# tenta as candidatas propostas pela relíquia, em ordem, até alguma caber no tabuleiro.
# Se nenhuma couber, a peça atual é mantida
func _aplicar_substituicao_de_peca(contexto: ContextoDeTempo):
	for candidata in contexto.candidatas_substituicao:
		if tabuleiro.substituir_peca_atual(candidata):
			# a relíquia só é considerada ativa se a troca de fato aconteceu
			AutoBus.reliquia_ativada.emit(contexto.reliquia_proponente)
			return


func iniciar_novo_jogo():
	pontuacao = 0
	meta = fase.meta
	velocidade_atual = fase.velocidade_inicial
	aumento_meta = true
	linhas_pendentes = []
	tipo_spin_pendente = ""
	peca_armazenada = null
	pecas_posicionadas = 0
	pecas_extras_da_partida = 0
	
	# a bolsa precisa ser resetada antes das relíquias, que disparam o recálculo
	bolsa_de_pecas.clear()
	for peca_inicial in tabuleiro.pecas:
		bolsa_de_pecas.append(peca_inicial.criar_copia())
	
	gerenciador_reliquias.limpar()
	for reliquia in reliquias_iniciais:
		gerenciador_reliquias.adquirir(reliquia)
	
	# o HUD reseta os visuais (o contador de peças é atualizado em _aplicar_regras)
	hud.atualizar_pontuacao(pontuacao)
	hud.atualizar_meta(meta)
	hud.esconder_telas_de_fim()
	hud.limpar_peca_armazenada()
	
	# dá início ao tabuleiro
	_aplicar_regras()
	tabuleiro.novo_jogo()


# monta as regras em vigor (Fase + relíquias) e entrega pro tabuleiro
func _aplicar_regras():
	regras_atuais = RegrasJogo.criar_a_partir_da_fase(fase, velocidade_atual)
	gerenciador_reliquias.aplicar_regras(regras_atuais)
	tabuleiro.aplicar_regras(regras_atuais)
	
	pecas_do_saco_atual = bolsa_de_pecas.duplicate()
	gerenciador_reliquias.aplicar_pecas_do_saco(pecas_do_saco_atual)
	tabuleiro.pecas_do_saco = pecas_do_saco_atual
	
	# o limite pode ter mudado (relíquias), então o HUD é atualizado junto
	_atualizar_hud_pecas()


# usada por recompensas de fim de batalha e lojas. Cada cópia é uma peça independente
func adicionar_peca_a_bolsa(peca: Peca, copias: int = 1):
	for i in range(copias):
		bolsa_de_pecas.append(peca.criar_copia())
	_aplicar_regras()


# usada por recompensas e lojas. Retorna false se o limite de relíquias foi atingido
func adquirir_reliquia(reliquia: Reliquia) -> bool:
	return gerenciador_reliquias.adquirir(reliquia)

func _atualizar_hud_reliquias():
	hud.atualizar_reliquias(gerenciador_reliquias.reliquias)


func obter_pecas_maximas() -> int:
	return regras_atuais.pecas_maximas + pecas_extras_da_partida

func _atualizar_hud_pecas():
	hud.atualizar_pecas(pecas_posicionadas, obter_pecas_maximas())


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
	
	_aplicar_bonus_base_de_spin(contexto)
	gerenciador_reliquias.processar_pontuacao(contexto)
	
	AutoBus.jogada_resolvida.emit(contexto)
	
	var pontos: int = contexto.obter_pontuacao_final()
	if pontos > 0:
		pontuacao += pontos
		_verificar_meta()
		hud.atualizar_pontuacao(pontuacao)
		hud.atualizar_meta(meta)
	
	# o limite é verificado DEPOIS da pontuação, que pode conceder peças extras
	pecas_posicionadas += 1
	pecas_extras_da_partida += contexto.pecas_extras
	_atualizar_hud_pecas()
	
	if pecas_posicionadas >= obter_pecas_maximas():
		_resolver_fim_do_limite_de_pecas()


# todo spin concede um bônus base, com ou sem relíquias e com ou sem linhas destruídas.
# É aplicado ANTES das relíquias, pra que elas ampliem o bônus
func _aplicar_bonus_base_de_spin(contexto: ContextoPontuacao):
	if not contexto.teve_spin():
		return
	
	contexto.adicionar_fichas(regras_atuais.fichas_base_spin)
	contexto.adicionar_multiplicador(regras_atuais.multiplicador_base_spin)


# com multiplicadores, uma única jogada pode passar de várias metas, por isso o while
func _verificar_meta():
	while pontuacao >= meta:
		var fator: float = 2.0 if aumento_meta else 2.5
		meta = int(meta * fator)
		aumento_meta = not aumento_meta


func _on_fim_de_jogo():
	_perder_partida()


# o limite de peças acabou e todas as pontuações já foram resolvidas. A fase é vencida se
# a meta DA FASE foi atingida (a variável "meta" dobra durante a partida, então não serve
# pra essa comparação). Caso contrário, é derrota
func _resolver_fim_do_limite_de_pecas():
	print("LIMITE: posicionadas=", pecas_posicionadas, " maximas=", obter_pecas_maximas(), " pontuacao=", pontuacao, " meta_fase=", fase.meta)
	tabuleiro.parar_jogo()
	
	if pontuacao >= fase.meta:
		_concluir_fase()
	else:
		_perder_partida()


func _concluir_fase():
	hud.mostrar_tela_vitoria()
	AutoBus.fase_concluida.emit(pontuacao)

func _perder_partida():
	hud.mostrar_tela_derrota()
	AutoBus.partida_perdida.emit(pontuacao)
