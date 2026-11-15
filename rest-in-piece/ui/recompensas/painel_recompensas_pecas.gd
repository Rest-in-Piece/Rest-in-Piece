

# tela de recompensa de peças. Tem duas telas internas, com troca animada:
#   CONJUNTOS: três conjuntos (um tipo especial cada). O jogador escolhe UM e confirma,
#              pula, ou vai para a tela de remover.
#   REMOVER:   as peças da bolsa. O jogador escolhe uma e confirma, ou volta aos conjuntos.
# Não sabe o que as escolhas fazem: só entrega o resultado (conjunto_confirmado /
# remocao_confirmada). Não há como voltar da tela de CONJUNTOS para a escolha do tipo de
# recompensa.

class_name PainelRecompensasPecas
extends Control

# lista vazia = o jogador pulou
signal conjunto_confirmado(pecas: Array[Peca])
signal remocao_confirmada(peca: Peca)

enum Tela { CONJUNTOS, REMOVER }

const DURACAO_ENTRADA: float = 0.4
const DURACAO_SAIDA: float = 0.25
const DURACAO_TROCA: float = 0.35
const ESCALA_INICIAL: Vector2 = Vector2(0.85, 0.85)
## a remoção é bloqueada se a bolsa ficaria com menos peças que isso
const PECAS_MINIMAS_NA_BOLSA: int = 1
const TAMANHO_BOTAO_PECA: Vector2 = Vector2(170, 150)
const TAMANHO_TEXTURA_PECA: Vector2 = Vector2(120, 80)

@onready var area_telas: Control = %AreaTelas
@onready var tela_conjuntos: Control = %TelaConjuntos
@onready var tela_remover: Control = %TelaRemover
@onready var container_conjuntos: Container = %Conjuntos
@onready var grade_bolsa: GridContainer = %GradeBolsa
@onready var label_titulo: Label = %LabelTitulo
@onready var botao_pular: Button = %BotaoPular
@onready var botao_remover: Button = %BotaoRemover
@onready var botao_voltar: Button = %BotaoVoltar
@onready var botao_confirmar: Button = %BotaoConfirmar

var cartoes: Array[ConjuntoRecompensa] = []
var conjunto_selecionado: ConjuntoRecompensa = null

var _tela_atual: Tela = Tela.CONJUNTOS
var _trocando: bool = false
var _bolsa: Array[Peca] = []
var _grupo_bolsa: ButtonGroup
var _peca_para_remover: Peca = null
var _tile_set: TileSet


func _ready() -> void:
	for filho in container_conjuntos.get_children():
		var cartao := filho as ConjuntoRecompensa
		if cartao == null:
			push_error("painel de peças: o filho '%s' de Conjuntos não é um ConjuntoRecompensa" % filho.name)
			continue
		cartoes.append(cartao)
		cartao.escolhido.connect(_on_conjunto_escolhido)
	
	botao_pular.toggled.connect(_on_pular_alternado)
	botao_remover.pressed.connect(_ir_para.bind(Tela.REMOVER))
	botao_voltar.pressed.connect(_ir_para.bind(Tela.CONJUNTOS))
	botao_confirmar.pressed.connect(_on_confirmar_pressionado)
	hide()


# "bolsa" são as peças que o jogador possui (as MESMAS instâncias da bolsa do GameManager)
func exibir(conjuntos: Array[ConjuntoDePecas], bolsa: Array[Peca], tile_set: TileSet) -> void:
	print("[painel de peças] cartões: %d | conjuntos: %d | bolsa: %d" % [cartoes.size(), conjuntos.size(), bolsa.size()])
	_bolsa = bolsa
	_tile_set = tile_set
	_tela_atual = Tela.CONJUNTOS
	_trocando = false
	conjunto_selecionado = null
	_peca_para_remover = null
	botao_pular.set_pressed_no_signal(false)
	
	for i in range(cartoes.size()):
		var tem_conjunto: bool = i < conjuntos.size()
		cartoes[i].visible = tem_conjunto
		if tem_conjunto:
			var conjunto: ConjuntoDePecas = conjuntos[i]
			cartoes[i].configurar(conjunto.nome_do_tipo, conjunto.descricao, conjunto.pecas, tile_set)
	
	_preparar_grade_bolsa()
	tela_conjuntos.position.x = 0.0
	tela_conjuntos.show()
	tela_remover.position.x = 0.0
	tela_remover.hide()
	_atualizar_interface()
	
	modulate.a = 0.0
	scale = ESCALA_INICIAL
	show()
	pivot_offset = size / 2.0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, DURACAO_ENTRADA)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, DURACAO_ENTRADA) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	for cartao in cartoes:
		cartao.habilitar()


func ocultar_com_animacao() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DURACAO_SAIDA)
	await tween.finished
	hide()


func esconder() -> void:
	hide()


# ---------- troca de tela ----------

func _obter_tela(tela: Tela) -> Control:
	return tela_conjuntos if tela == Tela.CONJUNTOS else tela_remover


# ir para REMOVER: a tela atual sai pela esquerda e a nova entra pela direita. Voltar inverte
func _ir_para(destino: Tela) -> void:
	if _trocando or destino == _tela_atual:
		return
	_trocando = true
	
	var saindo: Control = _obter_tela(_tela_atual)
	var entrando: Control = _obter_tela(destino)
	var largura: float = area_telas.size.x * (1.0 if destino == Tela.REMOVER else -1.0)
	
	entrando.position.x = largura
	entrando.show()
	_tela_atual = destino
	_atualizar_interface()
	
	var tween := create_tween().set_parallel(true) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(saindo, "position:x", -largura, DURACAO_TROCA)
	tween.tween_property(entrando, "position:x", 0.0, DURACAO_TROCA)
	await tween.finished
	
	saindo.hide()
	saindo.position.x = 0.0
	_trocando = false
	_atualizar_interface()


# ---------- tela de remover ----------

func _preparar_grade_bolsa() -> void:
	for filho in grade_bolsa.get_children():
		grade_bolsa.remove_child(filho)
		filho.queue_free()
	
	_grupo_bolsa = ButtonGroup.new()
	_grupo_bolsa.allow_unpress = true
	
	# ordenadas só pra exibir; as instâncias são as mesmas da bolsa
	var ordenadas: Array[Peca] = _bolsa.duplicate()
	ordenadas.sort_custom(func(a: Peca, b: Peca) -> bool:
		return a.obter_nome_para_exibicao() < b.obter_nome_para_exibicao())
	
	for peca in ordenadas:
		grade_bolsa.add_child(_criar_botao_peca(peca))


func _criar_botao_peca(peca: Peca) -> Button:
	var botao := Button.new()
	botao.toggle_mode = true
	botao.button_group = _grupo_bolsa
	botao.custom_minimum_size = TAMANHO_BOTAO_PECA
	botao.set_meta(&"peca", peca)
	botao.toggled.connect(_on_botao_bolsa_alternado)
	
	var caixa := VBoxContainer.new()
	caixa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_constant_override("separation", 4)
	botao.add_child(caixa)
	
	var textura := TextureRect.new()
	textura.texture = TexturaDePeca.criar(peca, _tile_set)
	textura.self_modulate = peca.obter_cor_visual()
	textura.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	textura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	textura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	textura.custom_minimum_size = TAMANHO_TEXTURA_PECA
	textura.size_flags_vertical = Control.SIZE_EXPAND_FILL
	textura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(textura)
	
	var rotulo := Label.new()
	rotulo.text = peca.obter_nome_para_exibicao()
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(rotulo)
	
	return botao


func _on_botao_bolsa_alternado(_ativo: bool) -> void:
	var botao: BaseButton = _grupo_bolsa.get_pressed_button()
	_peca_para_remover = null
	if botao != null:
		_peca_para_remover = botao.get_meta(&"peca") as Peca
	_atualizar_interface()


# ---------- tela de conjuntos ----------

func _on_conjunto_escolhido(cartao_escolhido: ConjuntoRecompensa) -> void:
	conjunto_selecionado = cartao_escolhido
	botao_pular.set_pressed_no_signal(false)
	for cartao in cartoes:
		cartao.definir_selecionado(cartao == cartao_escolhido)
	_atualizar_interface()


func _on_pular_alternado(ativo: bool) -> void:
	if ativo:
		conjunto_selecionado = null
		for cartao in cartoes:
			cartao.definir_selecionado(false)
	_atualizar_interface()


# ---------- botões ----------

func _tem_selecao() -> bool:
	if _tela_atual == Tela.CONJUNTOS:
		return conjunto_selecionado != null or botao_pular.button_pressed
	return _peca_para_remover != null


func _atualizar_interface() -> void:
	var nos_conjuntos: bool = _tela_atual == Tela.CONJUNTOS
	
	if nos_conjuntos:
		label_titulo.text = "ESCOLHA UM CONJUNTO"
	else:
		label_titulo.text = "REMOVER PEÇA (%d NA BOLSA)" % _bolsa.size()
	
	botao_pular.visible = nos_conjuntos
	botao_remover.visible = nos_conjuntos
	botao_voltar.visible = not nos_conjuntos
	
	botao_remover.disabled = _trocando or _bolsa.size() <= PECAS_MINIMAS_NA_BOLSA
	botao_voltar.disabled = _trocando
	botao_confirmar.disabled = _trocando or not _tem_selecao()


# depois de confirmar, nada mais pode ser clicado enquanto o painel some
func _travar_interface() -> void:
	_trocando = true
	for cartao in cartoes:
		cartao.desabilitar()
	for botao in grade_bolsa.get_children():
		(botao as Button).disabled = true
	botao_pular.disabled = true
	_atualizar_interface()


func _on_confirmar_pressionado() -> void:
	if _trocando or not _tem_selecao():
		return
	
	var tela_da_confirmacao: Tela = _tela_atual
	_travar_interface()
	
	if tela_da_confirmacao == Tela.CONJUNTOS:
		var pecas: Array[Peca] = []
		if conjunto_selecionado != null:
			pecas.assign(conjunto_selecionado.pecas)
		conjunto_confirmado.emit(pecas)
	else:
		remocao_confirmada.emit(_peca_para_remover)
