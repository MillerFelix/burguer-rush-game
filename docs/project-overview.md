# BurguerRush — Visão e Direção do Projeto

## 1. Identidade

Nome do projeto: BurguerRush

Tipo: jogo independente de simulação e gerenciamento de lanchonete.

Engine: Godot 4.7.x

Linguagem: GDScript

Plataforma inicial: Windows PC

Renderer inicial: Compatibility

Perspectiva: primeira pessoa.

## 2. Conceito

BurguerRush é um jogo 3D em que o jogador administra e trabalha em sua própria lanchonete.

O jogador controla diretamente um personagem em primeira pessoa e realiza pessoalmente as atividades da lanchonete.

A experiência deve transmitir a sensação de realmente estar trabalhando e administrando uma pequena lanchonete.

O foco inicial é uma experiência simples, divertida, satisfatória e visualmente agradável, que possa crescer progressivamente.

## 3. Fantasia do jogador

O jogador começa com uma pequena lanchonete, poucos equipamentos e recursos limitados.

Durante o jogo, ele prepara alimentos, atende clientes, recebe dinheiro e utiliza seus ganhos para melhorar o negócio.

A progressão deve transmitir a sensação de:

"Comecei com uma lanchonete simples e estou construindo meu próprio negócio."

## 4. Gameplay principal

O ciclo principal esperado é:

1. Começar o dia.
2. Preparar a lanchonete.
3. Receber clientes.
4. Receber pedidos.
5. Preparar os produtos.
6. Entregar os pedidos.
7. Receber o pagamento.
8. Administrar os recursos.
9. Encerrar o dia.
10. Utilizar o dinheiro para melhorias.
11. Começar o próximo dia.

A preparação dos alimentos deve ser uma parte importante e satisfatória da experiência.

O jogador deve poder realizar diferentes etapas manualmente, como pegar ingredientes, fritar, cozinhar, montar produtos e preparar bebidas.

## 5. Lanchonete

A lanchonete começa pequena e simples.

Inicialmente deve possuir apenas os equipamentos necessários para produzir poucos produtos.

Exemplos de equipamentos que podem existir:

* chapa;
* fritadeira;
* máquina de refrigerante;
* geladeira;
* bancadas;
* pia;
* caixa/balcão.

Os equipamentos podem futuramente possuir diferentes níveis de qualidade, velocidade, capacidade e confiabilidade.

## 6. Pedidos

Clientes podem realizar pedidos variados.

Um pedido pode conter:

* um único produto;
* uma bebida;
* múltiplos produtos;
* combinações ou combos.

O sistema de pedidos deverá ser projetado para permitir expansão futura do cardápio sem necessidade de reescrever o sistema inteiro.

## 7. Receitas

Os produtos possuem receitas e etapas de preparação.

Uma receita deve poder representar seus ingredientes e etapas necessárias para sua produção.

Exemplo conceitual:

Hambúrguer simples:

* pão;
* carne;
* queijo;
* montagem.

A quantidade de receitas inicialmente será pequena.

O cardápio poderá crescer progressivamente.

## 8. Clientes

Clientes chegam à lanchonete durante o dia e realizam pedidos.

Futuramente, os clientes poderão possuir características diferentes, como:

* paciência;
* preferência por determinados produtos;
* quantidade de itens no pedido;
* disposição para pagar;
* comportamento;
* frequência de visita.

Esses sistemas não fazem parte obrigatoriamente do primeiro MVP.

## 9. Ciclo de dias

O jogo deverá possuir progressão baseada em dias.

Exemplo:

Dia 1 → Dia 2 → Dia 3 → ...

Cada dia poderá possuir diferentes períodos:

* manhã;
* tarde;
* noite.

O movimento de clientes poderá variar de acordo com o horário.

Futuramente, poderão existir horários de pico e períodos de maior ou menor movimento.

## 10. Ambiente e atmosfera

O ambiente externo deve transmitir a sensação de que existe um mundo acontecendo fora da lanchonete.

Possíveis elementos:

* mudança de horário;
* manhã;
* tarde;
* noite;
* chuva;
* diferentes condições climáticas;
* sons ambientes;
* movimento externo simples.

Esses elementos devem inicialmente ser utilizados para enriquecer a atmosfera, sem exigir a criação de um mundo aberto.

## 11. Som e sensação

Uma prioridade do projeto é criar ações visual e sonoramente satisfatórias.

Exemplos:

* carne fritando;
* chapa funcionando;
* fritadeira;
* refrigerante sendo servido;
* objetos sendo colocados sobre bancadas;
* equipamentos ligando;
* sons de cozinha;
* sons de clientes;
* ambiente externo.

A combinação de animações, partículas, sons e feedback visual deve tornar as tarefas agradáveis de executar.

## 12. Economia

O jogador recebe dinheiro ao vender produtos.

O dinheiro pertence ao negócio do jogador e será utilizado para progressão.

Futuramente, o dinheiro poderá ser utilizado para:

* comprar ingredientes;
* comprar equipamentos;
* melhorar equipamentos;
* expandir a lanchonete;
* contratar funcionários;
* desbloquear novos produtos;
* melhorar estoque;
* adquirir estruturas melhores.

## 13. Ingredientes e mercado

Futuramente, ingredientes poderão precisar ser comprados antes de serem utilizados.

Ingredientes mais avançados poderão possuir preços maiores e serem necessários para receitas mais sofisticadas.

O jogador deverá administrar seus recursos e decidir como utilizar seu dinheiro.

Um sistema de mercado poderá posteriormente incluir:

* preços;
* disponibilidade;
* diferentes fornecedores;
* ingredientes básicos;
* ingredientes avançados;
* variação de custos.

Esse sistema não faz parte obrigatoriamente do primeiro MVP.

## 14. Equipamentos

Os equipamentos poderão possuir diferentes características.

Exemplos:

* velocidade;
* capacidade;
* qualidade;
* durabilidade;
* consumo;
* confiabilidade.

Alguns equipamentos poderão quebrar ou precisar de manutenção.

Esse sistema será desenvolvido somente quando a base do jogo estiver funcionando.

## 15. Funcionários

Futuramente, o jogador poderá contratar funcionários para ajudar na operação.

Possíveis funções:

* atendimento;
* cozinha;
* lavagem de louça;
* limpeza;
* reposição de estoque.

Os funcionários deverão possuir comportamentos automatizados e poderão evoluir em complexidade.

Esse sistema não faz parte do primeiro MVP.

## 16. Expansão da lanchonete

O jogador poderá futuramente utilizar seus ganhos para expandir o estabelecimento.

Possibilidades:

* aumentar a cozinha;
* adicionar mesas;
* adicionar equipamentos;
* aumentar capacidade de atendimento;
* melhorar decoração;
* adicionar novas áreas;
* melhorar infraestrutura.

A expansão deverá acontecer gradualmente conforme a progressão.

## 17. Direção visual

A direção inicial é:

* 3D;
* estilizado;
* simples;
* low-poly ou próximo disso;
* visual bonito e agradável;
* sem necessidade de realismo;
* boa iluminação;
* boa legibilidade;
* performance como prioridade.

O projeto deve evitar depender de gráficos extremamente complexos.

Assets devem possuir uma direção visual consistente.

## 18. MVP inicial

O primeiro MVP deve ser pequeno e servir para provar que o ciclo principal do jogo é divertido.

O MVP inicial deverá conter aproximadamente:

* uma pequena lanchonete;
* personagem controlável em primeira pessoa;
* movimentação;
* câmera;
* interação com objetos;
* poucos equipamentos;
* uma ou duas receitas;
* preparação manual dos produtos;
* clientes simples;
* sistema de pedidos;
* entrega dos pedidos;
* recebimento de dinheiro;
* ciclo básico de dia;
* encerramento do dia;
* progressão financeira extremamente simples.

O MVP não precisa possuir:

* grande cardápio;
* funcionários;
* expansão complexa;
* mercado avançado;
* sistema de clima completo;
* equipamentos quebráveis;
* dezenas de clientes;
* economia complexa;
* mundo aberto;
* multiplayer.

Esses sistemas poderão ser adicionados posteriormente.

## 19. Visão de longo prazo

O objetivo não é limitar BurguerRush ao MVP.

O MVP existe para estabelecer uma fundação funcional sobre a qual o projeto possa crescer.

A visão futura inclui uma experiência de gerenciamento e simulação de lanchonete muito mais completa, com:

* grande variedade de produtos;
* receitas complexas;
* diferentes ingredientes;
* mercado;
* equipamentos;
* manutenção;
* funcionários;
* expansão física;
* economia;
* clientes com comportamentos diferentes;
* diferentes horários;
* clima;
* atmosfera dinâmica;
* progressão;
* personalização;
* eventos;
* novas mecânicas definidas pelo criador.

Novos sistemas devem ser adicionados gradualmente.

## 20. Princípio de desenvolvimento

O jogo deve ser desenvolvido de forma incremental.

Cada sistema deve funcionar antes que novos sistemas dependentes sejam adicionados.

O projeto deve priorizar:

1. diversão;
2. funcionalidade;
3. performance;
4. estabilidade;
5. modularidade;
6. facilidade de expansão.

A arquitetura deve permitir que o MVP cresça sem exigir reconstrução completa do projeto.

## 21. Papel do criador

O criador define:

* visão;
* criatividade;
* gameplay;
* direção artística;
* experiência desejada;
* prioridades;
* decisões de design.

Ideias podem ser alteradas ou descartadas durante o desenvolvimento.

## 22. Papel do agente

O agente é responsável pela implementação técnica.

Pode:

* analisar problemas;
* sugerir soluções técnicas;
* implementar sistemas;
* organizar código;
* criar Scenes;
* criar scripts;
* validar implementações;
* identificar problemas de performance;
* propor melhorias técnicas.

O agente não deve assumir decisões importantes de design sem autorização do criador.

## 23. Estado atual

O projeto está em fase de preparação técnica.

A infraestrutura inicial do agente está sendo configurada.

Nenhum sistema de gameplay foi implementado ainda.

O próximo objetivo é finalizar a preparação do ambiente e então iniciar o primeiro protótipo jogável.
