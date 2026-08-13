# BurguerRush — Arquitetura do MVP

## Objetivo

Esta arquitetura representa a estrutura técnica inicial do primeiro protótipo jogável do BurguerRush.

Ela deve permanecer simples e evitar abstrações prematuras.

A arquitetura poderá evoluir conforme novos sistemas forem necessários.

## Fluxo principal do MVP

O primeiro protótipo deve validar:

Jogador anda
→ pega ingrediente
→ prepara carne
→ monta hambúrguer
→ recebe pedido
→ entrega pedido
→ recebe dinheiro.

## Estrutura inicial

res://
├── src/
│   ├── player/
│   │   ├── player.tscn
│   │   └── player.gd
│   │
│   ├── items/
│   │   ├── item.tscn
│   │   └── item.gd
│   │
│   ├── stations/
│   │   ├── dispenser.gd
│   │   ├── grill.gd
│   │   ├── prep_table.gd
│   │   └── counter.gd
│   │
│   └── ui/
│       ├── hud.tscn
│       └── hud.gd
│
└── main.tscn

## Sistemas incluídos

### Player

Responsável por:

- movimentação;
- câmera em primeira pessoa;
- interação;
- item atualmente segurado.

Utilizar CharacterBody3D.

### Item

Representa ingredientes e produtos transportáveis.

No MVP, o tipo do item pode ser representado de forma simples.

Tipos iniciais:

- bread;
- raw_patty;
- cooked_patty;
- cheese;
- burger.

A estrutura poderá posteriormente migrar para Resources quando a quantidade de itens e receitas justificar essa mudança.

### Dispenser

Fornece ingredientes ao jogador.

Não precisa possuir sistema complexo de estoque no MVP.

### Grill

Recebe carne crua.

Fluxo:

raw_patty
→ timer
→ cooked_patty

No MVP não existe carne queimada ou falha de preparo.

### PrepTable

Recebe os ingredientes necessários.

Quando possuir:

- bread;
- cooked_patty;
- cheese;

produz:

- burger.

### Counter

Representa o atendimento.

Possui um pedido simples de hambúrguer.

Quando recebe o hambúrguer correto:

- conclui o pedido;
- adiciona dinheiro;
- gera o próximo pedido.

### HUD

Exibe somente informações necessárias ao protótipo:

- mira;
- item segurado;
- pedido atual;
- dinheiro.

## Sistemas propositalmente adiados

Não implementar no primeiro protótipo:

- EventBus global;
- GameManager;
- EconomyManager;
- DayManager;
- NavigationAgent3D;
- IA avançada de clientes;
- sistema completo de receitas;
- Custom Resources para itens;
- sistema de estoque;
- mercado;
- funcionários;
- upgrades;
- clima;
- ciclo completo de dias;
- equipamentos quebráveis;
- sistema de carne queimada.

Esses sistemas poderão ser introduzidos quando houver necessidade real.

## Princípio arquitetural

Não criar abstrações apenas porque elas poderão ser úteis no futuro.

Primeiro implementar o comportamento real do jogo.

Quando uma necessidade concreta surgir, avaliar a melhor abstração naquele momento.

A arquitetura deve evoluir junto com o jogo.

## Critério de sucesso do MVP

O MVP será considerado funcional quando o jogador conseguir:

1. Entrar na lanchonete.
2. Andar livremente.
3. Pegar ingredientes.
4. Colocar carne na chapa.
5. Esperar a carne ficar pronta.
6. Pegar a carne.
7. Montar um hambúrguer.
8. Visualizar um pedido.
9. Entregar o hambúrguer.
10. Receber dinheiro.
11. Repetir o processo.