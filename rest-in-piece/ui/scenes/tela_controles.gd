extends Control

signal fechou

const COMANDOS: Array[Array] = [
	["Pausar ou retomar o jogo", "pausar"],
	["Mover para a esquerda", "mover_esquerda"],
	["Mover para a direita", "mover_direita"],
	["Rotacionar no sentido horário", "rotacionar_sentido_horario"],
	["Rotacionar no sentido anti-horário", "rotacionar_sentido_anti_horario"],
	["Acelerar a queda", "acelerar_queda"],
	["Queda imediata", "cair_imediatamente"],
	["Armazenar ou trocar uma peça", "armazenar_peca"],
	["Materializar a peça Fantasma", "materializar_fantasma"],
]
const NOMES_TECLAS: Dictionary = {
	KEY_ESCAPE: "Esc",
	KEY_SPACE: "Espaço",
	KEY_LEFT: "←",
	KEY_RIGHT: "→",
	KEY_UP: "↑",
	KEY_DOWN: "↓",
}

@onready var painel: PanelContainer = $Painel
@onready var lista: VBoxContainer = %ListaComandos
@onready var rolagem: ScrollContainer = %Rolagem
@onready var botao_voltar: Button = %Voltar


func _ready() -> void:
	botao_voltar.pressed.connect(fechar)
	resized.connect(_ajustar_painel)
	_ajustar_painel()
	for comando in COMANDOS:
		var teclas: Array[String] = []
		# A consulta ao InputMap mantém a tela fiel às teclas configuradas no projeto.
		for evento in InputMap.action_get_events(comando[1]):
			if evento is InputEventKey:
				var codigo: int = evento.physical_keycode if evento.physical_keycode != 0 else evento.keycode
				var nome: String = NOMES_TECLAS.get(codigo, OS.get_keycode_string(codigo))
				if not teclas.has(nome):
					teclas.append(nome)
		_criar_linha(comando[0], teclas)
	_criar_linha("Selecionar recompensas e botões", ["Botão esquerdo do mouse"])


func abrir() -> void:
	show()
	_ajustar_painel()
	rolagem.scroll_vertical = 0
	botao_voltar.grab_focus()


func fechar() -> void:
	if not visible:
		return
	hide()
	fechou.emit()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("pausar"):
		fechar()
		get_viewport().set_input_as_handled()


func _ajustar_painel() -> void:
	var tamanho := Vector2(minf(1120.0, maxf(0.0, size.x - 64.0)), minf(920.0, maxf(0.0, size.y - 64.0)))
	painel.size = tamanho
	painel.position = (size - tamanho) / 2.0


func _criar_linha(acao: String, teclas: Array[String]) -> void:
	var linha := PanelContainer.new()
	linha.custom_minimum_size.y = 54.0
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.0, 0.243137, 0.309804, 0.4)
	fundo.content_margin_left = 16.0
	fundo.content_margin_right = 16.0
	fundo.content_margin_top = 8.0
	fundo.content_margin_bottom = 8.0
	fundo.set_corner_radius_all(4)
	linha.add_theme_stylebox_override("panel", fundo)
	lista.add_child(linha)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 24)
	linha.add_child(colunas)
	var label := Label.new()
	label.text = acao
	label.theme_type_variation = &"Claro"
	label.add_theme_font_size_override("font_size", 22)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colunas.add_child(label)
	var atalhos := HFlowContainer.new()
	atalhos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atalhos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	atalhos.add_theme_constant_override("h_separation", 10)
	colunas.add_child(atalhos)
	colunas.resized.connect(func():
		var largura_coluna: float = maxf(0.0, (colunas.size.x - 24.0) / 2.0)
		label.custom_minimum_size.x = largura_coluna
		atalhos.custom_minimum_size.x = largura_coluna
	)
	for i in range(teclas.size()):
		if i > 0:
			var separador := Label.new()
			separador.text = "ou"
			separador.theme_type_variation = &"Secundario"
			separador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			atalhos.add_child(separador)
		_criar_tecla(atalhos, teclas[i])


func _criar_tecla(atalhos: Control, texto: String) -> void:
	var tecla := PanelContainer.new()
	tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.4, 0.196078, 0.298039, 1.0)
	estilo.content_margin_left = 12.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_top = 3.0
	estilo.content_margin_bottom = 3.0
	estilo.set_corner_radius_all(4)
	tecla.add_theme_stylebox_override("panel", estilo)
	atalhos.add_child(tecla)
	var label := Label.new()
	label.text = texto
	label.theme_type_variation = &"TextoPixel"
	label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.99, 1.0))
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tecla.add_child(label)
