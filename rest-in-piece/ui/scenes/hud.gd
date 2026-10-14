

# esse script SÓ deve tratar questões relacionadas à atualização da interface.
# O jogador pontuou? O hud.gd atualiza o label com os pontos atuais. Questões
# de lógica, como acionar vitória / derrota, devem ser tratadas em outro lugar.

extends CanvasLayer

signal solicitou_novo_jogo
# o jogador escolheu uma relíquia na tela de recompensas. O GameManager decide o que fazer
signal recompensa_reliquia_escolhida(reliquia: Reliquia)
# as animações de vitória e de recompensa terminaram: o GameManager pode iniciar a próxima fase
signal transicao_de_fase_concluida

const FORMATO_TEXTO_FASE_VENCIDA: String = "%s concluída!"
const DURACAO_ENTRADA_LABEL: float = 0.45
const DURACAO_PERMANENCIA_LABEL: float = 1.2
const DURACAO_SAIDA_LABEL: float = 0.35
const DURACAO_VOO_RELIQUIA: float = 0.55
const PAUSA_APOS_VOO_RELIQUIA: float = 0.35

@onready var label_perdeu: Label = $Perdeu
@onready var label_venceu: Label = $Venceu
@onready var label_fase_vencida: Label = %LabelVocePassouDeFase
@onready var painel_recompensas: PainelRecompensas = %PainelRecompensas
@onready var label_pontuacao: Label = %LabelPontuação
@onready var label_meta: Label = %LabelMeta
@onready var label_pecas: Label = %LabelPecas
@onready var botao_novo_jogo: Button = $"Botão novo jogo"
@onready var tile_map_proxima_peca: TileMapLayer = $ProximaPecaTileMap
@onready var tile_map_peca_armazenada: TileMapLayer = $PecaArmazenadaTileMap
@onready var lista_reliquias: ListaReliquias = %ListaReliquias
@onready var painel_info_reliquia: Control = %PainelInfoReliquia
@onready var label_nome_reliquia: Label = %LabelNomeReliquia
@onready var label_descricao_reliquia: Label = %LabelDescricaoReliquia


func _ready() -> void:
	botao_novo_jogo.pressed.connect(_on_botao_novo_jogo_pressed)
	lista_reliquias.reliquia_hover_iniciado.connect(mostrar_info_reliquia)
	lista_reliquias.reliquia_hover_encerrado.connect(esconder_info_reliquia)
	painel_recompensas.reliquia_escolhida.connect(_on_reliquia_escolhida_no_painel)
	esconder_info_reliquia()
	label_fase_vencida.hide()

func _on_botao_novo_jogo_pressed():
	solicitou_novo_jogo.emit()

func atualizar_pontuacao(valor: int):
	label_pontuacao.text = str(valor)

func atualizar_meta(valor: int):
	label_meta.text = str(valor)

func atualizar_pecas(posicionadas: int, maximas: int):
	label_pecas.text = "%d / %d" % [posicionadas, maximas]

func esconder_telas_de_fim():
	label_perdeu.hide()
	label_venceu.hide()
	label_fase_vencida.hide()
	painel_recompensas.esconder()
	botao_novo_jogo.hide()

func mostrar_tela_derrota():
	label_perdeu.show()
	botao_novo_jogo.show()


# fase vencida, com próxima fase: label animado e, em seguida, a tela de recompensas.
# O fluxo continua quando o jogador escolhe (ver _on_reliquia_escolhida_no_painel)
func mostrar_vitoria_da_fase(nome_da_fase: String, reliquias_oferecidas: Array[Reliquia]) -> void:
	await _animar_label_fase_vencida(nome_da_fase)
	
	# sem nada pra oferecer, segue direto pra próxima fase
	if reliquias_oferecidas.is_empty():
		transicao_de_fase_concluida.emit()
		return
	
	await painel_recompensas.exibir_reliquias(reliquias_oferecidas)


# última fase: não existe próxima, então só oferece recomeçar
func mostrar_vitoria_final(nome_da_fase: String) -> void:
	await _animar_label_fase_vencida(nome_da_fase)
	label_venceu.show()
	botao_novo_jogo.show()


func _animar_label_fase_vencida(nome_da_fase: String) -> void:
	label_fase_vencida.text = FORMATO_TEXTO_FASE_VENCIDA % nome_da_fase
	label_fase_vencida.modulate.a = 0.0
	label_fase_vencida.scale = Vector2(0.6, 0.6)
	label_fase_vencida.show()
	label_fase_vencida.pivot_offset = label_fase_vencida.size / 2.0
	
	var tween := create_tween()
	tween.tween_property(label_fase_vencida, "modulate:a", 1.0, DURACAO_ENTRADA_LABEL)
	tween.parallel().tween_property(label_fase_vencida, "scale", Vector2.ONE, DURACAO_ENTRADA_LABEL) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(DURACAO_PERMANENCIA_LABEL)
	tween.tween_property(label_fase_vencida, "modulate:a", 0.0, DURACAO_SAIDA_LABEL)
	await tween.finished
	
	label_fase_vencida.hide()


func _on_reliquia_escolhida_no_painel(reliquia: Reliquia, textura_origem: TextureRect) -> void:
	var slots_antes: int = lista_reliquias.get_child_count()
	
	# o GameManager adquire a relíquia dentro deste emit (signals são síncronos), e a lista
	# de relíquias já se reconstrói com ela antes da próxima linha
	recompensa_reliquia_escolhida.emit(reliquia)
	
	# se o limite de relíquias impediu a aquisição, não há slot novo pra animar
	var reliquia_entrou: bool = lista_reliquias.get_child_count() > slots_antes
	if reliquia_entrou:
		await _animar_reliquia_ate_a_lista(textura_origem)
	
	await get_tree().create_timer(PAUSA_APOS_VOO_RELIQUIA).timeout
	await painel_recompensas.ocultar_com_animacao()
	transicao_de_fase_concluida.emit()


# a textura do card "voa" até a textura do slot novo, que foi o último a entrar na lista
func _animar_reliquia_ate_a_lista(textura_origem: TextureRect) -> void:
	var slot := lista_reliquias.get_child(-1) as ReliquiaSlot
	if slot == null:
		return
	var textura_destino: TextureRect = slot.textura_rect
	
	# o slot já existe, mas a textura dele só aparece quando a cópia chegar
	textura_destino.modulate.a = 0.0
	
	# o container só calcula a posição dos filhos no fim do quadro
	await get_tree().process_frame
	
	var transformacao_origem: Transform2D = textura_origem.get_global_transform()
	var transformacao_destino: Transform2D = textura_destino.get_global_transform()
	
	var textura_voando := TextureRect.new()
	textura_voando.texture = textura_origem.texture
	textura_voando.texture_filter = textura_origem.texture_filter
	textura_voando.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	textura_voando.stretch_mode = textura_origem.stretch_mode
	textura_voando.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(textura_voando)
	textura_voando.global_position = transformacao_origem.origin
	textura_voando.size = textura_origem.size * transformacao_origem.get_scale()
	
	# a cópia assume o lugar da textura do card
	textura_origem.modulate.a = 0.0
	
	var tamanho_final: Vector2 = textura_destino.size * transformacao_destino.get_scale()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(textura_voando, "global_position", transformacao_destino.origin, DURACAO_VOO_RELIQUIA) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(textura_voando, "size", tamanho_final, DURACAO_VOO_RELIQUIA) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	if is_instance_valid(textura_destino):
		textura_destino.modulate.a = 1.0
	textura_voando.queue_free()


func atualizar_proxima_peca(peca: Peca, atlas_coords: Vector2i):
	tile_map_proxima_peca.clear()
	tile_map_proxima_peca.modulate = peca.obter_cor_visual()
	var pos_central = Vector2i(0, 0)
	for bloco in peca.angulos["0"]:
		tile_map_proxima_peca.set_cell(pos_central + bloco, peca.id_fonte_tiles, atlas_coords)


func atualizar_peca_armazenada(peca: Peca, atlas_coords: Vector2i):
	tile_map_peca_armazenada.clear()
	tile_map_peca_armazenada.modulate = peca.obter_cor_visual() if peca != null else Color.WHITE
	if peca == null:
		return
	var pos_central = Vector2i(0, 0)
	for bloco in peca.angulos["0"]:
		tile_map_peca_armazenada.set_cell(pos_central + bloco, peca.id_fonte_tiles, atlas_coords)


func atualizar_reliquias(reliquias: Array[Reliquia]):
	lista_reliquias.exibir(reliquias)

func mostrar_info_reliquia(reliquia: Reliquia):
	label_nome_reliquia.text = reliquia.nome
	label_descricao_reliquia.text = reliquia.descricao
	painel_info_reliquia.show()

func esconder_info_reliquia():
	painel_info_reliquia.hide()


func limpar_peca_armazenada():
	tile_map_peca_armazenada.clear()
