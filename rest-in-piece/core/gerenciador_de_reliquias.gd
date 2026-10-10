

# guarda as relíquias do jogador e repassa os eventos do jogo pra elas, na ordem
# em que foram adquiridas. Não sabe nada de tabuleiro nem de HUD.

class_name GerenciadorDeReliquias
extends RefCounted

signal reliquias_alteradas

const MAX_RELIQUIAS: int = 5

var reliquias: Array[Reliquia] = []


func adquirir(reliquia: Reliquia) -> bool:
	if reliquias.size() >= MAX_RELIQUIAS:
		return false
	
	# usa uma cópia pra que o estado da relíquia não vaze pro arquivo .tres
	reliquias.append(reliquia.duplicate() as Reliquia)
	reliquias_alteradas.emit()
	return true

func remover(reliquia: Reliquia):
	reliquias.erase(reliquia)
	reliquias_alteradas.emit()

func evoluir(reliquia: Reliquia) -> bool:
	if not reliquias.has(reliquia) or not reliquia.pode_evoluir():
		return false
	
	reliquia.nivel += 1
	reliquias_alteradas.emit()
	return true

func limpar():
	reliquias.clear()
	reliquias_alteradas.emit()


func aplicar_regras(regras: RegrasJogo):
	for reliquia in reliquias:
		reliquia.modificar_regras(regras)

func aplicar_pecas_sorteaveis(pecas: Array[Peca]):
	for reliquia in reliquias:
		reliquia.modificar_pecas_sorteaveis(pecas)

func processar_armazenamento(peca_armazenada: Peca):
	for reliquia in reliquias:
		reliquia.ao_armazenar_peca(peca_armazenada)


# ordem da pontuação: quadradinhos (esquerda -> direita) -> linha -> pontos da jogada -> jogada
func processar_pontuacao(contexto: ContextoPontuacao):
	for linha in contexto.linhas:
		_processar_blocos_da_linha(contexto, linha)
		_processar_linha(contexto, linha)
	
	contexto.somar_pontos_das_linhas()
	
	for reliquia in reliquias:
		contexto.ativou_reliquia = false
		reliquia.ao_pontuar(contexto)
		
		if contexto.ativou_reliquia:
			AutoBus.reliquia_ativada.emit(reliquia)


func _processar_blocos_da_linha(contexto: ContextoPontuacao, linha: LinhaPontuada):
	for bloco in linha.blocos:
		for reliquia in reliquias:
			_executar_hook_do_bloco(reliquia, contexto, linha, bloco)
		
		linha.acumular_bloco(bloco)

# a relíquia é considerada ativa se alterou o bloco, pra não depender de ela avisar
func _executar_hook_do_bloco(reliquia: Reliquia, contexto: ContextoPontuacao, linha: LinhaPontuada, bloco: BlocoPontuado):
	var pontos_antes: int = bloco.pontos
	var multiplicador_antes: float = bloco.multiplicador
	contexto.ativou_reliquia = false
	
	reliquia.ao_pontuar_bloco(contexto, linha, bloco)
	
	var alterou_bloco: bool = bloco.pontos != pontos_antes or bloco.multiplicador != multiplicador_antes
	if alterou_bloco or contexto.ativou_reliquia:
		AutoBus.reliquia_ativada.emit(reliquia)

func _processar_linha(contexto: ContextoPontuacao, linha: LinhaPontuada):
	for reliquia in reliquias:
		var pontos_antes: float = linha.pontos
		var estava_zerada: bool = linha.zerada
		contexto.ativou_reliquia = false
		
		reliquia.ao_pontuar_linha(contexto, linha)
		
		var alterou_linha: bool = linha.pontos != pontos_antes or linha.zerada != estava_zerada
		if alterou_linha or contexto.ativou_reliquia:
			AutoBus.reliquia_ativada.emit(reliquia)
