

# "a cada x segundos a peça em jogo vira uma cópia de outra peça do saco, e essa cópia
# ganha pontos por quadradinho (só nesta instância, a bolsa não é alterada). Se a nova
# peça não couber, tenta outras. Se nenhuma couber, mantém a peça atual"
class_name ReliquiaCamaleao
extends Reliquia

# quantas peças diferentes são tentadas antes de desistir da transformação
const TENTATIVAS_MAXIMAS: int = 3

## a cada quantos segundos a peça em jogo se transforma. Um valor por nível
@export var intervalo_em_segundos_por_nivel: Array[float] = [3.0, 2.5, 2.0]
## pontos por quadradinho somados à cópia. Um valor por nível
@export var pontos_extras_por_nivel: Array[int] = [5, 10, 15]

# estado da relíquia (sem @export, então cada cópia começa zerada). O tempo corre
# continuamente: travar uma peça ou usar o hold não reinicia a contagem
var segundos_acumulados: float = 0.0

func ao_passar_tempo(contexto: ContextoDeTempo) -> void:
	var intervalo_em_segundos: float = escolher_por_nivel(intervalo_em_segundos_por_nivel)
	if intervalo_em_segundos <= 0.0:
		return
	
	# o tempo não corre enquanto a peça está apoiada: evita transformar a peça entre o
	# hard drop e a fixação
	if contexto.peca_apoiada:
		return
	
	segundos_acumulados += contexto.delta
	if segundos_acumulados < intervalo_em_segundos:
		return
	
	# o intervalo é consumido mesmo que a troca falhe: a próxima tentativa é daqui a um intervalo
	segundos_acumulados -= intervalo_em_segundos
	
	var candidatas: Array[Peca] = _sortear_candidatas(contexto)
	if candidatas.is_empty():
		return
	
	contexto.propor_substituicao(candidatas, self)


# até TENTATIVAS_MAXIMAS cópias de formatos diferentes entre si e diferentes do atual
func _sortear_candidatas(contexto: ContextoDeTempo) -> Array[Peca]:
	var pecas_embaralhadas: Array[Peca] = contexto.pecas_do_saco.duplicate()
	pecas_embaralhadas.shuffle()
	
	var pontos_extras: int = escolher_por_nivel(pontos_extras_por_nivel)
	var formatos_usados: Array[String] = [contexto.peca_atual.tipo_peca]
	var candidatas: Array[Peca] = []
	
	for peca_do_saco in pecas_embaralhadas:
		if peca_do_saco.tipo_peca in formatos_usados:
			continue
		formatos_usados.append(peca_do_saco.tipo_peca)
		
		var copia: Peca = peca_do_saco.criar_copia()
		copia.pontos_extras += pontos_extras
		candidatas.append(copia)
		
		if candidatas.size() >= TENTATIVAS_MAXIMAS:
			break
	
	return candidatas
