
extends Node

# CRITÉRIO PRA UM SIGNAL ENTRAR NESSE SCRIPT (precisa responder "sim" nas três):
# 1. é um fato que JÁ aconteceu (nome no passado) e não um comando?
# 2. quem emite não precisa saber quem escuta?
# 3. quem escuta é um sistema de fora (áudio, partículas, estatísticas, save...)
#    e não um nó vizinho de quem emite?
# Comunicação entre nós vizinhos (tetris → GameManager, hud → GameManager) continua
# sendo um signal comum, declarado no próprio nó.


# --- relíquias ---

# emitido quando uma relíquia contribuiu na pontuação (animação do ícone, som...)
signal reliquia_ativada(reliquia: Reliquia)


# --- partida ---

# emitido toda vez que uma peça trava, com ou sem pontos (ouvintes filtram pelo contexto)
signal jogada_resolvida(contexto: ContextoPontuacao)

signal partida_encerrada(pontuacao_final: int)
