

class_name EfeitoVisualPulsoBase
extends EfeitoVisual

@export var duracao: float = 0.45

const CODIGO: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec4 cor : source_color = vec4(1.0);
uniform float intensidade = 0.6;
uniform float progresso = 0.0; // Animado de 0 a 1

void fragment() {
	// Centraliza a origem no fundo do UV (x = 0.5, y = 1.0)
	vec2 p = vec2(UV.x - 0.5, UV.y - 1.0);
	float dist = length(p);
	
	// O pulso se expande para fora
	float raio_pulso = progresso * 0.8;
	
	// O pulso afina enquanto cresce
	float espessura = 0.15 * (1.0 - progresso);
	float pulso = 1.0 - smoothstep(0.0, espessura, abs(dist - raio_pulso));
	
	// Corta o pulso no eixo Y para renderizar só a parte da base
	float corte_base = smoothstep(0.6, 0.9, UV.y);
	
	COLOR = vec4(cor.rgb, cor.a * intensidade * pulso * corte_base * (1.0 - progresso));
}
"""

func usa_bordas() -> bool:
	return true

func ao_fixar_celula(contexto: ContextoVisual) -> void:
	# Só aciona nas células que encostam em algo por baixo
	if not contexto.tem_borda(ContextoVisual.BAIXO):
		return
	
	# Tamanho expandido (1.5x) para o pulso poder escapar das bordas do quadrado
	var quad := criar_quad(contexto.camada, contexto.tamanho * 1.5, obter_shader(CODIGO))
	quad.position = contexto.posicao
	
	var material := quad.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("intensidade", intensidade)
	
	animar_e_liberar(quad, material, &"progresso", duracao)
