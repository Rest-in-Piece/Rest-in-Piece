extends CanvasLayer

const CAMINHO_MENU_PRINCIPAL: String = "res://ui/menu_inicial.tscn"

@onready var tabuleiro: TileMapLayer = $"../TabuleiroTileMap"
@onready var aviso: Label = $AvisoPausa
@onready var tela_pausa: Control = $TelaPausa
@onready var botao_retomar: Button = %RetomarJogo
@onready var botao_menu: Button = %VoltarAoMenu
@onready var botao_sair: Button = %SairDoJogo


func _ready() -> void:
	botao_retomar.pressed.connect(retomar_jogo)
	botao_menu.pressed.connect(voltar_ao_menu)
	botao_sair.pressed.connect(sair_do_jogo)


func _process(_delta: float) -> void:
	aviso.visible = tabuleiro.jogo_rodando and not tela_pausa.visible


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pausar"):
		return
	if tela_pausa.visible:
		retomar_jogo()
	elif tabuleiro.jogo_rodando and not get_tree().paused:
		pausar_jogo()
	else:
		return
	get_viewport().set_input_as_handled()


func pausar_jogo() -> void:
	if tela_pausa.visible or not tabuleiro.jogo_rodando or get_tree().paused:
		return
	# Só esta camada continua ativa; tabuleiro, relíquias, animações e áudio pausam juntos.
	get_tree().paused = true
	aviso.hide()
	tela_pausa.show()
	botao_retomar.grab_focus()


func retomar_jogo() -> void:
	if not tela_pausa.visible:
		return
	tela_pausa.hide()
	get_tree().paused = false


func voltar_ao_menu() -> void:
	if not tela_pausa.visible:
		return
	var arvore: SceneTree = get_tree()
	arvore.paused = false
	var erro: Error = arvore.change_scene_to_file(CAMINHO_MENU_PRINCIPAL)
	if erro != OK:
		arvore.paused = true
		push_error("Não foi possível abrir o menu principal: %s" % error_string(erro))


func sair_do_jogo() -> void:
	if tela_pausa.visible:
		get_tree().paused = false
		get_tree().quit()


func _exit_tree() -> void:
	if tela_pausa.visible:
		get_tree().paused = false
