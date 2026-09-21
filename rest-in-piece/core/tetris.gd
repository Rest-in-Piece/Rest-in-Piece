
extends TileMapLayer

@export var hud: CanvasLayer

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
var aceleracao: float = 0.25

# variaveis das peças no jogo
var tipo_peca: Peca
var prox_tipo_peca: Peca
var indice_rotacao : int = 0
var peca_ativa : Array
var pecas_disponiveis: Array[Peca]

var pontuacao: int
@export var recompensa: int = 100

# variaveis pro tileMap
var tile_id : int = 0
var peca_atlas : Vector2i
var prox_peca_atlas : Vector2i


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	novo_jogo()

func novo_jogo():
	etapas = [0, 0, 0] #0 esquerda #1 direita #2 baixo
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
	peca_ativa = obter_rotacoes(tipo_peca)[0]
	desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	desenhar_peca(obter_rotacoes(prox_tipo_peca)[0], Vector2i(16.5,3), prox_peca_atlas) # AQUI: a posição pra desenhar a peça está estática usando pixels

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
	if (pode_mover(direcao)):
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
	while linha > 0:
		var cont = 0
		for i in range(colunas):
			if get_cell_source_id(Vector2i(i + 1, linha)) != -1:
				cont += 1
		if cont == colunas:
			deslocar_linhas(linha)
			pontuacao += recompensa
			hud.atualizar_pontuacao(pontuacao)
			velocidade += aceleracao
			print("Velocidade: ", velocidade)
		else:
			linha -= 1

func deslocar_linhas(linha):
	var atlas
	for i in range(linha, 1, -1):
		for j in range(colunas):
			atlas = get_cell_atlas_coords(Vector2i(j + 1, i - 1))
			if atlas == Vector2i(-1, -1):
				erase_cell(Vector2i(j + 1, i))
			else:
				set_cell(Vector2i(j + 1, i), tile_id, atlas)
