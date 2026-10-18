
# esse script SÓ deve tratar a física e a movimentação das peças na grade.
# A peça colidiu? Uma linha foi preenchida? O tetris.gd atualiza o tabuleiro. 
# Questões de pontuação e avanço de meta devem ser tratadas no GameManager.
#
# Comportamentos de peças especiais (areia, bomba, vidro, fantasma...) NÃO ficam aqui:
# ficam em EfeitoDePeca. Este script oferece as primitivas do tabuleiro (seção
# "primitivas para os efeitos") e chama os hooks, sem saber qual efeito é qual.

extends TileMapLayer

signal fim_de_jogo
signal jogo_iniciado
signal proxima_peca_sorteada(peca: Peca, atlas_coords: Vector2i)
signal peca_armazenada_alterada(peca: Peca, atlas_coords: Vector2i)
signal spin_realizado(tipo_spin: String)
signal linhas_destruidas(linhas: Array[LinhaPontuada])
signal blocos_explodidos(linhas: Array[LinhaPontuada])
signal peca_travada(peca: Peca, casas_hard_drop: int)
signal peca_travando(travamento: TravamentoDePeca)
signal blocos_quebrados(quantidade: int)

@export var pecas: Array[Peca]
@onready var camada_fantasma: TileMapLayer = $PecaFantasma
@onready var camada_projecao: TileMapLayer = $ProjecaoPeca

# variaveis da grade (tabuleiro)
const COLUNAS : int = 10
const LINHAS : int = 20

const FPS_REFERENCIA: float = 60.0
const DELTA_MAXIMO: float = 0.1
const ETAPAS_QUEDA_RAPIDA: float = 10.0
const ETAPAS_FIXACAO_QUEDA_RAPIDA: float = 5.0
const OPACIDADE_PROJECAO: float = 0.25
# trava de segurança do loop que estabiliza o tabuleiro (gravidade -> linhas -> regras)
const MAX_ITERACOES_ESTABILIZACAO: int = 100

# variaveis de movimentação
const total_etapas : int = 50
var etapas_queda: float = 0.0  # quando chega em total_etapas, a peça desce uma casa
var pos_inicial := Vector2i(5, 2)
var pos_atual : Vector2i
var velocidade : float

# movimento lateral (em segundos reais, não depende do FPS)
const ATRASO_DESLOCAMENTO_LATERAL: float = 0.17
const INTERVALO_INICIAL_DESLOCAMENTO: float = 0.09
const INTERVALO_MINIMO_DESLOCAMENTO: float = 0.03
const FATOR_ACELERACAO_DESLOCAMENTO: float = 0.85
var direcao_lateral: Vector2i = Vector2i.ZERO  # ZERO = nenhuma tecla lateral ativa
var tempo_ate_proximo_deslocamento: float = 0.0
var intervalo_deslocamento_atual: float = INTERVALO_INICIAL_DESLOCAMENTO

# variaveis de delay para fixar a peça (os totais vêm do RegrasJogo)
var etapas_fixacao: float = 0.0
var total_etapas_fixacao: float
var resets_fixacao: int = 0
var max_resets_fixacao: int
var turno_atual: int = 0

# variaveis das peças no jogo
var peca: Peca
var prox_peca: Peca
var indice_rotacao : int = 0
var peca_ativa : Array
var saco_atual: Array[Peca]
var pecas_do_saco: Array[Peca] # saco de peças já modificado pelas relíquias (definido pelo GameManager)

# variáveis da peça armazenada
var peca_armazenada: Peca
var peca_armazenada_atlas: Vector2i
var pode_armazenar: bool = true

var jogo_rodando : bool

# variaveis pro tileMap
var peca_atlas : Vector2i
var prox_peca_atlas : Vector2i
var blocos_fixados: Dictionary[Vector2i, BlocoFixado] = {}
# casas que a peça atual desceu com hard drop (zerado a cada peça nova)
var casas_descidas_hard_drop: int = 0

var ultima_acao_foi_rotacao: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not jogo_rodando:
		return
	# peças que fixam sozinhas (ex: fantasma) não esperam o atraso de fixação
	if peca.fixa_ao_apoiar() and not pode_mover(Vector2i.DOWN):
		travar_peca()
		return
	
	var delta_limitado: float = minf(delta, DELTA_MAXIMO)
	var passo_tempo: float = delta_limitado * FPS_REFERENCIA
	var turno_antes_dos_inputs: int = turno_atual
	
	_processar_movimento_lateral(delta_limitado)
	_processar_inputs(passo_tempo)
	
	# um input pode ter travado a peça e causado game over
	if not jogo_rodando or turno_atual != turno_antes_dos_inputs:
		return

	if peca.fixa_ao_apoiar():
		_processar_queda_sem_atraso(passo_tempo)
		return

	if not pode_mover(Vector2i.DOWN):
		etapas_fixacao += velocidade * passo_tempo
		if etapas_fixacao >= total_etapas_fixacao:
			travar_peca()
	else:
		etapas_queda += velocidade * passo_tempo
	
	# a sobra é mantida em vez de perdida
	if etapas_queda >= total_etapas:
		mover_peca(Vector2i.DOWN)
		etapas_queda -= total_etapas


# queda das peças que fixam sozinhas: assim que não podem mais descer, travam
func _processar_queda_sem_atraso(passo_tempo: float):
	if not pode_mover(Vector2i.DOWN):
		travar_peca()
		return

	etapas_queda += velocidade * passo_tempo
	if etapas_queda >= total_etapas:
		mover_peca(Vector2i.DOWN)
		etapas_queda -= total_etapas
		if not pode_mover(Vector2i.DOWN):
			travar_peca()


func novo_jogo():
	jogo_rodando = true
	camada_fantasma.clear()
	etapas_queda = 0.0
	_parar_movimento_lateral()
	
	assert(not pecas_do_saco.is_empty(), "o GameManager precisa definir pecas_do_saco antes de novo_jogo")
	
	jogo_iniciado.emit()
	limpar_grid() # AQUI DESCOMENTAR
	
	saco_atual = pecas_do_saco.duplicate()
	peca = seleciona_uma_peca()
	peca_atlas = peca.coords_no_atlas
	prox_peca = seleciona_uma_peca()
	prox_peca_atlas = prox_peca.coords_no_atlas
	
	peca_armazenada = null
	pode_armazenar = true
	
	proxima_peca_sorteada.emit(prox_peca, prox_peca_atlas)
	
	criar_peca()


# embaralha o vetor de peças e retorna a primeira
func seleciona_uma_peca() -> Peca:
	var p: Peca
	if not saco_atual.is_empty():
		saco_atual.shuffle()
		p = saco_atual.pop_front()
	else:
		saco_atual = pecas_do_saco.duplicate()
		saco_atual.shuffle()
		p = saco_atual.pop_front()
	return p


func obter_rotacoes(peca: Peca) -> Array:
	var a = peca.angulos
	return [a["0"], a["90"], a["180"], a["270"]]


func _processar_inputs(passo_tempo: float):
	if peca.permite_fixar_manualmente() and Input.is_action_just_pressed("materializar_fantasma"):
		fixar_manualmente()
		return

	var turno_dos_inputs: int = turno_atual
	if Input.is_action_pressed("acelerar_queda"):
		etapas_queda += ETAPAS_QUEDA_RAPIDA * passo_tempo
		if not peca.fixa_ao_apoiar() and not pode_mover(Vector2i.DOWN):
			etapas_fixacao += ETAPAS_FIXACAO_QUEDA_RAPIDA * passo_tempo
	if Input.is_action_just_pressed("cair_imediatamente"):
		cair_imediatamente(false)
		if not jogo_rodando or turno_atual != turno_dos_inputs:
			return
	if Input.is_action_just_pressed("posicionar_imediatamente"):
		cair_imediatamente(true)
		if not jogo_rodando or turno_atual != turno_dos_inputs:
			return
	if Input.is_action_just_pressed("rotacionar_sentido_horario"):
		rotacionar_peca(1)
	if Input.is_action_just_pressed("rotacionar_sentido_anti_horario"):
		rotacionar_peca(-1)
	if Input.is_action_just_pressed("armazenar_peca") and pode_armazenar:
		armazenar_peca_atual()
	
	# ISSO É SÓ PRA FACILITAR OS TESTES
	if Input.is_action_just_pressed("debug_sortear_nova_peca"):
		limpar_peca()
		peca = seleciona_uma_peca()
		peca_atlas = peca.coords_no_atlas
		criar_peca()

func parar_jogo():
	jogo_rodando = false
	camada_projecao.clear()
	_parar_movimento_lateral()


func _processar_movimento_lateral(delta_segundos: float):
	var esquerda_pressionada: bool = Input.is_action_pressed("mover_esquerda")
	var direita_pressionada: bool = Input.is_action_pressed("mover_direita")
	
	# a direção apertada por último tem prioridade
	if Input.is_action_just_pressed("mover_esquerda"):
		_iniciar_movimento_lateral(Vector2i.LEFT, true)
	elif Input.is_action_just_pressed("mover_direita"):
		_iniciar_movimento_lateral(Vector2i.RIGHT, true)
	
	# soltou a direção atual: continua na outra, se ela ainda estiver pressionada
	if direcao_lateral == Vector2i.LEFT and not esquerda_pressionada:
		_parar_movimento_lateral()
		if direita_pressionada:
			_iniciar_movimento_lateral(Vector2i.RIGHT, false)
	elif direcao_lateral == Vector2i.RIGHT and not direita_pressionada:
		_parar_movimento_lateral()
		if esquerda_pressionada:
			_iniciar_movimento_lateral(Vector2i.LEFT, false)
	
	if direcao_lateral == Vector2i.ZERO:
		return
	
	# o while garante o ritmo correto mesmo se um quadro demorar mais que um intervalo
	tempo_ate_proximo_deslocamento -= delta_segundos
	while tempo_ate_proximo_deslocamento <= 0.0:
		mover_peca(direcao_lateral)
		tempo_ate_proximo_deslocamento += intervalo_deslocamento_atual
		intervalo_deslocamento_atual = maxf(
				intervalo_deslocamento_atual * FATOR_ACELERACAO_DESLOCAMENTO,
				INTERVALO_MINIMO_DESLOCAMENTO)


func _iniciar_movimento_lateral(direcao: Vector2i, mover_agora: bool):
	direcao_lateral = direcao
	tempo_ate_proximo_deslocamento = ATRASO_DESLOCAMENTO_LATERAL
	intervalo_deslocamento_atual = INTERVALO_INICIAL_DESLOCAMENTO
	
	if mover_agora:
		mover_peca(direcao)


func _parar_movimento_lateral():
	direcao_lateral = Vector2i.ZERO


func armazenar_peca_atual():
	limpar_peca()
	pode_armazenar = false
	
	if peca_armazenada == null:
		peca_armazenada = peca
		peca_armazenada_atlas = peca_atlas
		peca = prox_peca
		peca_atlas = prox_peca_atlas
		prox_peca = seleciona_uma_peca()
		prox_peca_atlas = prox_peca.coords_no_atlas
		proxima_peca_sorteada.emit(prox_peca, prox_peca_atlas)
	else:
		var temp_peca = peca
		var temp_atlas = peca_atlas
		peca = peca_armazenada
		peca_atlas = peca_armazenada_atlas
		peca_armazenada = temp_peca
		peca_armazenada_atlas = temp_atlas
	
	peca_armazenada_alterada.emit(peca_armazenada, peca_armazenada_atlas)
	criar_peca()


func criar_peca():
	turno_atual += 1
	camada_fantasma.clear()
	camada_projecao.clear()
	etapas_queda = 0.0
	etapas_fixacao = 0.0
	resets_fixacao = 0
	casas_descidas_hard_drop = 0
	# se a tecla continuar pressionada na peça seguinte, o deslocamento segue sem a pausa
	# inicial, mas recomeça na velocidade lenta (evita a peça nova "voar" até a parede)
	intervalo_deslocamento_atual = INTERVALO_INICIAL_DESLOCAMENTO
	
	pos_atual = pos_inicial
	indice_rotacao = 0
	peca_ativa = obter_rotacoes(peca)[0]
	
	ultima_acao_foi_rotacao = false
	
	if not pode_criar_peca():
		fim_de_jogo.emit()
		jogo_rodando = false
		return
	
	desenhar_peca(peca_ativa, pos_atual, peca_atlas)


func pode_criar_peca():
	for bloco in peca_ativa:
		var posicao = pos_atual + bloco
		if not posicao_esta_no_tabuleiro(posicao):
			return false
		if not peca.atravessa_blocos() and get_cell_source_id(posicao) != -1:
			return false
	return true


# Peças que atravessam blocos usam outra camada para nunca substituir os tiles fixos.
func desenhar_peca(peca_desenho, posicao, atlas):
	var atravessa: bool = peca.atravessa_blocos()
	var destino: TileMapLayer = camada_fantasma if atravessa else self
	if atravessa:
		camada_fantasma.modulate = peca.obter_cor_visual()
	for bloco in peca_desenho:
		if posicao_esta_no_tabuleiro(posicao + bloco):
			destino.set_cell(posicao + bloco, peca.id_fonte_tiles, atlas)
	atualizar_projecao()

func limpar_peca():
	camada_projecao.clear()
	if peca != null and peca.atravessa_blocos():
		camada_fantasma.clear()
		return
	for i in peca_ativa:
		erase_cell(pos_atual + i)


func obter_posicao_de_aterrissagem() -> Vector2i:
	var destino: Vector2i = pos_atual
	if peca == null or peca_ativa.is_empty():
		return destino
	# Usa as colisoes do hard drop, sem mover a peca nem alterar o grid.
	while pode_mover(destino - pos_atual + Vector2i.DOWN):
		destino += Vector2i.DOWN
	return destino


# onde os blocos da peça acabariam se ela fosse fixada no ponto de aterrissagem. Usa os
# MESMOS hooks do travamento real (filtro de posições e efeitos de projeção)
func obter_posicoes_da_projecao() -> Array[Vector2i]:
	var posicoes: Array[Vector2i] = []
	if peca == null or peca_ativa.is_empty():
		return posicoes
	
	var destino: Vector2i = obter_posicao_de_aterrissagem()
	for bloco in peca_ativa:
		posicoes.append(destino + bloco)
	posicoes = peca.filtrar_posicoes_para_registro(self, posicoes)
	
	# a peça comum está desenhada na grade: suas células atuais contam como vazias
	var ignoradas: Array[Vector2i] = []
	if not peca.atravessa_blocos():
		for bloco in peca_ativa:
			ignoradas.append(pos_atual + bloco)
	
	return peca.projetar_posicoes(self, posicoes, ignoradas)


func atualizar_projecao() -> void:
	camada_projecao.clear()
	if not jogo_rodando or peca == null:
		return
	camada_projecao.modulate = peca.obter_cor_visual()
	camada_projecao.modulate.a *= OPACIDADE_PROJECAO
	for posicao in obter_posicoes_da_projecao():
		camada_projecao.set_cell(posicao, peca.id_fonte_tiles, peca_atlas)


func zerar_rotacao():
	indice_rotacao = 0


func rotacionar_peca(sentido: int):
	var proximo_indice = (indice_rotacao + sentido + 4) % 4
	var angulos = [0, 90, 180, 270]
	
	var testes_srs = SRS.obter_testes(peca.obter_tipo_tabela_srs(), angulos[indice_rotacao], angulos[proximo_indice])
	var peca_rotacionada = obter_rotacoes(peca)[proximo_indice]
	
	for offset in testes_srs:
		if pode_rotacionar(peca_rotacionada, offset):
			limpar_peca()
			indice_rotacao = proximo_indice
			peca_ativa = peca_rotacionada
			pos_atual += offset
			desenhar_peca(peca_ativa, pos_atual, peca_atlas)
			tratar_reset_fixacao()
			
			ultima_acao_foi_rotacao = true
			return


func pode_rotacionar(peca_teste: Array, offset: Vector2i, peca_alvo: Peca = null) -> bool:
	var atravessa: bool = peca.atravessa_blocos() if peca_alvo == null else peca_alvo.atravessa_blocos()
	for bloco in peca_teste:
		if not _posicao_esta_livre_para_peca(pos_atual + bloco + offset, atravessa):
			return false
	return true


func mover_peca(direcao):
	if pode_mover(direcao):
		ultima_acao_foi_rotacao = false
		
		limpar_peca()
		pos_atual += direcao
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)
		
		if direcao == Vector2i.DOWN:
			etapas_fixacao = 0.0
			resets_fixacao = 0
		else:
			tratar_reset_fixacao()


# fixa a peça na hora, por pedido do jogador (só se algum efeito permitir)
func fixar_manualmente():
	if jogo_rodando and peca.permite_fixar_manualmente():
		travar_peca()


# PIPELINE DO TRAVAMENTO
# 1. spin  2. relíquias guardam bônus nos blocos  3. blocos são registrados (os efeitos
# podem filtrar posições)  4. ao_travar dos efeitos (ex: explosão)  5. estabilização:
# gravidade -> linhas completas -> regras (ex: vidro), repetindo até nada mudar
func travar_peca():
	camada_projecao.clear()
	avaliar_spin()
	
	# as relíquias podem guardar bônus nos quadradinhos antes de eles serem registrados
	var travamento := TravamentoDePeca.new()
	travamento.peca = peca
	travamento.casas_hard_drop = casas_descidas_hard_drop
	peca_travando.emit(travamento)
	
	var posicoes_registradas: Array[Vector2i] = registrar_blocos_da_peca(travamento)
	camada_fantasma.clear()
	# Uma materializacao sem celulas livres apenas encerra o turno.
	if not posicoes_registradas.is_empty():
		peca.ao_travar(self, posicoes_registradas)
		estabilizar_tabuleiro()
	
	peca_travada.emit(peca, casas_descidas_hard_drop)
	
	if not jogo_rodando:
		return
	
	pode_armazenar = true
	peca = prox_peca
	peca_atlas = prox_peca_atlas
	prox_peca = seleciona_uma_peca()
	prox_peca_atlas = prox_peca.coords_no_atlas
	
	proxima_peca_sorteada.emit(prox_peca, prox_peca_atlas)
	criar_peca()
	


func registrar_blocos_da_peca(travamento: TravamentoDePeca) -> Array[Vector2i]:
	var candidatas: Array[Vector2i] = []
	for deslocamento in peca_ativa:
		candidatas.append(pos_atual + deslocamento)
	
	var posicoes: Array[Vector2i] = peca.filtrar_posicoes_para_registro(self, candidatas)
	for posicao in posicoes:
		# peças comuns já estão desenhadas aqui; as que usam outra camada ainda não estão
		set_cell(posicao, peca.id_fonte_tiles, peca_atlas)
		blocos_fixados[posicao] = BlocoFixado.criar_a_partir_da_peca(peca, travamento)
	return posicoes


# deixa o tabuleiro em um estado estável depois de qualquer mudança. Cada volta:
# 1. FÍSICA dos efeitos (gravidade da areia)  2. linhas completas  3. REGRAS dos efeitos
# (quebra do vidro). Se algo mudou, repete: uma queda pode completar outra linha, uma
# linha limpa pode deixar areia sem apoio, um vidro quebrado pode soltar areia...
func estabilizar_tabuleiro() -> void:
	for volta in range(MAX_ITERACOES_ESTABILIZACAO):
		var mudou: bool = false
		
		for efeito in _obter_efeitos_no_tabuleiro():
			if efeito.ao_assentar_tabuleiro(self):
				mudou = true
		
		if identificar_e_tratar_linhas_completas():
			mudou = true
		
		for efeito in _obter_efeitos_no_tabuleiro():
			if efeito.ao_resolver_tabuleiro(self):
				mudou = true
		
		if not mudou:
			return
	
	push_warning("estabilizar_tabuleiro: limite de iteracoes atingido")


# cada efeito distinto (instância) que algum bloco do grid carrega
func _obter_efeitos_no_tabuleiro() -> Array[EfeitoDePeca]:
	var vistos: Dictionary = {}
	var efeitos: Array[EfeitoDePeca] = []
	for bloco in blocos_fixados.values():
		for efeito in bloco.efeitos:
			if not vistos.has(efeito):
				vistos[efeito] = true
				efeitos.append(efeito)
	return efeitos


# ---------- primitivas para os efeitos ----------
# Os EfeitoDePeca só mexem no tabuleiro por aqui. Cada uma mantém juntos o TileMap e o
# dicionário blocos_fixados.

# dentro dos limites e sem tile
func celula_vazia(posicao: Vector2i) -> bool:
	return posicao_esta_no_tabuleiro(posicao) and get_cell_source_id(posicao) == -1

# a linha vazia mais funda da coluna (1 = topo, LINHAS = fundo). 0 se a coluna estiver cheia
func linha_livre_mais_profunda(coluna: int) -> int:
	for linha in range(LINHAS, 0, -1):
		if get_cell_source_id(Vector2i(coluna, linha)) == -1:
			return linha
	return 0

# posições dos blocos do grid que carregam exatamente este efeito
func posicoes_com_efeito(efeito: EfeitoDePeca) -> Array[Vector2i]:
	var posicoes: Array[Vector2i] = []
	for posicao in blocos_fixados:
		if blocos_fixados[posicao].tem_efeito(efeito):
			posicoes.append(posicao)
	return posicoes

# move tile e dados de um bloco. O destino precisa estar vazio
func mover_bloco(origem: Vector2i, destino: Vector2i) -> void:
	var fonte: int = get_cell_source_id(origem)
	var atlas: Vector2i = get_cell_atlas_coords(origem)
	erase_cell(origem)
	set_cell(destino, fonte, atlas)
	mover_dados_do_bloco(origem, destino)
	blocos_fixados.erase(origem)

# apaga tile e dados SEM pontuar
func remover_bloco(posicao: Vector2i) -> void:
	erase_cell(posicao)
	blocos_fixados.erase(posicao)

# destrói tudo no alcance (distância de xadrez) das origens, limitado ao tabuleiro. As
# origens (a própria peça) são apagadas sem pontuar; o resto vira linhas parciais.
func explodir_area(origens: Array[Vector2i], raio: int) -> void:
	if origens.is_empty():
		return
	
	var area: Dictionary = {}
	var linha_inicial: int = LINHAS
	var linha_final: int = 1
	for origem in origens:
		for y in range(maxi(1, origem.y - raio), mini(LINHAS, origem.y + raio) + 1):
			for x in range(maxi(1, origem.x - raio), mini(COLUNAS, origem.x + raio) + 1):
				area[Vector2i(x, y)] = true
				linha_inicial = mini(linha_inicial, y)
				linha_final = maxi(linha_final, y)
	
	var linhas_explodidas: Array[LinhaPontuada] = []
	
	# da linha de baixo pra cima, e da esquerda pra direita (ordem de leitura dos pontos)
	for linha in range(linha_final, linha_inicial - 1, -1):
		var linha_pontuada := LinhaPontuada.new()
		linha_pontuada.indice_linha = linha
		linha_pontuada.altura = LINHAS - linha + 1
		linha_pontuada.completa = false
		
		for coluna in range(1, COLUNAS + 1):
			var posicao := Vector2i(coluna, linha)
			if not area.has(posicao) or get_cell_source_id(posicao) == -1:
				continue
			
			if not origens.has(posicao):
				var bloco_fixado: BlocoFixado = blocos_fixados.get(posicao)
				linha_pontuada.blocos.append(BlocoPontuado.criar_a_partir_do_bloco_fixado(posicao, bloco_fixado))
			
			remover_bloco(posicao)
		
		if not linha_pontuada.blocos.is_empty():
			linhas_explodidas.append(linha_pontuada)
	
	if not linhas_explodidas.is_empty():
		blocos_explodidos.emit(linhas_explodidas)


func avaliar_spin():
	if peca.atravessa_blocos() or not ultima_acao_foi_rotacao:
		return
		
	if peca.tipo_peca == "T":
		var centro_t = Vector2i.ZERO
		
		# 1. Encontrar o bloco central matematicamente (o único bloco do T que toca em 3 vizinhos)
		for bloco in peca_ativa:
			var vizinhos = 0
			for outro in peca_ativa:
				var dist_x = abs(bloco.x - outro.x)
				var dist_y = abs(bloco.y - outro.y)
				if (dist_x == 1 and dist_y == 0) or (dist_x == 0 and dist_y == 1):
					vizinhos += 1
			if vizinhos >= 3:
				centro_t = pos_atual + bloco
				break
				
		# 2. Calcular os 4 cantos em volta do bloco central
		var cantos = [
			centro_t + Vector2i(-1, -1), # Superior Esquerdo
			centro_t + Vector2i(1, -1),  # Superior Direito
			centro_t + Vector2i(-1, 1),  # Inferior Esquerdo
			centro_t + Vector2i(1, 1)    # Inferior Direito
		]
		
		var cantos_ocupados = 0
		
		for canto in cantos:
			var ocupado = false
			
			# Verifica fora da grade
			if canto.x < 1 or canto.x > COLUNAS or canto.y > LINHAS or canto.y < 1:
				ocupado = true
			# Verifica tiles existentes
			elif get_cell_source_id(canto) != -1:
				var pertence_a_peca = false
				for bloco in peca_ativa:
					if pos_atual + bloco == canto:
						pertence_a_peca = true
						break
				if not pertence_a_peca:
					ocupado = true
					
			if ocupado:
				cantos_ocupados += 1
				
		if cantos_ocupados >= 3:
			print("T-Spin realizado")
			spin_realizado.emit("T-Spin")
	
	elif peca.tipo_peca in ["S", "Z", "L", "J", "I"]:
		var sem_saida_horizontal = not pode_mover(Vector2i.LEFT) and not pode_mover(Vector2i.RIGHT)
		var sem_saida_vertical = not pode_mover(Vector2i.UP) and not pode_mover(Vector2i.DOWN)
		
		if sem_saida_horizontal and sem_saida_vertical:
			print(peca.tipo_peca + "-Spin realizado")
			spin_realizado.emit(peca.tipo_peca + "-Spin")


func tratar_reset_fixacao():
	if peca.fixa_ao_apoiar():
		return
	if not pode_mover(Vector2i.DOWN):
		if resets_fixacao < max_resets_fixacao:
			etapas_fixacao = 0.0
			resets_fixacao += 1


# "direcao" é um deslocamento a partir da posição atual. Para descer, os efeitos da peça
# ainda podem vetar (ex: fantasma sem espaço vazio abaixo)
func pode_mover(direcao: Vector2i) -> bool:
	for bloco in peca_ativa:
		if not posicao_esta_livre(bloco + pos_atual + direcao):
			return false
	if direcao.y > 0 and not peca.permite_descer(self, peca_ativa, pos_atual + direcao):
		return false
	return true


func posicao_esta_no_tabuleiro(posicao: Vector2i) -> bool:
	return posicao.x >= 1 and posicao.x <= COLUNAS and posicao.y >= 1 and posicao.y <= LINHAS


func posicao_esta_livre(posicao: Vector2i) -> bool:
	return _posicao_esta_livre_para_peca(posicao, peca.atravessa_blocos())


func _posicao_esta_livre_para_peca(posicao: Vector2i, atravessa: bool) -> bool:
	if not posicao_esta_no_tabuleiro(posicao):
		return false
	if atravessa:
		return true

	# verifica se a posição pertence à peça atual
	if not peca.atravessa_blocos():
		for bloco in peca_ativa:
			if pos_atual + bloco == posicao:
				return true

	# se não pertence à peça atual, verifica se existe algum tile nessa posição
	return get_cell_source_id(posicao) == -1


# desce a peça INTEIRA até onde pode_mover permitir. Peças que fixam sozinhas fixam aqui
func cair_imediatamente(posicionar_imediatamente: bool):
	while pode_mover(Vector2i.DOWN):
		mover_peca(Vector2i.DOWN)
		casas_descidas_hard_drop += 1
	
	etapas_queda = 0.0
	
	if posicionar_imediatamente or peca.fixa_ao_apoiar():
		travar_peca()


# devolve true se alguma linha foi limpa
func identificar_e_tratar_linhas_completas() -> bool:
	var linhas_completas: Array[LinhaPontuada] = []
	
	for linha in range(LINHAS, 0, -1):
		if linha_esta_completa(linha):
			linhas_completas.append(criar_linha_pontuada(linha))
	
	for i in range(linhas_completas.size() - 1, -1, -1):
		deslocar_linhas(linhas_completas[i].indice_linha)
	
	if not linhas_completas.is_empty():
		linhas_destruidas.emit(linhas_completas)
	return not linhas_completas.is_empty()

# desloca linhas para baixo a partir de uma linha (inclusive todas as linhas acima dela)
func deslocar_linhas(linha):
	var atlas
	for i in range(linha, 1, -1):
		for j in range(COLUNAS):
			var posicao_origem := Vector2i(j + 1, i - 1)
			var posicao_destino := Vector2i(j + 1, i)
			
			atlas = get_cell_atlas_coords(posicao_origem)
			if atlas == Vector2i(-1, -1):
				erase_cell(posicao_destino)
			else:
				set_cell(posicao_destino, get_cell_source_id(posicao_origem), atlas)
			
			mover_dados_do_bloco(posicao_origem, posicao_destino)
	
	# a linha do topo não tem de onde copiar, então precisa ser esvaziada
	for j in range(COLUNAS):
		var posicao_topo := Vector2i(j + 1, 1)
		erase_cell(posicao_topo)
		blocos_fixados.erase(posicao_topo)


func limpar_grid():
	camada_projecao.clear()
	blocos_fixados.clear()
	for i in range(LINHAS):
		for j in range(COLUNAS):
			erase_cell(Vector2i(j + 1, i + 1))


# único ponto de entrada pros valores de jogabilidade definidos pelo GameManager
func aplicar_regras(regras: RegrasJogo):
	velocidade = regras.velocidade
	total_etapas_fixacao = regras.total_etapas_fixacao
	max_resets_fixacao = regras.max_resets_fixacao


func linha_esta_completa(linha: int) -> bool:
	for coluna in range(1, COLUNAS + 1):
		if get_cell_source_id(Vector2i(coluna, linha)) == -1:
			return false
	return true

func mover_dados_do_bloco(posicao_origem: Vector2i, posicao_destino: Vector2i):
	if blocos_fixados.has(posicao_origem):
		blocos_fixados[posicao_destino] = blocos_fixados[posicao_origem]
	else:
		blocos_fixados.erase(posicao_destino)

# monta os dados de uma linha completa, da esquerda pra direita (ordem de leitura dos pontos)
func criar_linha_pontuada(linha: int) -> LinhaPontuada:
	var linha_pontuada := LinhaPontuada.new()
	linha_pontuada.indice_linha = linha
	linha_pontuada.altura = LINHAS - linha + 1
	
	for coluna in range(1, COLUNAS + 1):
		var posicao := Vector2i(coluna, linha)
		var bloco_fixado: BlocoFixado = blocos_fixados.get(posicao)
		linha_pontuada.blocos.append(BlocoPontuado.criar_a_partir_do_bloco_fixado(posicao, bloco_fixado))
	
	return linha_pontuada


# troca a peça em jogo por outra, mantendo posição e rotação. Não conta como spin
func substituir_peca_atual(nova_peca: Peca) -> bool:
	var DESLOCAMENTOS_SUBSTITUICAO := [
		Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i(-2, 0), Vector2i(2, 0)
	]
	
	if not jogo_rodando:
		return false
	
	var nova_forma: Array = obter_rotacoes(nova_peca)[indice_rotacao]
	
	for deslocamento in DESLOCAMENTOS_SUBSTITUICAO:
		if not pode_rotacionar(nova_forma, deslocamento, nova_peca):
			continue
		
		limpar_peca()
		peca = nova_peca
		peca_atlas = nova_peca.coords_no_atlas
		peca_ativa = nova_forma
		pos_atual += deslocamento
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)
		
		ultima_acao_foi_rotacao = false
		return true
	
	return false











# colocar retorno visual visual na peça caindo de acordo com
# as relíquias equipadas

# # dinamismo. Tempo é pequeno. Sentou, se divertiu
# não precisa ser jogo com rejogabilidade infinita (20 min)
