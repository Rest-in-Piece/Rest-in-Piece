
# "toca uma animação feita de assets (SpriteFrames) em cada célula ou na peça inteira"
# QUEDA / PERMANENTE: a animação acompanha a peça (e o bloco, se PERMANENTE).
# FIXACAO: toca uma vez no instante em que a peça trava e se apaga sozinha.
# Não guarda estado: o SpriteFrames é só lido, cada uso cria o próprio AnimatedSprite2D.

class_name EfeitoVisualAnimado
extends EfeitoVisual

enum Escopo { CELULA, PECA }
enum Lado { CENTRO, TOPO, BAIXO, ESQUERDA, DIREITA }
enum Pivo { CENTRO, TOPO, BASE }
enum Medida { ALTURA, LARGURA }

@export_group("Animação")
@export var quadros: SpriteFrames
@export var animacao: StringName = &"default"
@export var velocidade: float = 1.0
## começa cada célula em um quadro diferente
@export var dessincronizar: bool = false
## movimento extra (rotação, posição, escala...) com trilhas no próprio sprite (".:rotation")
@export var movimento: Animation

@export_group("Posição e tamanho")
## CELULA: uma animação por quadradinho. PECA: uma só pra peça inteira (some quando ela fixa,
## a não ser no modo FIXACAO, em que toca uma vez no instante da fixação)
@export var escopo: Escopo = Escopo.CELULA
## de que lado da célula/peça a animação fica
@export var lado: Lado = Lado.CENTRO
## qual ponto do desenho fica no ponto de encaixe (ex: TOPO pra algo pendurado)
@export var pivo: Pivo = Pivo.CENTRO
## deslocamento extra, em tamanhos de célula
@export var deslocamento: Vector2 = Vector2.ZERO
## tamanho do desenho em células, medido pela altura ou pela largura (0 = tamanho original)
@export var tamanho_em_celulas: float = 1.0
@export var medida: Medida = Medida.ALTURA

@export_group("Filtros")
## fração das células que ganham a animação (só no escopo CELULA)
@export_range(0.0, 1.0) var chance: float = 1.0
## só aparece se o lado escolhido estiver exposto, sem vizinho com o mesmo efeito (só CELULA)
@export var somente_se_exposto: bool = false

@export_group("Visual")
@export var aditivo: bool = false
@export var pixel_art: bool = true


func usa_bordas() -> bool:
	return somente_se_exposto and escopo == Escopo.CELULA


func ao_criar_celula(celula: Node2D, contexto: ContextoVisual) -> void:
	if escopo == Escopo.CELULA:
		_tocar(celula, Vector2.ZERO, contexto.tamanho, contexto, false)

func ao_fixar_celula(contexto: ContextoVisual) -> void:
	if escopo == Escopo.CELULA and modo == Modo.FIXACAO:
		_tocar(contexto.camada, contexto.posicao, contexto.tamanho, contexto, true)

func ao_criar_peca(no: Node2D, contexto: ContextoVisual) -> void:
	if escopo == Escopo.PECA:
		_tocar(no, Vector2.ZERO, contexto.retangulo.size, contexto, false)

func ao_fixar_peca(contexto: ContextoVisual) -> void:
	if escopo == Escopo.PECA and modo == Modo.FIXACAO:
		_tocar(contexto.camada, contexto.retangulo.get_center(), contexto.retangulo.size, contexto, true)


# "base" é onde fica o centro do alvo dentro de "pai"; "area" é o tamanho do alvo
func _tocar(pai: Node2D, base: Vector2, area: Vector2, contexto: ContextoVisual, uma_vez: bool) -> void:
	if quadros == null or not quadros.has_animation(animacao):
		return
	if escopo == Escopo.CELULA:
		if contexto.fase > chance:
			return
		if somente_se_exposto and not _lado_exposto(contexto):
			return
	
	var textura: Texture2D = quadros.get_frame_texture(animacao, 0)
	if textura == null:
		return
	var tamanho_original: Vector2 = textura.get_size()
	
	var escala: float = 1.0
	if tamanho_em_celulas > 0.0:
		if medida == Medida.ALTURA:
			escala = tamanho_em_celulas * contexto.tamanho.y / tamanho_original.y
		else:
			escala = tamanho_em_celulas * contexto.tamanho.x / tamanho_original.x
	
	# a raiz recebe o encaixe; o sprite fica na origem dela, então trilhas de posição/rotação
	# do "movimento" partem do ponto de encaixe
	var raiz := Node2D.new()
	raiz.position = base + _ponto_de_encaixe(area) + deslocamento * contexto.tamanho
	pai.add_child(raiz)
	
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = quadros
	sprite.scale = Vector2(escala, escala)
	sprite.centered = false
	sprite.offset = _deslocamento_do_pivo(tamanho_original)
	sprite.speed_scale = velocidade
	sprite.modulate = Color(cor.r, cor.g, cor.b, intensidade)
	if pixel_art:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if aditivo:
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.material = material
	raiz.add_child(sprite)
	
	sprite.play(animacao)
	if dessincronizar:
		var total: int = quadros.get_frame_count(animacao)
		sprite.set_frame_and_progress(int(contexto.fase * total) % total, 0.0)
	if movimento != null:
		_tocar_movimento(sprite)
	if uma_vez:
		sprite.animation_finished.connect(raiz.queue_free)
		sprite.animation_looped.connect(raiz.queue_free)


# o AnimationPlayer filho do sprite usa o pai como raiz: ".:rotation" = rotação do sprite
func _tocar_movimento(sprite: AnimatedSprite2D) -> void:
	var player := AnimationPlayer.new()
	sprite.add_child(player)
	var biblioteca := AnimationLibrary.new()
	biblioteca.add_animation(&"movimento", movimento)
	player.add_animation_library(&"", biblioteca)
	player.play(&"movimento")


func _ponto_de_encaixe(area: Vector2) -> Vector2:
	match lado:
		Lado.TOPO:
			return Vector2(0.0, -area.y / 2.0)
		Lado.BAIXO:
			return Vector2(0.0, area.y / 2.0)
		Lado.ESQUERDA:
			return Vector2(-area.x / 2.0, 0.0)
		Lado.DIREITA:
			return Vector2(area.x / 2.0, 0.0)
	return Vector2.ZERO


func _deslocamento_do_pivo(tamanho_original: Vector2) -> Vector2:
	match pivo:
		Pivo.TOPO:
			return Vector2(-tamanho_original.x / 2.0, 0.0)
		Pivo.BASE:
			return Vector2(-tamanho_original.x / 2.0, -tamanho_original.y)
	return -tamanho_original / 2.0


func _lado_exposto(contexto: ContextoVisual) -> bool:
	match lado:
		Lado.TOPO:
			return contexto.tem_borda(ContextoVisual.TOPO)
		Lado.BAIXO:
			return contexto.tem_borda(ContextoVisual.BAIXO)
		Lado.ESQUERDA:
			return contexto.tem_borda(ContextoVisual.ESQUERDA)
		Lado.DIREITA:
			return contexto.tem_borda(ContextoVisual.DIREITA)
	return true
