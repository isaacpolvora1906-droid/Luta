# Instinto Brasil

Jogo de luta 2.5D (modelos 3D, combate em plano 2D) com lutadores animais
antropomórficos representando os 26 estados brasileiros. A mecânica central é
a troca de postura entre **mão nua** e **arma**. Feito em **Godot 4.7**.

## Estado atual

Protótipo jogável com dois lutadores provisórios (cápsulas):

- Máquina de estados determinística, contada em frames (60/s)
- Troca de arma em 10 frames, com vulnerabilidade durante a troca
- Mão nua anda 15% mais rápido; armado causa +20% de dano e tem mais alcance e recuperação
- Defesa com dano "chip"; agarrões ignoram a defesa
- Barra de Super com 3 níveis; Super com Trás, Frente, Trás + Soco Forte
- Buffer de input de 30 frames com leitura de comandos (meia-lua etc.)
- Rounds (melhor de 3), timer de 99 s, K.O. e tempo esgotado
- HUD e botões touch para celular

## Controles

| Ação | Jogador 1 | Jogador 2 | Controle |
| :--- | :--- | :--- | :--- |
| Mover / pular / agachar | W A S D | Setas | D-Pad ou analógico |
| Soco 1 / Soco 2 | U / I | Num 4 / Num 5 | X / Y |
| Chute 1 / Chute 2 | J / K | Num 1 / Num 2 | A / B |
| Defesa | O | Num 6 | RB |
| Arma (troca de postura) | L | Num 3 | LT ou LB |

No celular os botões aparecem na tela. No PC, rode com `-- --touch` para vê-los
(clicar com o mouse simula toque).

## Estrutura

```text
Assets/            Áudio, UI, VFX e cenários (Stages/<UF>_<Capital>/)
Core/              GameManager e InputManager (autoloads), BattleManager, InputBuffer, Roster
Entities/
  FighterBase/     Fighter.gd (máquina de estados), AttackData (frame data), FighterBase.tscn
  Characters/      Um diretório por lutador (ex.: AM_Onca/), herdando FighterBase
Scenes/            Battle (luta de protótipo), BattleHUD, MobileControls
tests/             Testes headless
```

Os valores de cada golpe (dano, startup, frames ativos, recuperação, hitbox) ficam
em `AttackData`. Hoje todos usam `DefaultMoves`; cada personagem terá seus próprios `.tres`.

## Testes

```bash
tests/run_tests.sh
```

O script roda os testes de lógica e um teste de fumaça da cena de luta, ambos headless.
Para usar outro binário do Godot, defina `GODOT=/caminho/do/godot`.
