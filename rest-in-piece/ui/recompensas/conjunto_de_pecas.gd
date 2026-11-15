

# um conjunto oferecido na recompensa de peças: UM tipo especial (ex: Vidro) com algumas
# peças de formatos diferentes. Só dados; o GameManager monta e a interface exibe.

class_name ConjuntoDePecas
extends RefCounted

var nome_do_tipo: String = ""
var descricao: String = ""
var pecas: Array[Peca] = []
