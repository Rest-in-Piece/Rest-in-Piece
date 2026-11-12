

# um menu de recompensa de peças: 3 cards + "Pular". Guarda a escolha, mas não adiciona nada
# à bolsa (isso só acontece quando o painel confirma).

class_name PaginaRecompensaPecas
extends Control

signal selecao_alterada

@onready var container_cartoes: Container = %Cartoes
@onready var botao_pular: Button = %BotaoPular

var cartoes: Array[RecompensaCard] = []
var peca_selecionada: Peca = null  # nula com "Pular" marcado ou sem escolha


func _ready() -> void:
	for filho in container_cartoes.get_children():
		var cartao := filho as RecompensaCard
		if cartao == null:
			continue
		cartoes.append(cartao)
		cartao.escolhido.connect(_on_cartao_escolhido)
	botao_pular.toggled.connect(_on_pular_alternado)


func exibir(pecas: Array, tile_set: TileSet) -> void:
	peca_selecionada = null
	botao_pular.set_pressed_no_signal(false)
	for i in range(cartoes.size()):
		var tem_peca: bool = i < pecas.size()
		cartoes[i].visible = tem_peca
		if tem_peca:
			cartoes[i].configurar_peca(pecas[i], tile_set)


func habilitar() -> void:
	for cartao in cartoes:
		cartao.habilitar()


func tem_selecao() -> bool:
	return peca_selecionada != null or botao_pular.button_pressed


# nula quando o jogador pulou
func obter_peca_escolhida() -> Peca:
	return peca_selecionada


func _on_cartao_escolhido(cartao_escolhido: RecompensaCard) -> void:
	peca_selecionada = cartao_escolhido.peca
	botao_pular.set_pressed_no_signal(false)
	for cartao in cartoes:
		cartao.definir_selecionado(cartao == cartao_escolhido)
	selecao_alterada.emit()


func _on_pular_alternado(ativo: bool) -> void:
	if ativo:
		peca_selecionada = null
		for cartao in cartoes:
			cartao.definir_selecionado(false)
	selecao_alterada.emit()
