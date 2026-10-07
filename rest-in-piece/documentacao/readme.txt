

# Rest in Piece

Tetris com pontuação inspirada em Balatro: cada jogada gera *pontos* e um **multiplicador**, e o jogador coleciona **relíquias** que alteram esse cálculo ou as regras da partida.

## Documentação

| Arquivo | Assunto |
|---|---|
| `docs/scripts.txt` | função de cada script e o que ele deve (ou não) abrigar |
| `docs/reliquias.txt` | funcionamento das relíquias e como criá-las |
| `docs/pontuacao.txt` | pontos x multiplicador, ContextoPontuacao, spins e metas |
| `docs/regras_de_jogo.txt` | fluxo Fase -> RegrasDeJogo -> Tetris e como adicionar parâmetros |
| `docs/bolsa_de_pecas.txt` | peças do jogador, recompensas e lojas |
| `docs/autobus.txt` | critérios e lista de signals globais |

## Como testar

- Relíquias: arraste os `.tres` para `reliquias_iniciais` no `GameManager`.
- Valores de jogabilidade: edite `levels/fase_1.tres`.
- Peças: chame `adicionar_peca_a_bolsa` no `GameManager` para simular uma recompensa.
