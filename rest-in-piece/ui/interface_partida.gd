@tool
extends Control

const LARGURA_PAINEL: float = 272.0
const ESPACO: float = 32.0
const TAMANHO_TABULEIRO_PADRAO := Vector2(491.52, 901.12)

var _hud: CanvasLayer


func _ready() -> void:
	_hud = get_parent() as CanvasLayer
	get_viewport().size_changed.connect(_organizar)
	for nome in ["Perdeu", "Venceu", "LabelVocePassouDeFase", "PainelRecompensas"]:
		_hud.get_node(nome).visibility_changed.connect(_sincronizar_modal)
	_organizar.call_deferred()
	_sincronizar_modal.call_deferred()


func _organizar() -> void:
	if _hud == null:
		return
	var tela: Vector2 = get_viewport_rect().size
	var tabuleiro: TileMapLayer = _hud.get_parent().get_node_or_null("TabuleiroTileMap") as TileMapLayer
	var tamanho: Vector2 = TAMANHO_TABULEIRO_PADRAO
	if tabuleiro != null:
		tamanho = Vector2(12, 22) * Vector2(tabuleiro.tile_set.tile_size) * tabuleiro.scale
	var origem := Vector2((tela.x - tamanho.x) / 2.0, maxf(136.0, (tela.y - tamanho.y) / 2.0))
	# Apenas a posicao visual muda; escala, tiles e coordenadas logicas permanecem intactos.
	if tabuleiro != null and not Engine.is_editor_hint():
		tabuleiro.position = origem
	var esquerdo := Vector2(origem.x - ESPACO - LARGURA_PAINEL, origem.y)
	var direito := Vector2(origem.x + tamanho.x + ESPACO, origem.y)
	_definir_rect("FundoInterface/Fundo", Vector2.ZERO, tela)
	_definir_rect("FundoInterface/MolduraTabuleiro", origem - Vector2(6, 6), tamanho + Vector2(12, 12))
	_definir_rect("LabelFaseAtual", direito - Vector2(0, 74), Vector2(LARGURA_PAINEL, 36))
	_definir_rect("LabelReliquias", origem - Vector2(0, 126), Vector2(tamanho.x, 24))
	_definir_rect("PanelContainer", origem - Vector2(0, 96), Vector2(tamanho.x, 80))
	_definir_rect("Panel2", esquerdo, Vector2(LARGURA_PAINEL, 176))
	_definir_rect("PainelPontuacao", esquerdo + Vector2(0, 192), Vector2(LARGURA_PAINEL, 196))
	_definir_rect("Panel", direito, Vector2(LARGURA_PAINEL, 256))
	_definir_rect("PainelReserva", direito + Vector2(0, 272), Vector2(LARGURA_PAINEL, 176))
	var tooltip: Control = _hud.get_node("PainelInfoReliquia")
	tooltip.position = esquerdo + Vector2(0, 412)
	tooltip.custom_minimum_size.x = LARGURA_PAINEL
	tooltip.size.x = LARGURA_PAINEL
	_definir_rect("Veu", Vector2.ZERO, tela)
	var centro := origem + tamanho / 2.0
	_definir_rect("PainelResultado", centro - Vector2(230, 150), Vector2(460, 300))
	for nome in ["Perdeu", "Venceu", "LabelVocePassouDeFase"]:
		_definir_rect(nome, centro - Vector2(206, 112), Vector2(412, 124))
	_definir_rect("Botão novo jogo", centro + Vector2(-140, 48), Vector2(280, 64))
	var recompensas: Control = _hud.get_node("PainelRecompensas")
	recompensas.size = Vector2(1250, 640)
	recompensas.position = tela / 2.0 - recompensas.size / 2.0
	if not Engine.is_editor_hint():
		_hud.centralizar_previas()
		_hud.ajustar_valores_numericos()


func _definir_rect(caminho: String, posicao: Vector2, dimensoes: Vector2) -> void:
	var controle: Control = _hud.get_node(caminho) as Control
	controle.position = posicao
	controle.size = dimensoes


func _sincronizar_modal() -> void:
	if _hud == null:
		return
	var resultado: bool = _hud.get_node("Perdeu").visible or _hud.get_node("Venceu").visible
	var transicao: bool = _hud.get_node("LabelVocePassouDeFase").visible
	var recompensa: bool = _hud.get_node("PainelRecompensas").visible
	_hud.get_node("Veu").visible = resultado or transicao or recompensa
	_hud.get_node("PainelResultado").visible = resultado or transicao
