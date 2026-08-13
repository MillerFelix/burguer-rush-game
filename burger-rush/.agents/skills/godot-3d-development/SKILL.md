# Godot 3D Development

## Objetivo

Esta skill fornece orientações para desenvolvimento de jogos 3D no Godot 4.7.x utilizando GDScript.

Deve ser utilizada em tarefas relacionadas a personagens, câmeras, movimentação, interação, física, ambientes 3D, NPCs, objetos interativos e sistemas de gameplay 3D.

## Estrutura 3D

Utilizar Nodes e Scenes da Godot de forma modular.

Exemplos comuns:

* CharacterBody3D para personagens controlados pelo jogador.
* Camera3D para câmeras.
* CollisionShape3D para colisões.
* MeshInstance3D para modelos 3D.
* Area3D para áreas de interação e detecção.
* StaticBody3D para objetos estáticos com colisão.
* RigidBody3D quando física dinâmica for necessária.
* RayCast3D quando detecção direcional for apropriada.
* NavigationRegion3D e NavigationAgent3D para navegação de NPCs quando necessário.

## Personagens

Personagens controláveis devem possuir:

* movimentação consistente;
* colisões adequadas;
* câmera separada da lógica principal do personagem;
* velocidade configurável;
* suporte a ações configuradas no Input Map;
* código modular para permitir futuras expansões.

Evitar colocar toda a lógica do personagem em um único bloco monolítico quando houver sistemas independentes.

## Input

Utilizar o sistema de Input Map da Godot.

Não depender diretamente de teclas específicas espalhadas pelo código quando uma ação nomeada for apropriada.

Exemplos de ações:

* move_forward
* move_backward
* move_left
* move_right
* interact
* sprint
* jump

As ações devem ser configuradas no projeto quando necessário.

## Câmera

Para jogos em terceira pessoa:

* manter a câmera desacoplada da lógica de gameplay;
* permitir controle suave;
* evitar movimentos bruscos;
* respeitar colisões quando apropriado;
* manter parâmetros configuráveis.

A câmera deve acompanhar o personagem sem comprometer a jogabilidade.

## Interação

Objetos interativos devem utilizar mecanismos claros de detecção.

Quando apropriado:

* Area3D para detectar proximidade;
* RayCast3D para interação direcionada;
* signals para comunicação entre objetos e sistemas.

A interação deve ser extensível para diferentes tipos de objetos.

Exemplos:

* pegar objetos;
* colocar objetos;
* abrir portas;
* utilizar equipamentos;
* conversar com NPCs;
* iniciar ações de cozinha.

## Física e colisões

Utilizar o sistema de física da Godot em vez de implementar manualmente comportamentos físicos que a engine já fornece.

Escolher o tipo de corpo adequado ao comportamento desejado.

Evitar física dinâmica quando uma solução estática ou cinemática for suficiente.

## NPCs

NPCs devem utilizar máquinas de estados ou sistemas equivalentes quando houver múltiplos comportamentos.

Exemplo:

IDLE → MOVING → INTERACTING → WAITING → LEAVING

Evitar lógica de IA complexa dentro de `_process()` quando eventos, timers ou sinais forem suficientes.

Para navegação, utilizar os recursos de Navigation da Godot quando apropriado.

## Performance 3D

Priorizar performance desde o início.

Considerar:

* quantidade de polígonos;
* quantidade de Nodes;
* quantidade de luzes;
* sombras;
* partículas;
* física;
* quantidade de NPCs;
* frequência de processamento;
* draw calls;
* carregamento de assets.

Evitar otimizações prematuras que prejudiquem a clareza do código, mas não criar sistemas claramente ineficientes sem necessidade.

## Assets 3D

Preferir formatos compatíveis com a Godot, especialmente `.glb`/glTF quando apropriado.

Ao importar assets:

* verificar escala;
* verificar orientação;
* verificar materiais;
* verificar colisões;
* verificar quantidade de polígonos;
* verificar tamanho das texturas.

Assets devem seguir a direção artística definida pelo criador.

Não substituir ou modificar assets sem necessidade.

## Princípio

O objetivo não é utilizar a maior quantidade possível de recursos da Godot.

O objetivo é criar uma experiência 3D simples, funcional, performática, modular e fácil de expandir.
