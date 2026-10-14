

# esse script define e coordena a lógica do jogo. O jogador destruiu linhas? O 
# game_manager.gd calcula os pontos e chama os sinais para outros scripts executarem
# suas próprias lógicas. Não coordena física e nem interface visual.

extends Node

## fases da partida, em ordem (1 - 2 - 3...). A primeira é a que começa
@export var fases: Array[Fase]

## relíquias que podem aparecer na tela de recompensas (quando a fase não define as suas)
@export var reliquias_disponiveis: Array[Reliquia]

## relíquias que o jogador já começa a partida (útil pra testar no editor)
@export var reliquias_iniciais: Array[Reliquia]

const QUANTIDADE_DE_RECOMPENSAS: int = 3

@onready var tabuleiro: TileMapLayer = $TabuleiroTileMap
@onready var hud: CanvasLayer = %HUD

# variáveis lógicas
var pontuacao: int = 0
var velocidade_atual: float = 1.0

var indice_fase: int = 0
# a fase em andamento. O resto do código lê "fase" normalmente
var fase: Fase:
	get:
		return fases[indice_fase]

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
	assert(not fases.is_empty(), "defina ao menos uma fase em 'fases' no GameManager")
	
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
	hud.recompensa_reliquia_escolhida.connect(_on_recompensa_reliquia_escolhida)
	hud.transicao_de_fase_concluida.connect(_avancar_para_proxima_fase)
	
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


# começa uma PARTIDA do zero: volta pra primeira fase e reseta bolsa de peças e relíquias
func iniciar_novo_jogo():
	indice_fase = 0
	
	# a bolsa precisa ser resetada antes das relíquias, que disparam o recálculo
	bolsa_de_pecas.clear()
	for peca_inicial in tabuleiro.pecas:
		bolsa_de_pecas.append(peca_inicial.criar_copia())
	
	gerenciador_reliquias.limpar()
	for reliquia in reliquias_iniciais:
		gerenciador_reliquias.adquirir(reliquia)
	
	_iniciar_fase()


# começa uma FASE: zera o que é da fase (pontuação, limite de peças, velocidade, tabuleiro)
# e mantém o que é da partida (bolsa de peças e relíquias)
func _iniciar_fase():
	pontuacao = 0
	velocidade_atual = fase.velocidade_inicial
	linhas_pendentes = []
	tipo_spin_pendente = ""
	peca_armazenada = null
	pecas_posicionadas = 0
	pecas_extras_da_partida = 0
	
	# o HUD reseta os visuais (o contador de peças é atualizado em _aplicar_regras)
	hud.atualizar_pontuacao(pontuacao)
	hud.atualizar_meta(fase.meta)
	hud.esconder_telas_de_fim()
	hud.limpar_peca_armazenada()
	
	# dá início ao tabuleiro
	_aplicar_regras()
	tabuleiro.novo_jogo()


# chamado pelo HUD quando a vitória e a recompensa terminaram de ser exibidas
func _avancar_para_proxima_fase():
	if not _existe_proxima_fase():
		return
	
	indice_fase += 1
	_iniciar_fase()


func _existe_proxima_fase() -> bool:
	return indice_fase + 1 < fases.size()


func _obter_nome_da_fase() -> String:
	if fase.nome.is_empty():
		return "Fase %d" % (indice_fase + 1)
	return fase.nome


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
		hud.atualizar_pontuacao(pontuacao)
	
	# o limite é verificado DEPOIS da pontuação, que pode conceder peças extras
	pecas_posicionadas += 1
	pecas_extras_da_partida += contexto.pecas_extras
	_atualizar_hud_pecas()
	
	# a meta vence a fase NA HORA. Ela tem prioridade sobre o limite: se a última peça
	# atingiu a meta, é vitória
	if pontuacao >= fase.meta:
		_concluir_fase()
	elif pecas_posicionadas >= obter_pecas_maximas():
		_perder_partida()


# todo spin concede um bônus base, com ou sem relíquias e com ou sem linhas destruídas.
# É aplicado ANTES das relíquias, pra que elas ampliem o bônus
func _aplicar_bonus_base_de_spin(contexto: ContextoPontuacao):
	if not contexto.teve_spin():
		return
	
	contexto.adicionar_fichas(regras_atuais.fichas_base_spin)
	contexto.adicionar_multiplicador(regras_atuais.multiplicador_base_spin)


func _on_fim_de_jogo():
	_perder_partida()


# pausa o jogo e entrega a sequência de vitória e recompensas ao HUD. O jogo só continua
# quando o HUD avisa (transicao_de_fase_concluida)
func _concluir_fase():
	tabuleiro.parar_jogo()
	AutoBus.fase_concluida.emit(pontuacao)
	
	if _existe_proxima_fase():
		hud.mostrar_vitoria_da_fase(_obter_nome_da_fase(), _obter_reliquias_de_recompensa())
	else:
		hud.mostrar_vitoria_final(_obter_nome_da_fase())


# as recompensas definidas na Fase (escolha manual, pra teaser) vêm primeiro, na ordem. O que
# faltar pra completar QUANTIDADE_DE_RECOMPENSAS é sorteado do pool, sem repetir. Se o pool
# não tiver relíquias diferentes o bastante, repete relíquias pra sempre oferecer 3 opções
func _obter_reliquias_de_recompensa() -> Array[Reliquia]:
	var oferecidas: Array[Reliquia] = []
	
	for reliquia in fase.recompensas_fixas:
		if reliquia != null and oferecidas.size() < QUANTIDADE_DE_RECOMPENSAS:
			oferecidas.append(reliquia)
	
	var pool: Array[Reliquia] = _obter_pool_de_reliquias()
	
	var sorteaveis: Array[Reliquia] = []
	for reliquia in pool:
		if not oferecidas.has(reliquia):
			sorteaveis.append(reliquia)
	sorteaveis.shuffle()
	
	while oferecidas.size() < QUANTIDADE_DE_RECOMPENSAS and not sorteaveis.is_empty():
		oferecidas.append(sorteaveis.pop_back())
	
	if oferecidas.size() >= QUANTIDADE_DE_RECOMPENSAS:
		return oferecidas
	
	# o pool é pequeno demais: repete relíquias pra manter sempre 3 opções
	var repetiveis: Array[Reliquia] = pool
	if repetiveis.is_empty():
		repetiveis = oferecidas.duplicate()
	
	if repetiveis.is_empty():
		push_warning("recompensas: nenhuma relíquia disponível. Preencha 'reliquias_disponiveis' no GameManager")
		return oferecidas
	
	push_warning("recompensas: só há %d relíquia(s) diferente(s) disponível(is). Repetindo pra completar %d opções. Adicione mais relíquias em 'reliquias_disponiveis'" % [oferecidas.size() + sorteaveis.size(), QUANTIDADE_DE_RECOMPENSAS])
	while oferecidas.size() < QUANTIDADE_DE_RECOMPENSAS:
		oferecidas.append(repetiveis.pick_random())
	
	return oferecidas


# o pool sem os elementos vazios do inspetor
func _obter_pool_de_reliquias() -> Array[Reliquia]:
	var pool: Array[Reliquia] = []
	for reliquia in reliquias_disponiveis:
		if reliquia != null:
			pool.append(reliquia)
	return pool


func _on_recompensa_reliquia_escolhida(reliquia: Reliquia):
	if not gerenciador_reliquias.adquirir(reliquia):
		push_warning("limite de relíquias atingido: a recompensa foi descartada")


func _perder_partida():
	tabuleiro.parar_jogo()
	hud.mostrar_tela_derrota()
	AutoBus.partida_perdida.emit(pontuacao)
