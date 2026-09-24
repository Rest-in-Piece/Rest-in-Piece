
@tool
extends TileMapLayer

@export var peca_alvo: Resource

@export_category("Ferramentas de Captura")
@export var capturar_angulo_0: bool = false:
	set(valor):
		if valor: _capturar_para_resource("angulo_0")

@export var capturar_angulo_90: bool = false:
	set(valor):
		if valor: _capturar_para_resource("angulo_90")

@export var capturar_angulo_180: bool = false:
	set(valor):
		if valor: _capturar_para_resource("angulo_180")

@export var capturar_angulo_270: bool = false:
	set(valor):
		if valor: _capturar_para_resource("angulo_270")

@export_category("Limpeza")
@export var limpar_grid: bool = false:
	set(valor):
		if valor:
			clear()
			limpar_grid = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

# desenha marcadores que facilitam a definição da origem das peças
func _draw():
	if not Engine.is_editor_hint() or not tile_set:
		return
		
	var tam = tile_set.tile_size
	
	# Quadrado vermelho translúcido na coordenada (0,0).
	# Use este quadrado como o centro exato para as peças T, J, L, S e Z.
	draw_rect(Rect2(Vector2.ZERO, tam), Color(1, 0, 0, 0.3))
	
	# Cruz azul na quina superior esquerda da coordenada (0,0).
	# Use este cruzamento como o centro para posicionar a peça I e a peça O.
	var raio = tam.x * 0.8
	draw_line(Vector2(-raio, 0), Vector2(raio, 0), Color(0, 0.5, 1, 0.8), 3.0)
	draw_line(Vector2(0, -raio), Vector2(0, raio), Color(0, 0.5, 1, 0.8), 3.0)

func _capturar_para_resource(propriedade: String):
	capturar_angulo_0 = false
	capturar_angulo_90 = false
	capturar_angulo_180 = false
	capturar_angulo_270 = false
	
	if not peca_alvo:
		print("GERADOR: Erro! Atribua um ficheiro Resource 'Peca' no inspetor primeiro.")
		return
		
	var celulas_desenhadas = get_used_cells()
	
	if celulas_desenhadas.is_empty():
		print("GERADOR: Aviso! A grelha está vazia. Nada foi guardado.")
		return
		
	if celulas_desenhadas.size() != 4:
		print("GERADOR: Aviso! O Tetraminó deve ter exatamente 4 blocos. Atualmente tem ", celulas_desenhadas.size())
	
	peca_alvo.set(propriedade, celulas_desenhadas)
	ResourceSaver.save(peca_alvo)
	print("GERADOR: Sucesso! Coordenadas gravadas em ", propriedade, " do ficheiro ", peca_alvo.resource_path)
