
# biblioteca dos shaders dos efeitos de ativação das relíquias. Tudo é criado por código:
# cada shader é montado uma vez e reaproveitado (cada efeito cria o próprio ShaderMaterial,
# porque os parâmetros ficam no material, não no shader).
#
# Os shaders de "overlay" (contorno, glow, onda, brilho_caixa) são desenhados em cima de um
# quadrado branco e só usam UV + o uniform "tamanho" (pixels do quadrado). O shader "icone"
# vai no TextureRect da relíquia e junta glitch, dissolução e varredura de brilho.

class_name ShadersDeEfeito
extends RefCounted

const ICONE: StringName = &"icone"
const CONTORNO: StringName = &"contorno"
const GLOW: StringName = &"glow"
const ONDA: StringName = &"onda"
const BRILHO_CAIXA: StringName = &"brilho_caixa"

static var _cache: Dictionary = {}


static func obter(nome: StringName) -> Shader:
	if not _cache.has(nome):
		var shader := Shader.new()
		match nome:
			ICONE:
				shader.code = CODIGO_ICONE
			CONTORNO:
				shader.code = CODIGO_CONTORNO
			GLOW:
				shader.code = CODIGO_GLOW
			ONDA:
				shader.code = CODIGO_ONDA
			BRILHO_CAIXA:
				shader.code = CODIGO_BRILHO_CAIXA
		_cache[nome] = shader
	return _cache[nome] as Shader


# anima um parâmetro float do material por uma sequência de etapas [valor_final, duração],
# partindo de "inicio". Ex: animar(tween, mat, &"intensidade", 0.0, [[1.0, 0.1], [0.0, 0.3]])
static func animar(tween: Tween, material: ShaderMaterial, parametro: StringName, inicio: float, etapas: Array) -> void:
	var atual: float = inicio
	for etapa in etapas:
		var alvo: float = etapa[0]
		var duracao: float = etapa[1]
		tween.tween_method(
				func(valor: float): material.set_shader_parameter(parametro, valor),
				atual, alvo, duracao)
		atual = alvo


# ---------------------------------------------------------------------------------------
# ÍCONE DA RELÍQUIA (glitch + dissolução + varredura de brilho)
# O alfa do ícone é respeitado: o brilho só aparece em cima do desenho, não do fundo.
# O modulate do TextureRect é preservado (capturado no vertex).
# ---------------------------------------------------------------------------------------
const CODIGO_ICONE: String = """
shader_type canvas_item;

uniform vec2 tamanho = vec2(64.0);
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float dissolver : hint_range(0.0, 1.0) = 0.0;
uniform float brilho : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_borda : source_color = vec4(1.0, 0.55, 0.1, 1.0);

varying vec4 cor_mod;
varying vec2 pos_local;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
			mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
			f.y);
}

void vertex() {
	cor_mod = COLOR;
	pos_local = VERTEX;
}

void fragment() {
	vec2 uv = UV;
	vec2 texel = TEXTURE_PIXEL_SIZE;
	float separacao = 0.0;

	// glitch: faixas horizontais deslocadas + canais RGB separados
	if (glitch > 0.0) {
		float passo = floor(TIME * 20.0);
		float faixa = floor(uv.y / (texel.y * 2.0));
		float sorteio = hash(vec2(faixa, passo));
		if (sorteio > 0.72) {
			uv.x += (sorteio - 0.86) * 20.0 * texel.x * glitch;
		}
		separacao = (1.0 + hash(vec2(passo, 3.0)) * 1.5) * texel.x * glitch;
	}

	vec4 meio = texture(TEXTURE, uv);
	vec3 rgb = meio.rgb;
	float alfa = meio.a;

	if (separacao > 0.0) {
		vec4 vermelho = texture(TEXTURE, uv + vec2(separacao, 0.0));
		vec4 azul = texture(TEXTURE, uv - vec2(separacao, 0.0));
		// cada canal só existe onde a sua própria amostra é opaca
		rgb = vec3(
				vermelho.r * step(0.01, vermelho.a),
				meio.g * step(0.01, meio.a),
				azul.b * step(0.01, azul.a));
		alfa = max(vermelho.a, max(meio.a, azul.a));
	}

	// dissolução: ruído por texel corroendo o alfa, com a borda brilhando
	if (dissolver > 0.0) {
		float n = ruido(floor(uv / texel) * 0.5);
		float limite = dissolver * 1.25 - 0.1;
		float d = n - limite;
		if (d < 0.0) {
			alfa = 0.0;
		} else {
			float borda = 1.0 - smoothstep(0.0, 0.14, d);
			rgb = mix(rgb, cor_borda.rgb, borda);
		}
	}

	// varredura de brilho (foil): faixa diagonal com leve arco-íris
	if (brilho > 0.0) {
		vec2 q = pos_local / tamanho;
		float diag = (q.x + q.y) * 0.5;
		float pos_faixa = mix(-0.25, 1.25, brilho);
		float faixa_brilho = 1.0 - smoothstep(0.0, 0.16, abs(diag - pos_faixa));
		vec3 arco = 0.5 + 0.5 * cos(6.28318 * (diag * 1.5 + vec3(0.0, 0.33, 0.67)));
		rgb += mix(vec3(1.0), arco, 0.45) * faixa_brilho * 0.85;
	}

	COLOR = vec4(rgb, alfa) * cor_mod;
}
"""


# ---------------------------------------------------------------------------------------
# OVERLAYS (desenhados em cima de um quadrado branco de "tamanho" pixels)
# "caixa" é o retângulo real do alvo (célula ou card), centralizado no quadrado
# ---------------------------------------------------------------------------------------

# contorno: linha na borda da caixa, pulsando pelo parâmetro "intensidade"
const CODIGO_CONTORNO: String = """
shader_type canvas_item;

uniform vec2 tamanho = vec2(40.0);
uniform vec2 caixa = vec2(32.0);
uniform vec4 cor : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform float espessura = 2.5;

float sdf_caixa(vec2 p, vec2 meia) {
	vec2 d = abs(p) - meia;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * tamanho;
	float sd = sdf_caixa(p, caixa * 0.5);
	float faixa = 1.0 - smoothstep(0.0, 1.0, abs(sd) - espessura * 0.5);
	COLOR = vec4(cor.rgb, faixa * intensidade * cor.a);
}
"""

# glow: preenchimento suave + halo que decai pra fora da caixa (aditivo)
const CODIGO_GLOW: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec2 tamanho = vec2(72.0);
uniform vec2 caixa = vec2(32.0);
uniform vec4 cor : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform float raio = 7.0;

float sdf_caixa(vec2 p, vec2 meia) {
	vec2 d = abs(p) - meia;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * tamanho;
	float sd = sdf_caixa(p, caixa * 0.5);
	float limite = max(min(tamanho.x, tamanho.y) * 0.5 - min(caixa.x, caixa.y) * 0.5, 1.0);
	float brilho_final = 0.0;
	if (sd < 0.0) {
		brilho_final = 0.18 + 0.3 * smoothstep(-8.0, 0.0, sd);
	} else {
		brilho_final = 0.48 * exp(-sd / raio) * (1.0 - smoothstep(0.0, limite, sd));
	}
	COLOR = vec4(cor.rgb, brilho_final * intensidade * cor.a);
}
"""

# onda: anel que se expande do centro e some (aditivo). "progresso" vai de 0 a 1
const CODIGO_ONDA: String = """
shader_type canvas_item;
render_mode blend_add;

uniform vec2 tamanho = vec2(80.0);
uniform vec4 cor : source_color = vec4(1.0, 0.85, 0.35, 1.0);
uniform float progresso : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * tamanho;
	float raio_max = min(tamanho.x, tamanho.y) * 0.5;
	float r = progresso * raio_max;
	float largura = mix(4.0, 1.5, progresso);
	float anel = 1.0 - smoothstep(0.0, 1.5, abs(length(p) - r) - largura * 0.5);
	float fade = 1.0 - progresso;
	COLOR = vec4(cor.rgb, cor.a * anel * fade * fade * step(0.0001, progresso));
}
"""

# varredura de brilho sobre uma caixa inteira (usada nas células do tabuleiro)
const CODIGO_BRILHO_CAIXA: String = """
shader_type canvas_item;
render_mode blend_add;

uniform float progresso : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float diag = (UV.x + UV.y) * 0.5;
	float pos_faixa = mix(-0.25, 1.25, progresso);
	float faixa = 1.0 - smoothstep(0.0, 0.18, abs(diag - pos_faixa));
	vec3 arco = 0.5 + 0.5 * cos(6.28318 * (diag * 1.5 + vec3(0.0, 0.33, 0.67)));
	vec3 tom = mix(vec3(1.0), arco, 0.4);
	COLOR = vec4(tom, faixa * 0.75 * step(0.0001, progresso));
}
"""
