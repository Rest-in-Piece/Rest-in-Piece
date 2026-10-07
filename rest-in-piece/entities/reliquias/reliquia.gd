

# classe base de toda relíquia. Cada relíquia só sobrescreve os hooks que precisa;
# os que não forem sobrescritos não fazem nada.

class_name Reliquia
extends Resource

@export var nome: String = ""
@export_multiline var descricao: String = ""
@export var icone: Texture2D


# altera as regras de jogabilidade (tempo de fixação, velocidade...)
func modificar_regras(_regras: RegrasJogo) -> void:
	pass

# altera o saco de peças sorteáveis. O array recebido pode ser modificado direto
# (geralmente relíquias não modificam as peças. Aqui, a ideia é adicionar algo do
# tipo "dobre as chances de aparecer peças T na roleta")
func modificar_pecas_sorteaveis(_pecas: Array[Peca]) -> void:
	pass

# chamado toda vez que uma peça trava, mesmo sem linhas destruídas
func ao_pontuar(_contexto: ContextoPontuacao) -> void:
	pass
