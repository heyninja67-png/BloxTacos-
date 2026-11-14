# BloxTacos v0.2.0 — Classic experiences prototype

BloxTacos é um projeto independente em Godot 4.7.2, inspirado na aparência de plataformas e experiências de blocos de 2016–2017. Esta versão recebe dois avatares GLB rigados enviados pelo usuário e inclui três experiências locais.

> O projeto não é um cliente oficial do Roblox e não se conecta aos serviços Roblox. Os créditos chamados “Robux” são uma carteira fictícia salva localmente, sem valor real e sem transferência para o Roblox.

## O que está incluído nesta versão

### Avatares
- **Noob R6**: GLB rigado incluído em `assets/avatars/noob_r6.glb`.
- **Bacon Hair**: GLB rigado com um clipe de animação incluído em `assets/avatars/bacon_hair.glb`.
- Tela Avatar com seleção entre os dois modelos. A escolha fica salva localmente.
- Acessórios do catálogo podem ser comprados, equipados e removidos. Os itens equipados são montados como meshes 3D originais.
- A animação do Bacon Hair usa o clipe incluído no modelo. O Noob não contém clipes no arquivo de origem; o jogo aplica um movimento simples nas pernas pelo esqueleto.

### Carteira e catálogo
- O primeiro perfil local começa com **100 Robux de demonstração**.
- Dez itens de catálogo, com preços de demonstração.
- Comprar, equipar e desequipar itens.
- Saldo, avatar escolhido e inventário salvos em `user://bloxtacos_profile.cfg`.
- O saldo não representa Robux reais e não pode ser gasto fora do BloxTacos.

### Experiências
- **Classic Yard**: baseplate verde com studs, blocos, árvores quadradas, torre e pequenos obstáculos.
- **Natural Disasters**: ilha com três eventos escolhidos aleatoriamente — enchente com água crescente, terremoto com tremor visual e ventania com funil móvel e empurrões leves. Cada rodada dura até 60 segundos após a contagem inicial.
- **Pizza Place**: restaurante construído para esta experiência, com balcão, cozinha, pizza, forno, prateleira de entregas e mesas. O ciclo de trabalho exige visitar quatro estações na ordem: pedidos, preparo, forno e entrega. Pedidos concluídos geram gorjetas fictícias, separadas da carteira de Robux de demonstração.

### Interface e controles
- Barra superior clássica BloxTacos com Início, Experiências, Avatar, Catálogo e Chat.
- Janela de chat inspirada em interfaces antigas; as mensagens são locais e não chegam a outros jogadores.
- Joystick virtual, botão Pular, Renascer e Interagir no Android.
- No PC: WASD/setas para andar, Espaço para pular, R para renascer, botão direito + arrastar para girar a câmera e Enter para interagir na Pizza Place.
- Orientação de tela configurada para paisagem.

## O que ainda não está implementado

- Multiplayer online, servidores compartilhados, contas na nuvem, amigos e chat entre jogadores.
- Moderação de chat em rede, sistema de denúncias, loja conectada a pagamentos ou economia Roblox.
- Construtor de experiências e publicação de jogos criados por usuários.
- Física avançada de destruição, NPCs de clientes e sistema de entregas com veículos.

Esses recursos precisam de servidor próprio, autenticação, persistência, sincronização e moderação. O chat atual é um protótipo local e não deve ser tratado como chat online.

## Abrir no Godot

1. Extraia o ZIP.
2. Abra a pasta `BloxTacos/` no Godot **4.7.2 stable**.
3. Aguarde a importação dos dois arquivos GLB.
4. Execute o projeto com F6/F5.

## Gerar APK Android no GitHub Actions

1. Crie um repositório GitHub vazio.
2. Envie todo o conteúdo desta pasta para a raiz do repositório. A pasta oculta `.github/` deve ser enviada também.
3. Faça push para `main` ou `master`, ou abra **Actions → Build BloxTacos Android APK → Run workflow**.
4. Quando a execução terminar com sucesso, baixe o artefato `BloxTacos-Android-APK`.
5. Extraia o artefato e instale `BloxTacos.apk` no Android.

O workflow configura Java 17, Android SDK, baixa o editor e templates Godot 4.7.2, importa/valida o projeto, executa uma inicialização headless e exporta um APK de depuração ARM64. A chave de depuração é criada durante o build; não é uma chave de publicação da Play Store.

## Estrutura

```text
BloxTacos/
├── .github/workflows/android-apk.yml
├── assets/
│   ├── avatars/
│   │   ├── noob_r6.glb
│   │   └── bacon_hair.glb
│   ├── icon.png
│   └── icon.svg
├── scenes/main.tscn
├── scripts/
│   ├── avatar_items.gd
│   ├── main.gd
│   ├── mobile_joystick.gd
│   └── player_controller.gd
├── export_presets.cfg
└── project.godot
```

## Identidade do aplicativo

- Nome: `BloxTacos`
- Pacote Android: `com.bloxtacos.classic`
- Versão: `0.2.0` (código 2)
- Arquitetura: `arm64-v8a`

## Licença

O código original BloxTacos está sob MIT. Os modelos de avatar têm licenças próprias e atribuições separadas; consulte `THIRD_PARTY_NOTICES.md`.
