
# "uma linha fina e pulsante desenha o contorno da região com este efeito (só os lados
# expostos, então peças vizinhas com o mesmo efeito formam um contorno único)"
class_name EfeitoVisualContorno
extends EfeitoVisual

@export var espessura: float = 1.5

const CODIGO: String = """
shader_type canvas_item;

uniform vec2 tamanho = vec2(32.0);
uniform vec4 cor : source_color = vec4(1.0);
uniform float intensidade = 0.5;
uniform float espessura = 1.5;
uniform int bordas = 0;

void fragment() {
	vec2 p = UV * tamanho;
	float e = espessura;
	float linha = 0.0;
	if ((bordas & 1) != 0) { linha = max(linha, 1.0 - smoothstep(e, e + 1.0, p.y)); }
	if ((bordas & 2) != 0) { linha = max(linha, 1.0 - smoothstep(e, e + 1.0, tamanho.x - p.x)); }
	if ((bordas & 4) != 0) { linha = max(linha, 1.0 - smoothstep(e, e + 1.0, tamanho.y - p.y)); }
	if ((bordas & 8) != 0) { linha = max(linha, 1.0 - smoothstep(e, e + 1.0, p.x)); }
	float pulso = 0.7 + 0.3 * sin(TIME * 2.0);
	COLOR = vec4(cor.rgb, cor.a * intensidade * linha * pulso);
}
"""


func usa_bordas() -> bool:
	return true


func ao_criar_celula(celula: Node2D, contexto: ContextoVisual) -> void:
	if contexto.bordas_expostas == 0:
		return
	var quad := criar_quad(celula, contexto.tamanho, obter_shader(CODIGO))
	var material := quad.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("intensidade", intensidade)
	material.set_shader_parameter("espessura", espessura)
	material.set_shader_parameter("bordas", contexto.bordas_expostas)
