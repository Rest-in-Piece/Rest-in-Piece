
# base dos efeitos visuais de peça. Cada efeito sobrescreve só os hooks que precisa.
# Efeitos são SEM ESTADO (o .tres é compartilhado): o que aparece vive nos nós criados.

class_name EfeitoVisual
extends Resource

enum Modo { QUEDA, FIXACAO, PERMANENTE }

@export var nome: String = ""
## QUEDA: só enquanto a peça cai. FIXACAO: só no instante em que ela trava.
## PERMANENTE: na queda, na fixação e depois, enquanto o bloco existir
@export var modo: Modo = Modo.PERMANENTE
@export var cor: Color = Color.WHITE
@export_range(0.0, 1.0) var intensidade: float = 0.5

static var _textura_branca: ImageTexture
static var _shaders: Dictionary = {}


func ativo_na_queda() -> bool:
	return modo != Modo.FIXACAO

func ativo_na_fixacao() -> bool:
	return modo != Modo.QUEDA

func permanece_fixo() -> bool:
	return modo == Modo.PERMANENTE

# true se o efeito depende de quais lados da célula estão expostos
func usa_bordas() -> bool:
	return false


# célula criada (peça em queda ou bloco fixo). Filhos de "celula" acompanham a peça
func ao_criar_celula(_celula: Node2D, _contexto: ContextoVisual) -> void:
	pass

# célula da peça em queda andou. contexto.posicao é a nova posição
func ao_celula_movida(_contexto: ContextoVisual, _origem: Vector2) -> void:
	pass

# instante em que a peça trava, uma vez por célula
func ao_fixar_celula(_contexto: ContextoVisual) -> void:
	pass

# peça inteira em queda, uma vez por peça (QUEDA e PERMANENTE). "no" fica no centro da peça
# e a acompanha; contexto.retangulo.size é o tamanho dela. Some quando a peça trava
func ao_criar_peca(_no: Node2D, _contexto: ContextoVisual) -> void:
	pass

# instante em que a peça trava, uma vez por peça. contexto.retangulo é o retângulo dela
func ao_fixar_peca(_contexto: ContextoVisual) -> void:
	pass


# ---------- utilidades ----------

# junta listas sem repetir o mesmo efeito
static func combinar(a: Array[EfeitoVisual], b: Array[EfeitoVisual]) -> Array[EfeitoVisual]:
	var resultado: Array[EfeitoVisual] = []
	for lista in [a, b]:
		for efeito in lista:
			if efeito != null and not resultado.has(efeito):
				resultado.append(efeito)
	return resultado


static func obter_shader(codigo: String) -> Shader:
	if not _shaders.has(codigo):
		var shader := Shader.new()
		shader.code = codigo
		_shaders[codigo] = shader
	return _shaders[codigo] as Shader


# quadrado branco centrado na origem do pai, esticado até "tamanho"
static func criar_quad(pai: Node2D, tamanho: Vector2, shader: Shader = null) -> Sprite2D:
	if _textura_branca == null:
		var imagem := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		imagem.fill(Color.WHITE)
		_textura_branca = ImageTexture.create_from_image(imagem)
	
	var quad := Sprite2D.new()
	quad.texture = _textura_branca
	quad.scale = tamanho
	if shader != null:
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("tamanho", tamanho)
		quad.material = material
	pai.add_child(quad)
	return quad


# clarão aditivo que some sozinho
static func soltar_flash(pai: Node2D, posicao: Vector2, tamanho: Vector2, cor_inicial: Color, duracao: float) -> void:
	var flash := criar_quad(pai, tamanho)
	flash.position = posicao
	flash.modulate = cor_inicial
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flash.material = material
	
	var tween := flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duracao)
	tween.tween_callback(flash.queue_free)


# anima um parâmetro de 0 a 1 e apaga o nó no fim
static func animar_e_liberar(no: Node, material: ShaderMaterial, parametro: StringName, duracao: float) -> void:
	var tween := no.create_tween()
	tween.tween_method(func(valor: float): material.set_shader_parameter(parametro, valor), 0.0, 1.0, duracao)
	tween.tween_callback(no.queue_free)


static func gradiente_de_alfa(cor: Color, inicio: float, meio: float, fim: float) -> Gradient:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradiente.colors = PackedColorArray([
		Color(cor.r, cor.g, cor.b, inicio),
		Color(cor.r, cor.g, cor.b, meio),
		Color(cor.r, cor.g, cor.b, fim),
	])
	return gradiente
