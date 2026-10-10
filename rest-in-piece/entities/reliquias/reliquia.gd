

# classe base de toda relíquia. Cada relíquia só sobrescreve os hooks que precisa;
# os que não forem sobrescritos não fazem nada.

class_name Reliquia
extends Resource

const NIVEL_MAXIMO: int = 3

@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var icone: Texture2D
@export_range(1, 3) var nivel: int = 1


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
func modificar_pecas_sorteaveis(_pecas: Array[Peca]) -> void:
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
