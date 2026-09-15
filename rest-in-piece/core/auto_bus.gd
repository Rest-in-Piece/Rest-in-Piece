

# AutoBus é um script com acesso público global.
# A ÚNICA coisa que ele faz é criar signals.

# Um signal é uma forma de comunicação que auxilia a manter
# o encapsulamento das informações. Se um inimigo morre, ele 
# não vai mexer nas estatísticas do jogo para que o jogador
# complete a quest; ele vai apenas dizer "eu morri!" (emitir
# um sinal), e qualquer script que tenha interesse nessa in-
# formação pode subscrever (connect) esse signal para poder
# executar sua própria lógica.

# Só temos que tomar cuidado pra não sobrecarregar demais o
# EventBus. Lidar com centenas de signals em um script pode
# ser bem trabalhoso, criando dependências difíceis de iden-
# tificar e debugar

extends Node

# quero adicionar um signal pra indicar que a linha foi com-
# pletada. Porém, não sei quantos detalhes preciso inserir
# no signal
