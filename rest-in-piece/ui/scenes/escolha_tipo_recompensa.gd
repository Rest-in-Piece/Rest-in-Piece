

# menu em que o jogador escolhe o TIPO de recompensa. Só avisa a escolha; quem abre a
# tela de cada tipo é o HUD.

class_name EscolhaTipoRecompensa
extends Control

enum Tipo { RELIQUIA, PECAS }

signal tipo_escolhido(tipo: Tipo)

const DURACAO_ENTRADA: float = 0.4
const DURACAO_SAIDA: float = 0.25
const ESCALA_INICIAL: Vector2 = Vector2(0.85, 0.85)

@onready var botao_reliquia: Button = %BotaoReliquia
@onready var botao_pecas: Button = %BotaoPecas


func _ready() -> void:
	botao_reliquia.pressed.connect(_on_botao_pressionado.bind(Tipo.RELIQUIA))
	botao_pecas.pressed.connect(_on_botao_pressionado.bind(Tipo.PECAS))
	hide()


func exibir() -> void:
	botao_reliquia.disabled = true
	botao_pecas.disabled = true
	modulate.a = 0.0
	scale = ESCALA_INICIAL
	show()
	pivot_offset = size / 2.0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, DURACAO_ENTRADA)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, DURACAO_ENTRADA) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	botao_reliquia.disabled = false
	botao_pecas.disabled = false


func ocultar_com_animacao() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DURACAO_SAIDA)
	await tween.finished
	hide()


func esconder() -> void:
	hide()


func _on_botao_pressionado(tipo: Tipo) -> void:
	botao_reliquia.disabled = true
	botao_pecas.disabled = true
	tipo_escolhido.emit(tipo)
