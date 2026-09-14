extends TileMapLayer

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
const colunas : int = 11
const linhas : int = 21

# variaveis de movimentação
const direcoes := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var etapas : Array
const total_etapas : int = 50
var pos_inicial := Vector2i(5, 1)
var pos_atual : Vector2i
var velocidade : float

# variaveis das peças no jogo
var tipo_peca
var prox_tipo_peca
var indice_rotacao : int = 0
var peca_ativa : Array

# variaveis pro tileMap
var tile_id : int = 0
var peca_atlas : Vector2i
var prox_peca_atlas : Vector2i


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	novo_jogo()

func novo_jogo():
	velocidade = 1.0
	etapas = [0, 0, 0] #0 esquerda #1 direita #2 baixo
	tipo_peca = peca_escolhida()
	peca_atlas = Vector2i(todas_pecas.find(tipo_peca), 0)
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
	if Input.is_action_pressed("ui_left"):
		etapas[0] += 10
	elif Input.is_action_pressed("ui_right"):
		etapas[1] += 10
	elif Input.is_action_pressed("ui_down"):
		etapas[2] += 10
	elif Input.is_action_just_pressed("ui_up"):
		rotacionar_peca()
	etapas[2] += velocidade
	
	# mover a peça
	for i in range(etapas.size()):
		if etapas[i] >= total_etapas:
			mover_peca(direcoes[i])
			etapas[i] = 0
	
func criar_peca():
	etapas = [0, 0, 0]
	pos_atual = pos_inicial
	peca_ativa = tipo_peca[indice_rotacao]
	desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	
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

func mover_peca(direcao):
	if (pode_mover(direcao)):
		limpar_peca()
		pos_atual += direcao
		desenhar_peca(peca_ativa, pos_atual, peca_atlas)
	
func pode_mover(direcao):
	#verifica se tem espaço para se mover
	var resposta = true
	for i in peca_ativa:
		print(i + pos_atual + direcao)
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
	

	
	
	
