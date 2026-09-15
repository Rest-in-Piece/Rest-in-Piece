
extends TileMapLayer

@onready var label_pontuacao: Label = $HUD/Pontuação
@onready var hud: CanvasLayer = $HUD


# peças do tetris
# aqui instaciamos as peças existentes
# as coordenadas são os pontos da peça da matriz 
# rotações da peça ( 0 graus, 90 graus, 180 graus e 270 graus)

# peça reta em formato de I
var i_0 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
var i_90 := [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)]
var i_180 := [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
var i_270 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
var i := [i_0, i_90, i_180, i_270]

# peça em formato de T 
var t_0 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var t_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var t_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var t_270 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
var t := [t_0, t_90, t_180, t_270]

# peça quadrada
var o_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_90 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_180 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o_270 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
var o := [o_0, o_90, o_180, o_270]

# peça em formato de Z 
var z_0 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
var z_90 := [Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]
var z_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]
var z_270 := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
var z := [z_0, z_90, z_180, z_270]

# outra peça em formato de Z invertido
var s_0 := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]
var s_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
var s_180 := [Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)]
var s_270 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]
var s := [s_0, s_90, s_180, s_270]

# Peça que parece o número 1 invertido
var l_0 := [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var l_90 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)]
var l_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)]
var l_270 := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]
var l := [l_0, l_90, l_180, l_270]

# peça que parece o número 1
var j_0 := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
var j_90 := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]
var j_180 := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)]
var j_270 := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
var j := [j_0, j_90, j_180, j_270]

var pecas := [i, t, o , z, s, l, j]
var todas_pecas := pecas.duplicate()

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
var tipo_peca
var prox_tipo_peca
var indice_rotacao : int = 0
var peca_ativa : Array

var pontuacao: int
@export var recompensa: int = 100

# variaveis pro tileMap
var tile_id : int = 0
var peca_atlas : Vector2i
var prox_peca_atlas : Vector2i


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	novo_jogo()
	print(label_pontuacao)

func novo_jogo():
	etapas = [0, 0, 0] #0 esquerda #1 direita #2 baixo
	hud.get_node("Perdeu").hide()
	tipo_peca = peca_escolhida()
	peca_atlas = Vector2i(todas_pecas.find(tipo_peca), 0)
	prox_tipo_peca = peca_escolhida()
	prox_peca_atlas = Vector2i(todas_pecas.find(tipo_peca), 0)
	criar_peca()

func peca_escolhida():
	# retorna uma peça, embaralha o vetor de peças e pega o primeiro
	var p
	if not pecas.is_empty():
		pecas.shuffle()
		p = pecas.pop_front()
	else:
		pecas = todas_pecas.duplicate()
		pecas.shuffle()
		p = pecas.pop_front()
	return p

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	peca_ativa = tipo_peca[0]
	desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	#mostra a proxima peça
	desenhar_peca(prox_tipo_peca[0], Vector2i(15,6), prox_peca_atlas)

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
		peca_ativa = tipo_peca[indice_rotacao]
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
			prox_peca_atlas = Vector2i(todas_pecas.find(tipo_peca), 0)
			limpar_painel()
			criar_peca()


func pode_mover(direcao):
	#verifica se tem espaço para se mover
	var resposta = true
	for i in peca_ativa:
		if not esta_livre(i + pos_atual + direcao):
			resposta = false
	return resposta

func pode_rotacionar():
	var resposta = true
	var var_indice_rotacao = (indice_rotacao + 1) % 4
	for i in tipo_peca[var_indice_rotacao]:
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
	for i in range(14, 19):
		for j in range(5, 9):
			erase_cell(Vector2i(i, j))

func verificar_linhas():
	var linha : int = linhas
	while linha > 0:
		var cont = 0
		for i in range(colunas):
			# AQUI
			if get_cell_source_id(Vector2i(i + 1, linha)) != -1:
				cont += 1
		if cont == colunas:
			deslocar_linhas(linha)
			pontuacao += recompensa
			label_pontuacao.text = str("PONTUAÇÃO: " + str(pontuacao))
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
	
	
	
