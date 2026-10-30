
# "ao travar, a célula dá um clarão curto e levanta poeira pelos lados de baixo"
class_name EfeitoVisualImpacto
extends EfeitoVisual


func usa_bordas() -> bool:
	return true


func ao_fixar_celula(contexto: ContextoVisual) -> void:
	soltar_flash(contexto.camada, contexto.posicao, contexto.tamanho,
			Color(cor.r, cor.g, cor.b, intensidade * 0.4), 0.2)
	
	if not contexto.tem_borda(ContextoVisual.BAIXO):
		return
	
	var poeira := CPUParticles2D.new()
	poeira.position = contexto.posicao + Vector2(0.0, contexto.tamanho.y * 0.5)
	poeira.one_shot = true
	poeira.amount = 10
	poeira.lifetime = 0.45
	poeira.explosiveness = 1.0
	poeira.direction = Vector2.UP
	poeira.spread = 80.0
	poeira.initial_velocity_min = 15.0
	poeira.initial_velocity_max = 35.0
	poeira.gravity = Vector2(0.0, 30.0)
	poeira.scale_amount_min = 4.5
	poeira.scale_amount_max = 8.0
	poeira.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	poeira.emission_rect_extents = Vector2(contexto.tamanho.x * 0.4, 1.0)
	poeira.color_ramp = gradiente_de_alfa(cor, intensidade * 0.6, intensidade * 0.3, 0.0)
	contexto.camada.add_child(poeira)
	poeira.finished.connect(poeira.queue_free)
