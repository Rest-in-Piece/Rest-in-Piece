

@tool
# card de UMA relíquia equipada. SÓ exibe a textura e avisa quando o mouse entra/sai.
# Quem mostra nome e descrição é o HUD. É @tool pra aparecer na prévia do editor.

class_name ReliquiaSlot
extends PanelContainer

signal hover_iniciado(reliquia: Reliquia)
signal hover_encerrado

@onready var textura_rect: TextureRect = %Textura

var reliquia: Reliquia
var _tween_ativacao: Tween


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# o AutoBus não existe no editor, e a prévia só precisa do visual
	if not Engine.is_editor_hint():
		AutoBus.reliquia_ativada.connect(_on_reliquia_ativada)


func configurar(nova_reliquia: Reliquia) -> void:
	reliquia = nova_reliquia
	textura_rect.texture = reliquia.textura


func _on_mouse_entered() -> void:
	if reliquia != null:
		hover_iniciado.emit(reliquia)


func _on_mouse_exited() -> void:
	hover_encerrado.emit()


# o gerenciador emite a MESMA instância que guarda, então comparar referência funciona
func _on_reliquia_ativada(reliquia_ativada: Reliquia) -> void:
	if reliquia_ativada != reliquia:
		return
	
	if _tween_ativacao != null and _tween_ativacao.is_valid():
		_tween_ativacao.kill()
	
	pivot_offset = size / 2.0
	scale = Vector2(1.12, 1.12)
	_tween_ativacao = create_tween()
	_tween_ativacao.tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
