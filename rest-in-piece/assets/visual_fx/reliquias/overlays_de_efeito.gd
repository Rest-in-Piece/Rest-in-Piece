
# efeitos desenhados POR CIMA de um alvo (célula do tabuleiro ou card da relíquia). Servem pros
# dois lados: quem chama só diz o pai, o centro e o tamanho da "caixa" do alvo.
# Cada efeito cria nós temporários, que se apagam sozinhos no fim, e devolve o nó criado
# (o chamador pode guardar pra descartar o anterior se o efeito for disparado de novo).
#
# O "atraso" (segundos) segura o início do efeito; é assim que o tabuleiro escalona as células.

class_name OverlaysDeEfeito
extends RefCounted

const COR_PADRAO: Color = Color(1.0, 0.85, 0.35)
const Z_EFEITO: int = 20
const DURACAO_AURA: float = 1.2

static var _textura_branca: ImageTexture


# duas batidas de intensidade na borda da caixa
static func contorno(pai: Node, centro: Vector2, caixa: Vector2, atraso: float = 0.0, cor: Color = COR_PADRAO) -> Node:
	var margem: float = 6.0
	var overlay := _criar_overlay(pai, centro, caixa + Vector2.ONE * margem * 2.0, ShadersDeEfeito.CONTORNO)
	var material := overlay.material as ShaderMaterial
	material.set_shader_parameter("caixa", caixa)
	material.set_shader_parameter("cor", cor)
	
	var tween := _criar_tween(overlay, atraso)
	ShadersDeEfeito.animar(tween, material, &"intensidade", 0.0,
			[[1.0, 0.12], [0.3, 0.16], [1.0, 0.12], [0.0, 0.35]])
	tween.tween_callback(overlay.queue_free)
	return overlay


# halo luminoso que sobe, oscila e apaga
static func glow(pai: Node, centro: Vector2, caixa: Vector2, atraso: float = 0.0, cor: Color = COR_PADRAO) -> Node:
	var margem: float = 20.0
	var overlay := _criar_overlay(pai, centro, caixa + Vector2.ONE * margem * 2.0, ShadersDeEfeito.GLOW)
	var material := overlay.material as ShaderMaterial
	material.set_shader_parameter("caixa", caixa)
	material.set_shader_parameter("cor", cor)
	material.set_shader_parameter("raio", margem * 0.35)
	
	var tween := _criar_tween(overlay, atraso)
	ShadersDeEfeito.animar(tween, material, &"intensidade", 0.0,
			[[1.0, 0.14], [0.45, 0.18], [0.9, 0.14], [0.0, 0.4]])
	tween.tween_callback(overlay.queue_free)
	return overlay


# anel de choque que se expande a partir do centro
static func onda(pai: Node, centro: Vector2, caixa: Vector2, atraso: float = 0.0, cor: Color = COR_PADRAO) -> Node:
	var lado: float = maxf(caixa.x, caixa.y) * 2.6
	var overlay := _criar_overlay(pai, centro, Vector2(lado, lado), ShadersDeEfeito.ONDA)
	var material := overlay.material as ShaderMaterial
	material.set_shader_parameter("cor", cor)
	
	var tween := _criar_tween(overlay, atraso, Tween.TRANS_QUAD, Tween.EASE_OUT)
	ShadersDeEfeito.animar(tween, material, &"progresso", 0.0, [[1.0, 0.55]])
	tween.tween_callback(overlay.queue_free)
	return overlay


# faixa diagonal brilhante cruzando a caixa (usada nas células do tabuleiro)
static func brilho_varredura(pai: Node, centro: Vector2, caixa: Vector2, atraso: float = 0.0) -> Node:
	var overlay := _criar_overlay(pai, centro, caixa, ShadersDeEfeito.BRILHO_CAIXA)
	var material := overlay.material as ShaderMaterial
	
	var tween := _criar_tween(overlay, atraso)
	ShadersDeEfeito.animar(tween, material, &"progresso", 0.0, [[1.0, 0.45]])
	tween.tween_callback(overlay.queue_free)
	return overlay


# explosão rápida de faíscas que caem com gravidade
static func faiscas(pai: Node, centro: Vector2, caixa: Vector2, atraso: float = 0.0, cor: Color = COR_PADRAO) -> Node:
	var particulas := CPUParticles2D.new()
	particulas.position = centro
	particulas.z_index = Z_EFEITO
	particulas.emitting = false
	particulas.one_shot = true
	particulas.amount = 12
	particulas.lifetime = 0.55
	particulas.explosiveness = 1.0
	particulas.direction = Vector2.UP
	particulas.spread = 180.0
	particulas.initial_velocity_min = 50.0
	particulas.initial_velocity_max = 120.0
	particulas.gravity = Vector2(0.0, 240.0)
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 4.0
	particulas.scale_amount_curve = _curva_de_encolhimento()
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particulas.emission_sphere_radius = maxf(caixa.x, caixa.y) * 0.2
	particulas.color_ramp = _gradiente(cor, 1.0, 0.9, 0.0)
	pai.add_child(particulas)
	
	var tween := _criar_tween(particulas, atraso)
	tween.tween_callback(func(): particulas.emitting = true)
	tween.tween_interval(particulas.lifetime + 0.1)
	tween.tween_callback(particulas.queue_free)
	return particulas


# partículas lentas e suaves subindo POR TRÁS do alvo (poder acumulado)
static func aura(pai: Node, centro: Vector2, caixa: Vector2, atraso: float = 0.0, cor: Color = COR_PADRAO) -> Node:
	var particulas := CPUParticles2D.new()
	particulas.position = centro + Vector2(0.0, caixa.y * 0.3)
	particulas.show_behind_parent = true
	particulas.local_coords = true
	particulas.emitting = false
	particulas.amount = 16
	particulas.lifetime = 1.4
	particulas.explosiveness = 0.0
	particulas.direction = Vector2.UP
	particulas.spread = 12.0
	particulas.initial_velocity_min = 10.0
	particulas.initial_velocity_max = 25.0
	particulas.gravity = Vector2(0.0, -20.0)
	particulas.scale_amount_min = 1.5
	particulas.scale_amount_max = 3.0
	particulas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas.emission_rect_extents = Vector2(caixa.x * 0.45, 3.0)
	particulas.color_ramp = _gradiente(cor, 0.0, 0.75, 0.0)
	pai.add_child(particulas)
	
	var tween := _criar_tween(particulas, atraso)
	tween.tween_callback(func(): particulas.emitting = true)
	tween.tween_interval(DURACAO_AURA)
	tween.tween_callback(func(): particulas.emitting = false)
	tween.tween_interval(particulas.lifetime)
	tween.tween_callback(particulas.queue_free)
	return particulas


# ---------------------------------------------------------------------------------------

# quadrado branco de 1x1 esticado pro tamanho do efeito (o shader desenha tudo com UV)
static func _criar_overlay(pai: Node, centro: Vector2, tamanho: Vector2, nome_shader: StringName) -> Sprite2D:
	var overlay := Sprite2D.new()
	overlay.texture = _obter_textura_branca()
	overlay.position = centro
	overlay.scale = tamanho
	overlay.z_index = Z_EFEITO
	
	var material := ShaderMaterial.new()
	material.shader = ShadersDeEfeito.obter(nome_shader)
	material.set_shader_parameter("tamanho", tamanho)
	overlay.material = material
	
	pai.add_child(overlay)
	return overlay


static func _obter_textura_branca() -> ImageTexture:
	if _textura_branca == null:
		var imagem := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		imagem.fill(Color.WHITE)
		_textura_branca = ImageTexture.create_from_image(imagem)
	return _textura_branca


# o tween pertence ao próprio nó do efeito: se o nó for apagado, o tween para junto
static func _criar_tween(no: Node, atraso: float, transicao: Tween.TransitionType = Tween.TRANS_SINE, suavizacao: Tween.EaseType = Tween.EASE_IN_OUT) -> Tween:
	var tween := no.create_tween()
	tween.set_trans(transicao).set_ease(suavizacao)
	if atraso > 0.0:
		tween.tween_interval(atraso)
	return tween


static func _gradiente(cor: Color, alfa_inicio: float, alfa_meio: float, alfa_fim: float) -> Gradient:
	var gradiente := Gradient.new()
	gradiente.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradiente.colors = PackedColorArray([
		Color(cor.r, cor.g, cor.b, alfa_inicio),
		Color(cor.r, cor.g, cor.b, alfa_meio),
		Color(cor.r, cor.g, cor.b, alfa_fim),
	])
	return gradiente


static func _curva_de_encolhimento() -> Curve:
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 1.0))
	curva.add_point(Vector2(1.0, 0.0))
	return curva
