class_name EfeitoVisualEscuridao
extends EfeitoVisual

## Tempo que a escuridão leva para expandir
@export var duracao: float = 0.6
@export var tempo_dissipacao: float = 0.3	# AQUI

const CODIGO: String = """
shader_type canvas_item;

uniform vec4 cor : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float intensidade = 0.8;
uniform float raio = 0.0; // Animado de 0.0 a 1.0 pelo tween
uniform float dissipacao = 1.0; // AQUI

void fragment() {
	// Distância do centro
	float dist = length(UV - vec2(0.5));
	
	// Cria um círculo preenchido que expande
	float borda = smoothstep(raio - 0.15, raio, dist);
	float alpha = (1.0 - borda) * intensidade;
	
	COLOR = vec4(cor.rgb, cor.a * alpha * dissipacao);	// AQUI
}
"""

func ao_fixar_celula(contexto: ContextoVisual) -> void:
	# Como é um efeito transiente de fixação, desenhamos na camada para não sumir
	# caso a célula original seja limpa imediatamente por limpar linha.
	var quad := criar_quad(contexto.camada, contexto.tamanho, obter_shader(CODIGO))
	quad.position = contexto.posicao
	
	var material := quad.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("intensidade", intensidade)
	material.set_shader_parameter("raio", 0.0)	# AQUI
	material.set_shader_parameter("dissipacao", 1.0)	# AQUI
	
	var tween := quad.create_tween()	# AQUI
	tween.tween_method(	# AQUI
			func(valor: float): material.set_shader_parameter("raio", valor),	# AQUI
			0.0, 1.0, duracao)	# AQUI
	tween.tween_method(	# AQUI
			func(valor: float): material.set_shader_parameter("dissipacao", valor),	# AQUI
			1.0, 0.0, tempo_dissipacao)	# AQUI
	tween.tween_callback(quad.queue_free)	# AQUI
