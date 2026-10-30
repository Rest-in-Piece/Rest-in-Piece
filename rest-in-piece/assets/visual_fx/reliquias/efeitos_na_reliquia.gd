
# efeitos de ativação aplicados no CARD de uma relíquia (ReliquiaSlot). O slot só chama
# EfeitosNaReliquia.tocar(self, efeito); a implementação de cada efeito fica toda aqui.
#
# Cada efeito é "reiniciável": disparar de novo enquanto o anterior ainda toca cancela o
# anterior (tween ou nó de overlay guardado em meta no slot) em vez de empilhar.
#
# Efeitos que mexem no próprio card (flip, pulo) usam as propriedades do slot. Os que mexem
# no desenho do ícone (brilho, glitch, dissolução) usam um ShaderMaterial no TextureRect.
# Os demais são overlays/partículas filhos do slot, então acompanham o pulo e o flip.

class_name EfeitosNaReliquia
extends RefCounted

const DURACAO_FLIP_IDA: float = 0.09
const DURACAO_FLIP_VOLTA: float = 0.16
const SOMBRA_FLIP: Color = Color(0.55, 0.55, 0.62)
const DURACAO_PULO: float = 0.3
const ALTURA_MINIMA_PULO: float = 8.0
const META_PREFIXO: String = "_efeito_visual_"
const META_Y_BASE_DO_PULO: StringName = &"_efeito_visual_pulo_y_base"


static func tocar(slot: ReliquiaSlot, efeito: Reliquia.EfeitoDeAtivacao) -> void:
	var cor: Color = slot.reliquia.cor_dos_efeitos
	var caixa: Vector2 = slot.size
	var centro: Vector2 = caixa / 2.0
	
	match efeito:
		Reliquia.EfeitoDeAtivacao.RELIQUIA_FLIP:
			_flip(slot)
		Reliquia.EfeitoDeAtivacao.RELIQUIA_PULO:
			_pulo(slot)
		Reliquia.EfeitoDeAtivacao.RELIQUIA_BRILHO_VARREDURA:
			_brilho_no_icone(slot)
		Reliquia.EfeitoDeAtivacao.RELIQUIA_GLITCH:
			_glitch(slot)
		Reliquia.EfeitoDeAtivacao.RELIQUIA_DISSOLUCAO:
			_dissolucao(slot, cor)
		Reliquia.EfeitoDeAtivacao.RELIQUIA_CONTORNO:
			_guardar_no(slot, efeito, OverlaysDeEfeito.contorno(slot, centro, caixa, 0.0, cor))
		Reliquia.EfeitoDeAtivacao.RELIQUIA_GLOW:
			_guardar_no(slot, efeito, OverlaysDeEfeito.glow(slot, centro, caixa, 0.0, cor))
		Reliquia.EfeitoDeAtivacao.RELIQUIA_ONDA:
			_guardar_no(slot, efeito, OverlaysDeEfeito.onda(slot, centro, caixa, 0.0, cor))
		Reliquia.EfeitoDeAtivacao.RELIQUIA_FAISCAS:
			_guardar_no(slot, efeito, OverlaysDeEfeito.faiscas(slot, centro, caixa, 0.0, cor))
		Reliquia.EfeitoDeAtivacao.RELIQUIA_AURA:
			_guardar_no(slot, efeito, OverlaysDeEfeito.aura(slot, centro, caixa, 0.0, cor))
		_:
			pass  # efeitos PECA_* são do tabuleiro


# --- efeitos que mexem no card ---------------------------------------------------------

# falso 3D: a escala X vai a 0 rápido e volta a 1, escurecendo na hora em que o card está de lado
static func _flip(slot: ReliquiaSlot) -> void:
	var tween := _novo_tween(slot, Reliquia.EfeitoDeAtivacao.RELIQUIA_FLIP)
	slot.pivot_offset = slot.size / 2.0
	slot.scale = Vector2.ONE
	slot.modulate = Color.WHITE
	
	tween.tween_property(slot, "scale:x", 0.0, DURACAO_FLIP_IDA) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(slot, "modulate", SOMBRA_FLIP, DURACAO_FLIP_IDA)
	tween.tween_property(slot, "scale:x", 1.0, DURACAO_FLIP_VOLTA) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(slot, "modulate", Color.WHITE, DURACAO_FLIP_VOLTA)


# pulo em parábola no eixo Y. O Y de origem fica guardado pra um novo pulo no ar não "subir"
static func _pulo(slot: ReliquiaSlot) -> void:
	var efeito: Reliquia.EfeitoDeAtivacao = Reliquia.EfeitoDeAtivacao.RELIQUIA_PULO
	if not _tween_em_andamento(slot, efeito):
		slot.set_meta(META_Y_BASE_DO_PULO, slot.position.y)
	var y_base: float = slot.get_meta(META_Y_BASE_DO_PULO)
	var altura: float = maxf(slot.size.y * 0.3, ALTURA_MINIMA_PULO)
	
	var tween := _novo_tween(slot, efeito)
	tween.tween_method(
			func(t: float): slot.position.y = y_base - altura * 4.0 * t * (1.0 - t),
			0.0, 1.0, DURACAO_PULO)
	tween.tween_callback(func(): slot.position.y = y_base)


# --- efeitos no desenho do ícone -------------------------------------------------------

static func _brilho_no_icone(slot: ReliquiaSlot) -> void:
	var material := _material_do_icone(slot)
	var tween := _novo_tween(slot, Reliquia.EfeitoDeAtivacao.RELIQUIA_BRILHO_VARREDURA)
	ShadersDeEfeito.animar(tween, material, &"brilho", 0.0, [[1.0, 0.55]])
	tween.tween_callback(func(): material.set_shader_parameter("brilho", 0.0))


static func _glitch(slot: ReliquiaSlot) -> void:
	var material := _material_do_icone(slot)
	var tween := _novo_tween(slot, Reliquia.EfeitoDeAtivacao.RELIQUIA_GLITCH)
	ShadersDeEfeito.animar(tween, material, &"glitch", 0.0,
			[[1.0, 0.05], [0.6, 0.12], [1.0, 0.1], [0.0, 0.08]])
	tween.tween_callback(func(): material.set_shader_parameter("glitch", 0.0))


# corrói o ícone com ruído e depois ele se recompõe. Para uma relíquia consumível, troque a
# última etapa por [1.0, 0.0] (fica dissolvida) e remova a relíquia em seguida
static func _dissolucao(slot: ReliquiaSlot, cor: Color) -> void:
	var material := _material_do_icone(slot)
	material.set_shader_parameter("cor_borda", cor)
	var tween := _novo_tween(slot, Reliquia.EfeitoDeAtivacao.RELIQUIA_DISSOLUCAO)
	ShadersDeEfeito.animar(tween, material, &"dissolver", 0.0,
			[[1.0, 0.32], [1.0, 0.06], [0.0, 0.28]])
	tween.tween_callback(func(): material.set_shader_parameter("dissolver", 0.0))


# um ShaderMaterial por slot, criado só na primeira vez. Com todos os parâmetros em 0 o
# desenho do ícone fica idêntico ao original
static func _material_do_icone(slot: ReliquiaSlot) -> ShaderMaterial:
	var textura: TextureRect = slot.textura_rect
	var material := textura.material as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = ShadersDeEfeito.obter(ShadersDeEfeito.ICONE)
		textura.material = material
	material.set_shader_parameter("tamanho", textura.size)
	return material


# --- controle de reinício --------------------------------------------------------------

static func _chave(efeito: Reliquia.EfeitoDeAtivacao) -> StringName:
	return StringName(META_PREFIXO + str(efeito))


static func _tween_em_andamento(slot: ReliquiaSlot, efeito: Reliquia.EfeitoDeAtivacao) -> bool:
	var chave: StringName = _chave(efeito)
	if not slot.has_meta(chave):
		return false
	var tween: Tween = slot.get_meta(chave)
	return tween != null and tween.is_valid()


# cancela o tween anterior do mesmo efeito (se houver) e devolve um novo, ligado ao slot
static func _novo_tween(slot: ReliquiaSlot, efeito: Reliquia.EfeitoDeAtivacao) -> Tween:
	var chave: StringName = _chave(efeito)
	if slot.has_meta(chave):
		var anterior: Tween = slot.get_meta(chave)
		if anterior != null and anterior.is_valid():
			anterior.kill()
	
	var tween := slot.create_tween()
	slot.set_meta(chave, tween)
	return tween


# guarda o nó do efeito e apaga o do disparo anterior, pra não empilhar brilhos
static func _guardar_no(slot: ReliquiaSlot, efeito: Reliquia.EfeitoDeAtivacao, novo: Node) -> void:
	var chave: StringName = _chave(efeito)
	if slot.has_meta(chave):
		# sem tipo: o nó anterior pode já ter se apagado sozinho, e atribuir uma instância
		# liberada a uma variável tipada dá erro
		var anterior = slot.get_meta(chave)
		if is_instance_valid(anterior):
			anterior.queue_free()
	slot.set_meta(chave, novo)
