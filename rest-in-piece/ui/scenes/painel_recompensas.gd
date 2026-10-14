

# tela de recompensas: mostra os cards, anima a entrada e a saída e avisa qual o jogador
# escolheu. Não sabe o que a escolha faz (quem decide é o GameManager, via HUD).
# Quando houver recompensas de peça, entra um método irmão de exibir_reliquias.

class_name PainelRecompensas
extends Control

# a textura de origem é entregue pra o HUD animar o voo até a lista de relíquias
signal reliquia_escolhida(reliquia: Reliquia, textura_origem: TextureRect)

const DURACAO_ENTRADA: float = 0.4
const DURACAO_SAIDA: float = 0.25
const ESCALA_INICIAL: Vector2 = Vector2(0.85, 0.85)

@onready var container_cartoes: Container = $Margem/Recompensas

var cartoes: Array[RecompensaCard] = []


func _ready() -> void:
	for filho in container_cartoes.get_children():
		var cartao := filho as RecompensaCard
		if cartao == null:
			continue
		cartoes.append(cartao)
		cartao.escolhido.connect(_on_cartao_escolhido)
	
	hide()


# usa um card por relíquia; os cards que sobrarem ficam escondidos
func exibir_reliquias(reliquias: Array[Reliquia]) -> void:
	for i in range(cartoes.size()):
		var cartao: RecompensaCard = cartoes[i]
		if i < reliquias.size():
			cartao.configurar(reliquias[i])
			cartao.show()
		else:
			cartao.hide()
	
	modulate.a = 0.0
	scale = ESCALA_INICIAL
	show()
	pivot_offset = size / 2.0
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, DURACAO_ENTRADA)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, DURACAO_ENTRADA) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# os cards só aceitam clique depois da entrada
	for i in range(mini(cartoes.size(), reliquias.size())):
		cartoes[i].habilitar()


func ocultar_com_animacao() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DURACAO_SAIDA)
	await tween.finished
	hide()


func esconder() -> void:
	hide()


func _on_cartao_escolhido(cartao_escolhido: RecompensaCard) -> void:
	for cartao in cartoes:
		cartao.desabilitar()
		if cartao != cartao_escolhido:
			cartao.esmaecer()
	
	reliquia_escolhida.emit(cartao_escolhido.reliquia, cartao_escolhido.textura)
