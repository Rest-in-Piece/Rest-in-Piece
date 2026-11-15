

# um dos cards da tela de recompensas. SÓ cuida do visual do card (textos, hover) e avisa
# quando o jogador clica. Quem decide o que a escolha significa é o GameManager.
# Os filhos são encontrados pelo começo do nome, então "Fundo1", "Textura1", "Nome1" e
# "Descricao1" funcionam sem renomear.

class_name RecompensaCard
extends Control

signal escolhido(cartao: RecompensaCard)

## desmarque nos cards cuja escolha pode ser trocada depois (recompensa de peças)
@export var desabilitar_ao_escolher: bool = true

const ESCALA_HOVER: Vector2 = Vector2(1.06, 1.06)
const CLAREAR_FUNDO_HOVER: float = 0.15
const DURACAO_SELECAO: float = 0.15
const DURACAO_HOVER: float = 0.12
const DURACAO_ESMAECER: float = 0.2
const OPACIDADE_ESMAECIDA: float = 0.3

var reliquia: Reliquia
var peca: Peca
var habilitado: bool = false

var _tween_selecao: Tween
var _tween_hover: Tween
var _cor_fundo_normal: Color
var _cor_fundo_hover: Color

@onready var fundo: ColorRect = find_child("Fundo*", true, false) as ColorRect
@onready var textura: TextureRect = find_child("Textura*", true, false) as TextureRect
@onready var nome: Label = find_child("Nome*", true, false) as Label
@onready var descricao: Label = find_child("Descricao*", true, false) as Label
@onready var selecao: Control = find_child("Selecao*", true, false) as Control


func _ready() -> void:
	assert(fundo != null and textura != null and nome != null and descricao != null and selecao != null,
			"RecompensaCard precisa dos filhos Fundo*, Textura*, Nome*, Descricao* e Selecao")
	
	_cor_fundo_normal = fundo.color
	_cor_fundo_hover = fundo.color.lightened(CLAREAR_FUNDO_HOVER)
	
	# só o card recebe o mouse: se um filho também recebesse, o card perderia o hover
	# (mouse_exited) toda vez que o ponteiro passasse por cima dele
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ignorar_mouse_nos_filhos(self)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func configurar(nova_reliquia: Reliquia) -> void:
	reliquia = nova_reliquia
	peca = null
	nome.text = reliquia.nome
	descricao.text = reliquia.descricao
	textura.texture = reliquia.textura
	textura.self_modulate = Color.WHITE
	_reiniciar_estado()


func configurar_peca(nova_peca: Peca, tile_set: TileSet) -> void:
	peca = nova_peca
	reliquia = null
	nome.text = peca.obter_nome_para_exibicao()
	descricao.text = peca.descricao
	textura.texture = _criar_textura_da_peca(peca, tile_set)
	textura.self_modulate = peca.obter_cor_visual()
	_reiniciar_estado()


# volta ao estado inicial (o card pode ter sido esmaecido, selecionado ou ter ficado com hover)
func _reiniciar_estado() -> void:
	if _tween_hover != null and _tween_hover.is_valid():
		_tween_hover.kill()
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	scale = Vector2.ONE
	modulate.a = 1.0
	textura.modulate.a = 1.0
	fundo.color = _cor_fundo_normal
	selecao.hide()
	selecao.modulate.a = 0.0
	habilitado = false


func definir_selecionado(ativo: bool) -> void:
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	selecao.show()
	_tween_selecao = create_tween()
	_tween_selecao.tween_property(selecao, "modulate:a", 1.0 if ativo else 0.0, DURACAO_SELECAO)
	if not ativo:
		_tween_selecao.tween_callback(selecao.hide)


# junta os blocos do ângulo 0 numa única imagem (recortando o tile da peça no atlas), então o
# TextureRect centraliza e escala sozinho, sem posicionar nada por código
func _criar_textura_da_peca(peca_alvo: Peca, tile_set: TileSet) -> Texture2D:
	var fonte := tile_set.get_source(peca_alvo.id_fonte_tiles) as TileSetAtlasSource
	if fonte == null or peca_alvo.angulo_0.is_empty():
		return null
	
	var atlas: Image = fonte.texture.get_image()
	if atlas.is_compressed():
		atlas.decompress()
	var regiao: Rect2i = fonte.get_tile_texture_region(peca_alvo.coords_no_atlas)
	
	var minimo: Vector2i = peca_alvo.angulo_0[0]
	var maximo: Vector2i = peca_alvo.angulo_0[0]
	for celula in peca_alvo.angulo_0:
		minimo = Vector2i(mini(minimo.x, celula.x), mini(minimo.y, celula.y))
		maximo = Vector2i(maxi(maximo.x, celula.x), maxi(maximo.y, celula.y))
	var tamanho_em_celulas: Vector2i = maximo - minimo + Vector2i.ONE
	
	var imagem := Image.create(tamanho_em_celulas.x * regiao.size.x,
			tamanho_em_celulas.y * regiao.size.y, false, atlas.get_format())
	for celula in peca_alvo.angulo_0:
		imagem.blit_rect(atlas, regiao, (celula - minimo) * regiao.size)
	return ImageTexture.create_from_image(imagem)


func habilitar() -> void:
	habilitado = true

func desabilitar() -> void:
	habilitado = false


# usado nos cards que NÃO foram escolhidos
func esmaecer() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", OPACIDADE_ESMAECIDA, DURACAO_ESMAECER)


# o container reseta a escala dos filhos quando reorganiza o layout. Como nada muda de
# tamanho durante o hover, a escala se mantém
func _animar_hover(ativo: bool) -> void:
	if _tween_hover != null and _tween_hover.is_valid():
		_tween_hover.kill()
	
	pivot_offset = size / 2.0
	var escala_final: Vector2 = ESCALA_HOVER if ativo else Vector2.ONE
	var cor_final: Color = _cor_fundo_hover if ativo else _cor_fundo_normal
	
	_tween_hover = create_tween().set_parallel(true)
	_tween_hover.tween_property(self, "scale", escala_final, DURACAO_HOVER) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_hover.tween_property(fundo, "color", cor_final, DURACAO_HOVER)


func _ignorar_mouse_nos_filhos(no: Node) -> void:
	for filho in no.get_children():
		var controle := filho as Control
		if controle != null:
			controle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignorar_mouse_nos_filhos(filho)


func _on_mouse_entered() -> void:
	if habilitado:
		_animar_hover(true)

func _on_mouse_exited() -> void:
	if habilitado:
		_animar_hover(false)

func _on_gui_input(evento: InputEvent) -> void:
	if not habilitado:
		return
	
	var clique := evento as InputEventMouseButton
	if clique != null and clique.pressed and clique.button_index == MOUSE_BUTTON_LEFT:
		if desabilitar_ao_escolher:
			habilitado = false
		escolhido.emit(self)
