

# classe base de toda relíquia. Cada relíquia só sobrescreve os hooks que precisa;
# os que não forem sobrescritos não fazem nada.

class_name Reliquia
extends Resource

const NIVEL_MAXIMO: int = 3

enum EfeitoDeAtivacao {
	RELIQUIA_FLIP, RELIQUIA_PULO, RELIQUIA_BRILHO_VARREDURA, RELIQUIA_GLITCH,
	RELIQUIA_DISSOLUCAO, RELIQUIA_CONTORNO, RELIQUIA_GLOW, RELIQUIA_AURA,
	RELIQUIA_ONDA, RELIQUIA_FAISCAS,
	PECA_CONTORNO, PECA_GLOW, PECA_BRILHO_VARREDURA, PECA_ONDA, PECA_FAISCAS,
}

@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var textura: Texture2D
@export_range(1, 3) var nivel: int = 1

@export_category("Efeitos visuais")
@export var efeitos_visuais: Array[EfeitoVisual] = []
@export var cor_dos_efeitos: Color = Color(1.0, 0.85, 0.35)
@export var efeitos_de_ativacao: Array[EfeitoDeAtivacao] = []


# escolhe, numa lista com um valor por nível, o valor do nível atual.
# Ex: escolher_por_nivel([2.0, 3.0, 4.0]) devolve 3.0 no nível 2
func escolher_por_nivel(valores_por_nivel: Array) -> Variant:
	if valores_por_nivel.is_empty():
		return 0
	var indice: int = clampi(nivel, 1, valores_por_nivel.size()) - 1
	return valores_por_nivel[indice]

func pode_evoluir() -> bool:
	return nivel < NIVEL_MAXIMO


# altera as regras de jogabilidade (tempo de fixação, velocidade...)
func modificar_regras(_regras: RegrasJogo) -> void:
	pass

# altera o saco de peças sorteáveis. O array recebido pode ser modificado direto
func modificar_pecas_do_saco(_pecas: Array[Peca]) -> void:
	pass

# chamado pra cada quadradinho de cada linha, da esquerda pra direita, ANTES de os
# pontos dele serem acumulados na linha. Altere bloco.pontos / bloco.multiplicador
func ao_pontuar_bloco(_contexto: ContextoPontuacao, _linha: LinhaPontuada, _bloco: BlocoPontuado) -> void:
	pass

# chamado quando todos os quadradinhos da linha já foram acumulados
func ao_pontuar_linha(_contexto: ContextoPontuacao, _linha: LinhaPontuada) -> void:
	pass

# chamado toda vez que uma peça trava, mesmo sem linhas destruídas, DEPOIS de os pontos
# das linhas virarem fichas
func ao_pontuar(_contexto: ContextoPontuacao) -> void:
	pass

# chamado quando o jogador dá hold. Recebe a peça que ficou armazenada
func ao_armazenar_peca(_peca_armazenada: Peca) -> void:
	pass

# chamado quando a peça trava, ANTES de os quadradinhos dela serem registrados no tabuleiro.
# Use pra guardar bônus nos quadradinhos da peça (travamento.adicionar_pontos_por_bloco)
func ao_travar_peca(_travamento: TravamentoDePeca) -> void:
	pass

# chamado todo quadro enquanto uma peça está em jogo. Use pra efeitos baseados em tempo
# (contexto.delta em segundos reais). Pedidos ao jogo são feitos pelos métodos do contexto
func ao_passar_tempo(_contexto: ContextoDeTempo) -> void:
	pass


static func efeito_eh_da_peca(efeito: EfeitoDeAtivacao) -> bool:
	match efeito:
		EfeitoDeAtivacao.PECA_CONTORNO, EfeitoDeAtivacao.PECA_GLOW, \
		EfeitoDeAtivacao.PECA_BRILHO_VARREDURA, EfeitoDeAtivacao.PECA_ONDA, \
		EfeitoDeAtivacao.PECA_FAISCAS:
			return true
	return false

func tem_efeitos_na_peca() -> bool:
	for efeito in efeitos_de_ativacao:
		if efeito_eh_da_peca(efeito):
			return true
	return false

func obter_efeitos_na_peca() -> Array[EfeitoDeAtivacao]:
	var efeitos: Array[EfeitoDeAtivacao] = []
	for efeito in efeitos_de_ativacao:
		if efeito_eh_da_peca(efeito):
			efeitos.append(efeito)
	return efeitos

# efeitos visuais que esta relíquia dá à peça. Sobrescreva pra filtrar
func obter_efeitos_visuais_para(_peca: Peca) -> Array[EfeitoVisual]:
	return efeitos_visuais
