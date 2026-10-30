
# "brasas minúsculas sobem devagar dos lados de cima expostos"
class_name EfeitoVisualBrasas
extends EfeitoVisual


func usa_bordas() -> bool:
	return true


func ao_criar_celula(celula: Node2D, contexto: ContextoVisual) -> void:
	if not contexto.tem_borda(ContextoVisual.TOPO):
		return
	
	var brasas := CPUParticles2D.new()
	brasas.position = Vector2(0.0, -contexto.tamanho.y * 0.5)
	brasas.amount = 5
	brasas.lifetime = 1.8
	brasas.direction = Vector2.UP
	brasas.spread = 12.0
	brasas.initial_velocity_min = 5.0
	brasas.initial_velocity_max = 12.0
	brasas.gravity = Vector2(0.0, -4.0)
	brasas.scale_amount_min = 2.0
	brasas.scale_amount_max = 4.0
	brasas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	brasas.emission_rect_extents = Vector2(contexto.tamanho.x * 0.35, 1.0)
	brasas.color_ramp = gradiente_de_alfa(cor, 0.0, intensidade, 0.0)
	celula.add_child(brasas)
