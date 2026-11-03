

@tool
# fileira de slots de relíquias (uma do lado da outra). Cria e remove os slots.
# No editor, mostra uma PRÉVIA a partir de "reliquias_de_preview". Os slots da prévia
# não têm owner, então NÃO são salvos na cena. Em jogo, a prévia some e a lista passa a
# ser preenchida pelo HUD. Não adicione outros filhos a este nó: eles seriam apagados.

class_name ListaReliquias
extends HBoxContainer

signal reliquia_hover_iniciado(reliquia: Reliquia)
signal reliquia_hover_encerrado

const CENA_RELIQUIA_SLOT: PackedScene = preload("uid://4ba84tlnc5s8")

## SÓ PARA O EDITOR: arraste os .tres aqui pra montar o visual. Em jogo é ignorado
@export var reliquias_de_preview: Array[Reliquia] = []:
	set(valor):
		reliquias_de_preview = valor
		_atualizar_preview()

## marque pra forçar a atualização da prévia (se o inspetor não atualizar sozinho)
@export var atualizar_preview: bool = false:
	set(valor):
		if valor:
			_atualizar_preview()
		atualizar_preview = false


func _ready() -> void:
	if Engine.is_editor_hint():
		_atualizar_preview()
	else:
		# em jogo a prévia sai: quem manda é o GameManager (via HUD)
		limpar()


func exibir(reliquias: Array[Reliquia]) -> void:
	limpar()
	
	for reliquia in reliquias:
		if reliquia == null:  # elemento vazio no array da prévia
			continue
		
		var slot := CENA_RELIQUIA_SLOT.instantiate() as ReliquiaSlot
		add_child(slot)
		slot.configurar(reliquia)
		slot.hover_iniciado.connect(reliquia_hover_iniciado.emit)
		slot.hover_encerrado.connect(reliquia_hover_encerrado.emit)


func limpar() -> void:
	for slot in get_children():
		remove_child(slot)
		slot.queue_free()
	
	reliquia_hover_encerrado.emit()


func _atualizar_preview() -> void:
	if not is_node_ready() or not Engine.is_editor_hint():
		return
	exibir(reliquias_de_preview)
