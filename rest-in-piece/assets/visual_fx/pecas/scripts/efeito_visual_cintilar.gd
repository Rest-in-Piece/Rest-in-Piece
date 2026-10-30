
# "de tempos em tempos, um brilho diagonal cruza a célula (cada célula no seu ritmo)"
class_name EfeitoVisualCintilar
extends EfeitoVisual

## segundos entre um brilho e o seguinte
@export var intervalo: float = 4.0

const CODIGO: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec2 tamanho = vec2(32.0);
uniform vec4 cor : source_color = vec4(1.0);
uniform float intensidade = 0.5;
uniform float intervalo = 4.0;
uniform float fase = 0.0;

void fragment() {
	float t = fract(TIME / intervalo + fase);
	float ativo = 1.0 - step(0.18, t);
	float pos_faixa = mix(-0.2, 1.2, clamp(t / 0.18, 0.0, 1.0));
	float diag = (UV.x + UV.y) * 0.5;
	float faixa = 1.0 - smoothstep(0.0, 0.12, abs(diag - pos_faixa));
	COLOR = vec4(cor.rgb, cor.a * intensidade * 0.8 * faixa * ativo);
}
"""


func ao_criar_celula(celula: Node2D, contexto: ContextoVisual) -> void:
	var quad := criar_quad(celula, contexto.tamanho, obter_shader(CODIGO))
	var material := quad.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("intensidade", intensidade)
	material.set_shader_parameter("intervalo", intervalo)
	material.set_shader_parameter("fase", contexto.fase)
