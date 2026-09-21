
extends TileMapLayer

signal fim_de_jogo
signal jogo_iniciado
signal linhas_destruidas(quantidade: int)

@export var pecas: Array[Peca]

# variaveis da grade(tabuleiro)
const colunas : int = 10
const linhas : int = 20

# variaveis de movimentação
const direcoes := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var etapas : Array
const total_etapas : int = 50
var pos_inicial := Vector2i(5, 1)
var pos_atual : Vector2i
@export var velocidade : float = 1.0

# variaveis das peças no jogo
var tipo_peca: Peca
var prox_tipo_peca: Peca
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
	novo_jogo()

func novo_jogo():
	jogo_rodando = true
	etapas = [0, 0, 0] #0 esquerda #1 direita #2 baixo
	
	jogo_iniciado.emit()
	
	limpar_peca()
	limpar_grid()
	limpar_painel()
	
	pecas_disponiveis = pecas.duplicate()
	tipo_peca = peca_escolhida()
	peca_atlas = Vector2i(pecas.find(tipo_peca), 0)
	prox_tipo_peca = peca_escolhida()
	prox_peca_atlas = Vector2i(pecas.find(prox_tipo_peca), 0)
	
	criar_peca()

func peca_escolhida():
	# retorna uma peça, embaralha o vetor de peças e pega o primeiro
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


func _process(delta: float) -> void:
	if jogo_rodando:
		if Input.is_action_pressed("mover_esquerda"):
			etapas[0] += 5
		if Input.is_action_pressed("mover_direita"):
			etapas[1] += 5
		if Input.is_action_pressed("acelerar_queda"):
			etapas[2] += 5
		if Input.is_action_just_pressed("rotacionar_peca"):
			rotacionar_peca()
		
		# queda da peça com o passar do tempo
		etapas[2] += velocidade
		
		# mover a peça
		for i in range(etapas.size()):
			if etapas[i] >= total_etapas:
				mover_peca(direcoes[i])
				etapas[i] = 0

func criar_peca():
	etapas = [0, 0, 0]
	pos_atual = pos_inicial
	indice_rotacao = 0
	peca_ativa = obter_rotacoes(tipo_peca)[0]
	
	if not pode_criar_peca():
		fim_de_jogo.emit()
		jogo_rodando = false
		return
		
	desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	desenhar_peca(obter_rotacoes(prox_tipo_peca)[0], Vector2i(16.5,3), prox_peca_atlas)

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

func rotacionar_peca():
	if pode_rotacionar():
		limpar_peca()
		indice_rotacao = (indice_rotacao + 1) % 4
		peca_ativa = obter_rotacoes(tipo_peca)[indice_rotacao]
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)

func zerar_rotacao():
	indice_rotacao = 0

func mover_peca(direcao):
	if pode_mover(direcao):
		limpar_peca()
		pos_atual += direcao
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	else:
		if direcao == Vector2i.DOWN:
			verificar_linhas()
			tipo_peca = prox_tipo_peca
			peca_atlas = prox_peca_atlas
			prox_tipo_peca = peca_escolhida()
			prox_peca_atlas = Vector2i(pecas.find(prox_tipo_peca), 0)
			
			limpar_painel()
			criar_peca()

func pode_mover(direcao):
	# verifica se tem espaço para se mover
	var resposta = true
	for i in peca_ativa:
		if not esta_livre(i + pos_atual + direcao):
			resposta = false
	return resposta

func pode_rotacionar():
	var resposta = true
	var var_indice_rotacao = (indice_rotacao + 1) % 4
	for i in obter_rotacoes(tipo_peca)[var_indice_rotacao]:
		if not esta_livre(i + pos_atual):
			resposta = false
	return resposta

func esta_livre(posicao):
	# verifica se a posição pertence à peça atual
	for bloco in peca_ativa:
		if pos_atual + bloco == posicao:
			return true

	# se não pertence à peça atual,
	# verifica se existe algum tile nessa posição
	return get_cell_source_id(posicao) == -1

func limpar_painel():
	for i in range(14, 21):
		for j in range(2, 9):
			erase_cell(Vector2i(i, j))

func verificar_linhas():
	var linha : int = linhas
	var linhas_apagadas: int = 0
	
	while linha > 0:
		var cont = 0
		for i in range(colunas):
			if get_cell_source_id(Vector2i(i + 1, linha)) != -1:
				cont += 1
		if cont == colunas:
			deslocar_linhas(linha)
			linhas_apagadas += 1
		else:
			linha -= 1
	
	if linhas_apagadas > 0:
		linhas_destruidas.emit(linhas_apagadas)

func deslocar_linhas(linha):
	var atlas
	for i in range(linha, 1, -1):
		for j in range(colunas):
			atlas = get_cell_atlas_coords(Vector2i(j + 1, i - 1))
			if atlas == Vector2i(-1, -1):
				erase_cell(Vector2i(j + 1, i))
			else:
				set_cell(Vector2i(j + 1, i), tile_id, atlas)

func limpar_grid():
	for i in range(linhas):
		for j in range(colunas):
			erase_cell(Vector2i(j + 1, i + 1))
