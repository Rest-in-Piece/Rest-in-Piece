
# "pontos de luz amarelo-esverdeados vagam em volta da célula e piscam"
class_name EfeitoVisualVagalumes
extends EfeitoVisual

## fração das células que ganham vagalumes
@export_range(0.0, 1.0) var densidade: float = 0.5

const CODIGO: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec2 tamanho = vec2(70.0);
uniform vec4 cor : source_color = vec4(0.8, 1.0, 0.4, 1.0);
uniform float intensidade = 0.5;
uniform float fase = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * tamanho;
	float brilho = 0.0;
	for (int i = 0; i < 2; i++) {
		float s = fase * 6.28318 + float(i) * 2.4;
		vec2 centro = vec2(sin(TIME * 0.6 + s * 1.3), cos(TIME * 0.45 + s * 0.7)) * tamanho * 0.32;
		float d = length(p - centro);
		float pisca = pow(0.5 + 0.5 * sin(TIME * 2.2 + s * 3.0), 2.0);
		brilho += (exp(-d * d / 6.0) + 0.25 * exp(-d / 5.0)) * pisca;
	}
	COLOR = vec4(cor.rgb, cor.a * intensidade * clamp(brilho, 0.0, 1.0));
}
"""


func ao_criar_celula(celula: Node2D, contexto: ContextoVisual) -> void:
	if contexto.fase > densidade:
		return
	var quad := criar_quad(celula, contexto.tamanho * 2.2, obter_shader(CODIGO))
	var material := quad.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("intensidade", intensidade)
	material.set_shader_parameter("fase", contexto.fase)
