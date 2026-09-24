

# esse script SÓ deve tratar a física e a movimentação das peças na grade.
# A peça colidiu? Uma linha foi preenchida? O tetris.gd atualiza o tabuleiro. 
# Questões de pontuação e avanço de meta devem ser tratadas no GameManager.

extends TileMapLayer

signal fim_de_jogo
signal jogo_iniciado
signal linhas_destruidas(quantidade: int)
signal proxima_peca_sorteada(peca: Peca, atlas_coords: Vector2i)

@export var pecas: Array[Peca]

# variaveis da grade (tabuleiro)
const COLUNAS : int = 10
const LINHAS : int = 20

# variaveis de movimentação
const direcoes := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var etapas : Array	# quando etapas == total_etapas, realiza o movimento
const total_etapas : int = 50
var pos_inicial := Vector2i(5, 1)
var pos_atual : Vector2i
var velocidade : float

# variaveis das peças no jogo
var peca: Peca
var prox_peca: Peca
var indice_rotacao : int = 0
var peca_ativa : Array
var pecas_disponiveis: Array[Peca]

var jogo_rodando : bool

# variaveis pro tileMap
var tile_id : int = 0
var peca_atlas : Vector2i
var prox_peca_atlas : Vector2i


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not jogo_rodando:
		return
	
	_processar_inputs()
	etapas[2] += velocidade   # queda com o passar do tempo
	# mover a peça
	for i in range(etapas.size()):
		if etapas[i] >= total_etapas:
			mover_peca(direcoes[i])
			etapas[i] = 0


func novo_jogo():
	jogo_rodando = true
	etapas = [0, 0, 0] #0 esquerda #1 direita #2 baixo
	
	jogo_iniciado.emit()
	limpar_peca()
	limpar_grid()
	
	pecas_disponiveis = pecas.duplicate()
	peca = seleciona_uma_peca()
	peca_atlas = Vector2i(pecas.find(peca), 0)
	prox_peca = seleciona_uma_peca()
	prox_peca_atlas = Vector2i(pecas.find(prox_peca), 0)
	
	proxima_peca_sorteada.emit(prox_peca, prox_peca_atlas)
	
	criar_peca()


# embaralha o vetor de peças e retorna a primeira
func seleciona_uma_peca() -> Peca:
	var p: Peca
	if not pecas_disponiveis.is_empty():
		pecas_disponiveis.shuffle()
		p = pecas_disponiveis.pop_front()
	else:
		pecas_disponiveis = pecas.duplicate()
		pecas_disponiveis.shuffle()
		p = pecas_disponiveis.pop_front()
	return p


func obter_rotacoes(peca: Peca) -> Array:
	var a = peca.angulos
	return [a["0"], a["90"], a["180"], a["270"]]


func _processar_inputs():
	if Input.is_action_pressed("mover_esquerda"):
		etapas[0] += 5
	if Input.is_action_pressed("mover_direita"):
		etapas[1] += 5
	if Input.is_action_pressed("acelerar_queda"):
		etapas[2] += 5
	if Input.is_action_just_pressed("rotacionar_peca"):
		rotacionar_peca()
	
	# ISSO É SÓ PRA FACILITAR OS TESTES
	if Input.is_action_just_pressed("debug_sortear_nova_peca"):
			limpar_peca()
			peca = seleciona_uma_peca()
			peca_atlas = Vector2i(pecas.find(peca), 0)
			criar_peca()


func criar_peca():
	etapas = [0, 0, 0]
	pos_atual = pos_inicial
	indice_rotacao = 0
	peca_ativa = obter_rotacoes(peca)[0]
	
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
func desenhar_peca(peca, posicao, atlas):
	for bloco in peca:
		set_cell(posicao + bloco, tile_id, atlas)

func limpar_peca():
	for i in peca_ativa:
		erase_cell(pos_atual + i)

func zerar_rotacao():
	indice_rotacao = 0

func rotacionar_peca():
	if pode_rotacionar():
		limpar_peca()
		indice_rotacao = (indice_rotacao + 1) % 4
		peca_ativa = obter_rotacoes(peca)[indice_rotacao]
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)


func mover_peca(direcao):
	if pode_mover(direcao):
		limpar_peca()
		pos_atual += direcao
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	else:
		if direcao == Vector2i.DOWN:
			identificar_e_tratar_linhas_completas()
			peca = prox_peca
			peca_atlas = prox_peca_atlas
			prox_peca = seleciona_uma_peca()
			prox_peca_atlas = Vector2i(pecas.find(prox_peca), 0)
			
			proxima_peca_sorteada.emit(prox_peca, prox_peca_atlas)
			
			criar_peca()

#func fixar_peca()


func pode_mover(direcao):
	# verifica se tem espaço para se mover
	var resposta = true
	for i in peca_ativa:
		if not posicao_esta_livre(i + pos_atual + direcao):
			resposta = false
	return resposta

func pode_rotacionar():
	var resposta = true
	var var_indice_rotacao = (indice_rotacao + 1) % 4
	for i in obter_rotacoes(peca)[var_indice_rotacao]:
		if not posicao_esta_livre(i + pos_atual):
			resposta = false
	return resposta


func posicao_esta_livre(posicao):
	# verifica se a posição pertence à peça atual
	for bloco in peca_ativa:
		if pos_atual + bloco == posicao:
			return true

	# se não pertence à peça atual, verifica se existe algum tile nessa posição
	return get_cell_source_id(posicao) == -1


func identificar_e_tratar_linhas_completas():
	var linha : int = LINHAS
	var linhas_apagadas: int = 0
	
	while linha > 0:
		var cont = 0
		for i in range(COLUNAS):
			if get_cell_source_id(Vector2i(i + 1, linha)) != -1:
				cont += 1
		if cont == COLUNAS:
			deslocar_linhas(linha)
			linhas_apagadas += 1
		else:
			linha -= 1
	
	if linhas_apagadas > 0:
		linhas_destruidas.emit(linhas_apagadas)

# desloca linhas para baixo a partir de uma linha (inclusive todas as linhas acima dela)
func deslocar_linhas(linha):
	var atlas
	for i in range(linha, 1, -1):
		for j in range(COLUNAS):
			atlas = get_cell_atlas_coords(Vector2i(j + 1, i - 1))
			if atlas == Vector2i(-1, -1):
				erase_cell(Vector2i(j + 1, i))
			else:
				set_cell(Vector2i(j + 1, i), tile_id, atlas)

func limpar_grid():
	for i in range(LINHAS):
		for j in range(COLUNAS):
			erase_cell(Vector2i(j + 1, i + 1))
