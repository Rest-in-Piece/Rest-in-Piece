

# esse script SÓ deve tratar a física e a movimentação das peças na grade.
# A peça colidiu? Uma linha foi preenchida? O tetris.gd atualiza o tabuleiro. 
# Questões de pontuação e avanço de meta devem ser tratadas no GameManager.

extends TileMapLayer

signal fim_de_jogo
signal jogo_iniciado
signal proxima_peca_sorteada(peca: Peca, atlas_coords: Vector2i)
signal peca_armazenada_alterada(peca: Peca, atlas_coords: Vector2i)
signal spin_realizado(tipo_spin: String)
signal linhas_destruidas(linhas: Array[LinhaPontuada])
signal peca_travada(peca: Peca, casas_hard_drop: int)

@export var pecas: Array[Peca]

# variaveis da grade (tabuleiro)
const COLUNAS : int = 10
const LINHAS : int = 20

# variaveis de movimentação
const direcoes := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var etapas : Array  # quando etapas == total_etapas, realiza o movimento
const total_etapas : int = 50
var pos_inicial := Vector2i(5, 2)
var pos_atual : Vector2i
var velocidade : float

# variaveis de delay para fixar a peça (os totais vêm do RegrasJogo)
var etapas_fixacao: float = 0.0
var total_etapas_fixacao: float
var resets_fixacao: int = 0
var max_resets_fixacao: int

# variaveis das peças no jogo
var pecas_sorteaveis: Array[Peca] = []
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
var tile_id : int = 0
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
	
	_processar_inputs()
	
	if not pode_mover(Vector2i.DOWN):
		etapas_fixacao += velocidade
		if etapas_fixacao >= total_etapas_fixacao:
			travar_peca()
	else:
		etapas[2] += velocidade   # queda com o passar do tempo
	
	# mover a peça
	for i in range(etapas.size()):
		if etapas[i] >= total_etapas:
			mover_peca(direcoes[i])
			etapas[i] = 0


func novo_jogo():
	jogo_rodando = true
	etapas = [0, 0, 0] #0 esquerda #1 direita #2 baixo
	
	if pecas_do_saco.is_empty():
		pecas_do_saco = pecas.duplicate()
	
	jogo_iniciado.emit()
	limpar_peca()
	# limpar_grid()  AQUI DESCOMENTAR
	
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


func _processar_inputs():
	if Input.is_action_pressed("mover_esquerda"):
		etapas[0] += 10
	if Input.is_action_pressed("mover_direita"):
		etapas[1] += 10
	if Input.is_action_pressed("acelerar_queda"):
		etapas[2] += 10
		if not pode_mover(Vector2i.DOWN):
			etapas_fixacao += 5.0
	if Input.is_action_just_pressed("cair_imediatamente"):
		cair_imediatamente(false)
	if Input.is_action_just_pressed("posicionar_imediatamente"):
		cair_imediatamente(true)
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
	etapas = [0, 0, 0]
	etapas_fixacao = 0.0
	resets_fixacao = 0
	casas_descidas_hard_drop = 0
	
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
		if get_cell_source_id(posicao) != -1:
			return false
	return true


# mostra a próxima peça
func desenhar_peca(peca_desenho, posicao, atlas):
	for bloco in peca_desenho:
		set_cell(posicao + bloco, tile_id, atlas)

func limpar_peca():
	for i in peca_ativa:
		erase_cell(pos_atual + i)

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


func pode_rotacionar(peca_teste: Array, offset: Vector2i) -> bool:
	for bloco in peca_teste:
		if not posicao_esta_livre(pos_atual + bloco + offset):
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


func travar_peca():
	avaliar_spin()
	
	registrar_blocos_da_peca()
	identificar_e_tratar_linhas_completas()
	
	peca_travada.emit(peca, casas_descidas_hard_drop)
	
	pode_armazenar = true
	peca = prox_peca
	peca_atlas = prox_peca_atlas
	prox_peca = seleciona_uma_peca()
	prox_peca_atlas = prox_peca.coords_no_atlas
	
	proxima_peca_sorteada.emit(prox_peca, prox_peca_atlas)
	criar_peca()


func avaliar_spin():
	if not ultima_acao_foi_rotacao:
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
	if not pode_mover(Vector2i.DOWN):
		if resets_fixacao < max_resets_fixacao:
			etapas_fixacao = 0.0
			resets_fixacao += 1


func pode_mover(direcao):
	# verifica se tem espaço para se mover
	var resposta = true
	for i in peca_ativa:
		if not posicao_esta_livre(i + pos_atual + direcao):
			resposta = false
	return resposta


func posicao_esta_livre(posicao):
	# verifica se a posição pertence à peça atual
	for bloco in peca_ativa:
		if pos_atual + bloco == posicao:
			return true

	# se não pertence à peça atual, verifica se existe algum tile nessa posição
	return get_cell_source_id(posicao) == -1


func cair_imediatamente(posicionar_imediatamente):
	while pode_mover(Vector2i.DOWN):
		etapas[2] = 0
		mover_peca(Vector2i.DOWN)
		casas_descidas_hard_drop += 1
	
	if posicionar_imediatamente:
		travar_peca()


func identificar_e_tratar_linhas_completas():
	var linhas_completas: Array[LinhaPontuada] = []
	
	for linha in range(LINHAS, 0, -1):
		if linha_esta_completa(linha):
			linhas_completas.append(criar_linha_pontuada(linha))
	
	for i in range(linhas_completas.size() - 1, -1, -1):
		deslocar_linhas(linhas_completas[i].indice_linha)
	
	if not linhas_completas.is_empty():
		linhas_destruidas.emit(linhas_completas)

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
				set_cell(posicao_destino, tile_id, atlas)
			
			mover_dados_do_bloco(posicao_origem, posicao_destino)

func limpar_grid():
	blocos_fixados.clear()
	for i in range(LINHAS):
		for j in range(COLUNAS):
			erase_cell(Vector2i(j + 1, i + 1))


# único ponto de entrada pros valores de jogabilidade definidos pelo GameManager
func aplicar_regras(regras: RegrasJogo):
	velocidade = regras.velocidade
	total_etapas_fixacao = regras.total_etapas_fixacao
	max_resets_fixacao = regras.max_resets_fixacao


func registrar_blocos_da_peca():
	for deslocamento in peca_ativa:
		blocos_fixados[pos_atual + deslocamento] = BlocoFixado.criar_a_partir_da_peca(peca)


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
