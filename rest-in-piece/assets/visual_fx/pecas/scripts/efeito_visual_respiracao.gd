
# "o miolo da célula brilha e apaga devagar, como uma respiração"
class_name EfeitoVisualRespiracao
extends EfeitoVisual

## segundos de um ciclo completo
@export var periodo: float = 2.4

const CODIGO: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec2 tamanho = vec2(32.0);
uniform vec4 cor : source_color = vec4(1.0);
uniform float intensidade = 0.5;
uniform float periodo = 2.4;
uniform float fase = 0.0;

void fragment() {
	float onda = 0.5 + 0.5 * sin((TIME / periodo + fase) * 6.28318);
	float miolo = 1.0 - smoothstep(0.1, 0.75, length(UV - vec2(0.5)) * 1.41);
	COLOR = vec4(cor.rgb, cor.a * intensidade * 0.35 * onda * (0.4 + 0.6 * miolo));
}
"""


func ao_criar_celula(celula: Node2D, contexto: ContextoVisual) -> void:
	var quad := criar_quad(celula, contexto.tamanho, obter_shader(CODIGO))
	var material := quad.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("intensidade", intensidade)
	material.set_shader_parameter("periodo", periodo)
	material.set_shader_parameter("fase", contexto.fase * 0.2)
