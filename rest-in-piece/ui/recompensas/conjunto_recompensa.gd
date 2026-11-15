

# card de UM conjunto de peças (título do tipo, três peças e a descrição do efeito). SÓ cuida
# do visual (hover, seleção) e avisa quando o jogador clica. Quem decide o que a escolha
# significa é o GameManager.

class_name ConjuntoRecompensa
extends Control

signal escolhido(conjunto: ConjuntoRecompensa)

const ESCALA_HOVER: Vector2 = Vector2(1.04, 1.04)
const DURACAO_SELECAO: float = 0.15
const DURACAO_HOVER: float = 0.12
const TAMANHO_TEXTURA_PECA: Vector2 = Vector2(96, 96)

@onready var titulo: Label = $Margem/Conteudo/Titulo
@onready var container_pecas: HBoxContainer = $Margem/Conteudo/Pecas
@onready var descricao: Label = $Margem/Conteudo/Descricao
@onready var selecao: Control = $Selecao

var pecas: Array[Peca] = []
var habilitado: bool = false

var _tween_selecao: Tween
var _tween_hover: Tween


func _ready() -> void:
	# só o card recebe o mouse (senão ele perde o hover ao passar por cima dos filhos)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ignorar_mouse_nos_filhos(self)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	_reiniciar_estado()


func configurar(nome_do_tipo: String, texto_descricao: String, novas_pecas: Array[Peca], tile_set: TileSet) -> void:
	print("[conjunto] configurar '%s' com %d peças" % [nome_do_tipo, novas_pecas.size()])
	pecas = novas_pecas
	titulo.text = nome_do_tipo.to_upper()
	descricao.text = texto_descricao
	
	for filho in container_pecas.get_children():
		container_pecas.remove_child(filho)
		filho.queue_free()
	for peca in pecas:
		container_pecas.add_child(_criar_mini_card(peca, tile_set))
	
	_reiniciar_estado()


func habilitar() -> void:
	habilitado = true

func desabilitar() -> void:
	habilitado = false


func definir_selecionado(ativo: bool) -> void:
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	selecao.show()
	_tween_selecao = create_tween()
	_tween_selecao.tween_property(selecao, "modulate:a", 1.0 if ativo else 0.0, DURACAO_SELECAO)
	if not ativo:
		_tween_selecao.tween_callback(selecao.hide)


func _criar_mini_card(peca: Peca, tile_set: TileSet) -> Control:
	var caixa := VBoxContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_constant_override("separation", 6)
	
	var textura := TextureRect.new()
	textura.texture = TexturaDePeca.criar(peca, tile_set)
	textura.self_modulate = peca.obter_cor_visual()
	textura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	textura.custom_minimum_size = TAMANHO_TEXTURA_PECA
	textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(textura)
	
	var rotulo := Label.new()
	rotulo.text = peca.tipo_peca
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.theme_type_variation = &"Claro"
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(rotulo)
	
	return caixa


# volta ao estado inicial (o card pode ter sido selecionado ou ter ficado com hover)
func _reiniciar_estado() -> void:
	if _tween_hover != null and _tween_hover.is_valid():
		_tween_hover.kill()
	if _tween_selecao != null and _tween_selecao.is_valid():
		_tween_selecao.kill()
	scale = Vector2.ONE
	modulate.a = 1.0
	selecao.hide()
	selecao.modulate.a = 0.0
	habilitado = false


func _animar_hover(ativo: bool) -> void:
	if _tween_hover != null and _tween_hover.is_valid():
		_tween_hover.kill()
	pivot_offset = size / 2.0
	_tween_hover = create_tween()
	_tween_hover.tween_property(self, "scale", ESCALA_HOVER if ativo else Vector2.ONE, DURACAO_HOVER) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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
		escolhido.emit(self)
