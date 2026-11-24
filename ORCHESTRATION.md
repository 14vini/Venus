# ORCHESTRATION.md — Substituição do avatar em código por arte visual (Venus)

> Documento vivo do orquestrador. Atualizado em cada transição de fase.
> Regras: o orquestrador não edita código de produto; delega com escopo exclusivo e verifica antes de declarar pronto.

---

## 0. Configuração

| Chave | Valor |
|---|---|
| PROJETO | Venus — app iOS de prontidão/energia com assistente IA |
| WORKSPACE | `/Users/kaua/Personal/Projetos/Venus` |
| ORIGINAIS | Commit `f5c5b82` (snapshot integral feito a pedido do usuário antes desta fase) |
| FONTE_VERDADE | Este prompt + direção visual fornecida pelo usuário; `README.md` e os componentes atuais como referência de comportamento |
| OBJETIVO | Substituir o avatar desenhado em SwiftUI por 4 PNGs originais (Idle, Thinking, Celebrating, Listening), integrados como assets reais com animações leves |
| RESTRIÇÕES | Não alterar `Core/AI/**`, `Core/DI/**`, `Features/DailyPlanning/**`, `Features/Chat/Domain/**`, `Config.xcconfig*`, `*.xcodeproj/**`. Areas vetadas devem terminar com `git status` vazio. |

Baseline confirmado: `git status --short` vazio após `f5c5b82`.

---

## 1. Fase de Descoberta (somente leitura)

### 1.1 Estrutura real

- **Linguagem/UI:** Swift 6 + SwiftUI (strict concurrency, `@Observable`, `Sendable`).
- **Projeto:** `Venus.xcodeproj` (sem XcodeGen/Fastlane/CocoaPods; SPM em `Venus.xcodeproj/project.xcworkspace/xcshareddata/swiftpm`). Schemes: `Venus` e `Venus - released`.
- **Entrada:** `Venus/App/` (`MainTabView.swift`, `VenusApp`).
- **Design system:** `Venus/Core/Theme/` — `VenusTheme`, `VenusPalette`, `View+Modifiers.swift` (`neumorphicCard`, `neumorphicCircle`).
- **Componentes visuais compartilhados:** `Venus/Core/UIComponents/`
  - `VenusMoodSurfaceComponents.swift` — `VenusMoodOrb` (corpo fantasma translúcido, aura, sombra, gestos, partículas), `VenusGhostBodyShape`.
  - `VenusMascotFaceView.swift` — enums `VenusMascotState` (12 estados) e `VenusMascotExpression` (15 expressões), olhos/sobrancelhas/boca desenhados em `Shape`.
  - `VenusMascotHandsView.swift` — `VenusHandPose` (8 poses) e mãos luminosas.
  - `VenusMascotParticles.swift` — `MascotParticleFactory` / `MascotParticleEmitterView`.
  - `VenusCurtainSplashView.swift`.
- **Features (Clean Architecture por feature):** `Venus/Features/{Home,Chat,DailyPlanning,MoodCheckIn,Galaxy,Onboarding,Profile,Settings}/.../{Data,Domain,Presentation}/`.
- **Assets atuais:** `Venus/Assets.xcassets/` contém apenas `AccentColor.colorset` e `AppIcon.appiconset` (`AppIcon-1024.png`, `AppIcon-Aura-1024.png`). **Não existe image set de avatar hoje.**
- **Testes:** `Tests/DailyPlanTests.swift`, `Tests/SelfKnowledgeTests.swift`.
- **Docs existentes:** `README.md`, `HISTORICO_CONVERSAS.md`, `MODO_ESCURO.md`, `VENUS_AI_IMPLEMENTATION.md`, `Venus/BiometricReadinessSpecification.md`.

### 1.2 Arquitetura

- Clean Architecture orientada a features, com `Data / Domain / Presentation`.
- DI via `Venus/Core/DI/DependencyContainer.swift`.
- Navegação: `MainTabView` (tabs) + fluxos de Onboarding e sheets.
- Estado/erro: `@Observable` ViewModels, `Result`/erros tipados em `Core/AI/AIErrorsAndModels.swift`, estados de UI derivados de `MoodType`, `DayMoment`, readiness.
- Avatar: `VenusMoodOrb` compõe corpo (`VenusGhostBodyShape`), rosto (`VenusMascotFaceView`), mãos (`VenusMascotHandsView`), aura, partículas e cosméticos. Hoje **toda a aparência é gerada por código** — é exatamente o que será substituído.

### 1.3 Convenções

- Prefixo `Venus` em tipos compartilhados; sufixos `View`, `ViewModel`, `Protocol`, `Impl`, `Model`.
- Código e UI em português; nomes de tipos em inglês.
- Cores centralizadas em `VenusTheme` / hex via `Color(hex:)`; nada de cor solta.
- Modificadores reutilizáveis: `.neumorphicCard(...)`, `.neumorphicCircle(...)`, `.glassEffect(...)`.
- Formatação: padrão Xcode (4 espaços), `// MARK: -` para seções.
- Sem `README` de contribuição nem `CONTRIBUTING`; `README.md` descreve produto, não processo.

### 1.4 Padrões de definição — adotados para esta frente

Checklist de entrega de todo sub-agente:
1. Compila no Xcode 27.2 / Swift 6 sem novos warnings.
2. Nenhuma área vetada alterada (ver configuração).
3. Nenhuma string, cor ou dimensão hardcoded onde já existe equivalente em `VenusTheme`.
4. Aparência da Venus vem **dos PNGs**, não de formas SwiftUI; animações apenas transformam a imagem (float, breathe, tilt, cross-fade, scale).
5. Erros esperados não ganham aviso novo/duplicado.
6. Entrega com: arquivos tocados, trecho de código/diff, comando de build e exit code.

Severidade de review: **bloqueante** (não compila / área vetada tocada / imagem não asset real / alpha ausente) · **importante** (inconsistência de identidade entre poses / animação que distorce o personagem / regressions de layout) · **menor** (nomenclatura, comentário, organização).

### 1.5 Build e validação

- Xcode 27.2 (27B52), `xcodebuild` disponível.
- Schemes: `Venus`, `Venus - released`.
- Comando de gate confirmado: `xcodebuild -project Venus.xcodeproj -scheme Venus -destination 'generic/platform=iOS Simulator' -derivedDataPath "$PWD/build/DerivedData" -quiet CODE_SIGNING_ALLOWED=NO build`.
- **Baseline verde:** `EXIT=0` em `build/gate-logs/baseline-build.log` (commit `f5c5b82`). Warnings pré-existentes em `HealthKitService.swift` e `SpeechRecognitionService.swift` — não são regressions desta frente.
- Gate criado em `scripts/gate_avatar.sh` (valida existência/dimensão/alpha dos 4 PNGs + build + áreas vetadas).

### 1.6 Ambiente

- macOS, Apple Silicon, espaço em disco aparentemente suficiente (aviso do prompt: limpar `build/` entre gates se necessário).
- `python3` sem PIL/rembg/numpy; disponíveis `sips` e toolchain Swift. Pós-processamento de imagem, se necessário, será feito com `sips`/Swift/CoreGraphics ou via próprio gerador.

### 1.7 Diferenças em relação ao workflow genérico (adaptações)

1. **Geração de imagem não é "edição de código".** As 4 PNGs são produzidas diretamente pelo orquestrador com a ferramenta de geração de imagens, usando a pose Idle como referência de identidade para as demais — não há "agente de imagem" entre os quiores perfis `.md`.
2. **Integração é a única frente de código** e será delegada a um `coder` com escopo exclusivo; `arquiteto` e `reviewer` atuam como perfis de apoio registrados nos `.md`.
3. **O app já tem um mascot rico em código.** A substituição será introduzida por um **novo componente** `VenusAvatarView` + image sets, trocando os pontos de uso sem apagar os componentes antigos (evita quebrar cosméticos, partículas e gestos ainda usados em outros fluxos). Isso é uma decisão de baixo risco, não overengineering.
4. **Commits são permitidos e já autorizados** pelo usuário; baseline `f5c5b82`.

---

## 2. Agentes do projeto (.md)

Criados em `.opencode/agents/`: `estrategico.md`, `arquiteto.md`, `coder.md`, `reviewer.md`. Todo sub-agente deve lê-los antes de trabalhar.

---

## 3. Modelos de sub-agente

- Provider: `opencode` · Modelo confirmado via `opencode.models`: `opencode/hy4-flash-free` (ativo).
- Modo: `async`.
-身份 lineage via T3 `delegate_task` quando disponível; fallback: `subagent` nativo com `sessionID` para follow-up na mesma sessão.
- `clientRequestId`: slug único por rodada (ex.: `avatar-integracao-r1`).

---

## 4. Plano de frentes (registrado ANTES da delegação)

| # | Frente | Tipo | Escopo exclusivo | Status |
|---|---|---|---|---|
| F0 | Descoberta + baseline |研究 (orquestrador) | `ORCHESTRATION.md`, `.opencode/agents/**` | concluído |
| F1 | Geração das 4 PNGs | imagem (orquestrador) | `output/avatar/**`, `Venus/Assets.xcassets/VenusAvatar*.imageset/**` | **CANCELADO** — usuário escolheu modelo 3D real (USDZ/RealityKit); 3 tentativas falharam com `Invalid credential` |
| F2 | Componente `VenusAvatarView` + troca de pontos de uso | — | — | **CANCELADO** (era dependente das PNGs; substituído por F7) |
| F5 | Novo agente `home` + correção do "pensamento" + loading + lentidão da Home | `home` (delegado) | ver `.opencode/agents/home.md` (escopo exclusivo) | **concluído e verificado** — build `EXIT=0`, áreas vetadas intactas |
| F6 | Gerar `VenusAvatar.usdz` procedural (SceneKit) | `coder` (delegado) | `scripts/generate_venus_usdz.swift`, `Venus/Assets.xcassets/VenusAvatar3D.dataset/**` | **concluído e verificado** — USDZ 72.024 bytes, `usdchecker` exit 0, 11 nós, determinístico |
| F7 | Integrar USDZ com RealityView + animações 3D + estados | `home` (follow-up) | `Venus/Core/UIComponents/VenusAvatar3DView.swift`, `VenusHomeHeroView.swift`, `VenusThinkingView.swift`, `OnboardingMascotCompanionView.swift` | **a delegar** |
| F8 | Redesenhar Home no estilo da referência (minimal/arejo/pastel), mantendo mascot + funções | `home` (follow-up) | `HomeView.swift`, `Venus/Features/Home/Presentation/Components/**`, `HomeViewModel.swift` (mínimo) | **concluído e verificado** — build exit 0, funções preservadas, diff revisado |
| F10 | Home EXATAMENTE como nova referência (tela mood:gradiente, silhueta→Venus, painel glass inferior) | `delegate_task` T3 | `HomeView.swift`, `Venus/Features/Home/Presentation/Components/**`, `Venus/Core/UIComponents/VenusAvatar3DView.swift` (ajuste) | **a delegar** — referência anterior (Nextly) DESCARTADA |

### Verificação consolidada (após F6 + F8)
`bash scripts/gate_avatar.sh` → **6 pass / 0 fail**: `usdz-existe`, `usdz-tamanho`, `usdz-valido`, `dataset-contents`, `build`, `areas-vetadas`.

### Correção de lineage (F9)
Usuário apontou que os agentes nativos (`subagent`) **não aparecem no lineage**. Correção: a partir de agora, toda delegação usa T3 `delegate_task` com `target: { providerInstanceId: "opencode", model: "opencode/hy4-flash-free" }`, `mode: "async"`, `role`, `title` e `clientRequestId` únicos.

| taskId | role | title | clientRequestId | status |
|---|---|---|---|---|
| `node:delegated-task:...:home-liquidglass-review-r1` | `review` | Home — auditoria Liquid Glass | `home-liquidglass-review-r1` | **concluído** — "aprovado com ressalvas", build 0, áreas vetadas vazias. Ressalvas (streak/mood mortos, anotações sobrepostas, vidro simulado residual) aplicam-se ao layout F8, **supersedido pela F10** |
| `node:delegated-task:...:home-mood-exact-r1` | `implementation` | Home exata — tela mood com Venus | `home-mood-exact-r1` | **concluído e verificado** — build exit 0, gate 6/0, áreas vetadas vazias |

## 7. Entrega final (estado atual)

| Frente | Status | Evidência |
|---|---|---|
| Baseline commitado | concluído | `f5c5b82` (antes de qualquer mudança) |
| F5 — loading/lentidão Home | concluído | `async let` + request IDs; build exit 0; diff revisado |
| F6 — USDZ procedural | concluído | 72.024 bytes, `usdchecker` exit 0, 11 nós, determinístico |
| F7 — integração 3D | concluído | `VenusAvatar3DView` com RealityKit + fallback; build exit 0 |
| F8 — layout Nextly | **supersedido** | descartado pelo usuário |
| F9 — auditoria Liquid Glass | concluído | T3 `review`, "aprovado com ressalvas" (ressalvas aplicáveis ao F8) |
| F10 — Home exata (tela mood + Venus) | **concluído** | build exit 0 + gate 6 pass / 0 fail + diff revisado |

**Validação final:** `bash scripts/gate_avatar.sh` → 6 pass / 0 fail (usdz-existe, usdz-tamanho, usdz-valido, dataset-contents, build, areas-vetadas).

**Áreas vetadas:** `git status --short` sem entradas em `Core/AI`, `Core/DI`, `DailyPlanning`, `Chat/Domain`, `Config.xcconfig*`, `.xcodeproj`.

**Limitação conhecida:** verificação visual em dispositivo/simulador não concluída — instalação limpa cai no onboarding e não há hook no escopo para chegar à Home. Conformidade validada por código, build e gate.

**Estado:** alterações **não commitadas** (conforme solicitado; único commit é o baseline `f5c5b82`).

**Nota de lineage:** F5–F8 rodaram em `subagent` nativo (fora do lineage); F9 e F10 rodaram via T3 `delegate_task` (no lineage). Correção registrada.

---

## 8. Nova direção (usuário, rodada atual) — redesign completo do app

Usuário pediu, com 3 imagens anexadas (caminhos abaixo):
- **Venus antiga de volta** (mascot em código `VenusMoodOrb`) — 3D descartado.
- Botões corretos na toolbar da Home.
- **Tab bar nova, animada, não nativa**: pill flutuante com botão central elevado, sem cobrir conteúdo.
- Redesign adaptado ao **resto do app**, hierarquia perfeita e organizada.
- Tudo minimalista; **zero texto de pensamento/processo da IA**.
- Transições, animações e haptics que reforcem a psicologia do app.
- **Cada subagente trabalha numa feature**, com as imagens enviadas a todos.

### Imagens (enviar a TODOS os subagentes)
1. Tab bar flutuante: `/Users/kaua/.t3/userdata/attachments/85aa5342-7fb6-40ec-84d8-a3604a2ea507-87d7c8f4-e92a-489c-9c09-3ddb2621b1a3.png`
2. Voice Coach / Stats / Analysis (linguagem visual): `/Users/kaua/.t3/userdata/attachments/85aa5342-7fb6-40ec-84d8-a3604a2ea507-c1c15af0-d8ad-43bc-90ee-c1b7ff943181.png`
3. Journey / Day 1 (psicologia de progresso): `/Users/kaua/.t3/userdata/attachments/85aa5342-7fb6-40ec-84d8-a3604a2ea507-c61cbb3d-e623-49e7-a087-508f82818bff.png`

### Frentes (escopos exclusivos)

| # | Frente | Escopo exclusivo | Status |
|---|---|---|---|
| F11 | Fundação: tab bar flutuante animada + shell + tema compartilhado | `Venus/App/**`, `Venus/Core/Theme/**`, `Venus/Core/UIComponents/VenusFloatingTabBar.swift`, `Venus/Core/UIComponents/VenusAppBackground.swift` | **concluído (T3)** — `...:f11-foundation-r1`. TabView nativa removida; pill glass + "+" elevado com spring/haptic/matchedGeometry; safeAreaInset 78pt; build isolado EXIT=0 |
| F12 | Home: Venus antiga + toolbar correta + folga para tab bar | `Venus/Features/Home/**` | **concluído (T3)** — `...:f12-home-r1`. VenusMoodOrb restaurado, toolbar hamburger/segmented/avatar, folga 100pt; build isolado EXIT=0 |
| F13 | Chat: linguagem visual + haptics + sem texto de processo | `Venus/Features/Chat/Presentation/**` | **concluído (T3)** — `...:f13-chat-r1`. VenusMoodOrb no indicador, balões glass, haptics envio/resposta, build EXIT=0 |
| F14 | MoodCheckIn + DailyPlanning: jornada/progresso | `Venus/Features/MoodCheckIn/**`, `Venus/Features/DailyPlanning/Presentation/**` | **concluído (T3)** — `...:f14-mood-plan-r1`. Sistema VenusJourneyDesign (arco+pontos), glass real, haptics, build EXIT=0 |
| F15 | Galaxy + Profile + Settings + Subscription | `Venus/Features/Galaxy/**`, `Venus/Features/Profile/**`, `Venus/Features/Settings/**`, `Venus/Features/Subscription/**` | **concluído (T3)** — `...:f15-other-features-r1`. Glass real, haptics, hierarquia; build EXIT=0. Ressalva: paywall em Core/UIComponents ainda com ultraThinMaterial → F18 |
| F16 | Onboarding: Venus antiga + estilo journey | `Venus/Features/Onboarding/**` | **concluído (T3)** — `...:f16-onboarding-r1`. VenusMoodOrb, jornada 6 etapas, haptics, build EXIT=0 |
| F17 | Limpeza 3D (após F12/F13/F16) | `Venus/Core/UIComponents/VenusAvatar3DView.swift`, `Venus/Assets.xcassets/VenusAvatar3D.dataset/**`, `scripts/generate_venus_usdz.swift` | **concluído (T3)** — `...:f17-cleanup-r1`. 3 itens apagados, build EXIT=0, gate 4/0. Só resta um comentário "sem USDZ" na F16 (inofensivo) |

Todas as 6 frentes receberam as 3 imagens e o mesmo conjunto de regras globais; cada uma com `role: implementation`, `mode: async`, target `opencode/hy4-flash-free`, `clientRequestId` único e `derivedDataPath` próprio para builds paralelos sem colisão.

| F18 | Limpeza final — 4 resíduos de `.ultraThinMaterial` em `Core/UIComponents` (apontados pela F15) | `Venus/Core/UIComponents/{VenusMoodSurfaceComponents,VenusTagSelectionGrid,VenusProComponents}.swift` | **concluído (T3)** — `...:f18-glass-cleanup-r1`. Grep vazio, build EXIT=0, mascot intacto |

### Entrega final do redesign (todas as frentes)
| Frente | Status | Evidência |
|---|---|---|
| F11 Fundação — tab bar flutuante | concluído | TabView nativa removida; pill glass + "+" animado; build 0 |
| F12 Home — Venus antiga + toolbar | concluído | VenusMoodOrb; hamburger/segmented/avatar; folga 100pt; build 0 |
| F13 Chat | concluído | Balões glass, haptics, sem texto de processo; build 0 |
| F14 Check-in + Meu Dia | concluído | VenusJourneyDesign (arco/pontos), haptics; build 0 |
| F15 Galaxy/Perfil/Ajustes/Subscription | concluído | Glass real, hierarquia, haptics; build 0 |
| F16 Onboarding | concluído | VenusMoodOrb, jornada 6 etapas; build 0 |
| F17 Limpeza 3D | concluído | 3 itens removidos; grep 0; build 0 |
| F18 Limpeza vidro falso | concluído | grep ultraThinMaterial = 0; build 0 |

**Gate final (orquestrador):** `bash scripts/gate_avatar.sh` → **4 pass / 0 fail** (`sem-3d`, `sem-texto-pensamento`, `build`, `areas-vetadas`).
**Diff consolidado:** 38 arquivos modificados, 2.214 inserções / 2.141 remoções + 13 arquivos novos.
**Greps finais:** `ultraThinMaterial` = 0 · `VenusAvatar3DView` = 0 · termos de processo na UI = 0 (a única ocorrência de "analisando" é uma string de prompt em `SelfKnowledgeEngine`, não exibida).
**Áreas vetadas:** vazias no `git status`.
**Estado:** tudo **não commitado** (HEAD `f5c5b82`).
**Limitação:** nenhuma captura visual em simulador/dispositivo foi obtida — conformidade validada por código, build, gate e grep.

---

## 9. Rodada de ajustes (feedback do usuário)

Feedback literal: "coloca os botões na Toolbar, com modifiers e não assim como você fez"; "a tab bar tá feia e tá tudo esquisito na Home"; "a Chat precisa de repaginada, reavaliação da hierarquia, função principal do app em foco"; "gostei do que você fez no check-in — simples e legal — agora a Prontidão, faz igual à imagem do Day 1".

| # | Frente | Escopo exclusivo | Status |
|---|---|---|---|
| F19 | Home — toolbar via `.toolbar`/`.toolbarItem`, layout simplificado, painel de Prontidão estilo "Day 1" | `Venus/Features/Home/**` | **delegado (T3)** — `...:f19-home-toolbar-r1` |
| F20 | Tab bar — deixar bonita e coerente (pill menor, ícones limpos, sem excesos) | `Venus/App/MainTabView.swift`, `Venus/Core/UIComponents/VenusFloatingTabBar.swift`, `Venus/Core/Theme/**` | **concluído (T3)** — `...:f20-tabbar-r1`. Pill 58pt, "+" 50pt, ícones outline, halo sutil, sem rotação/sombra excessiva; barHeight 90pt documentado; build EXIT=0 |
| F21 | Chat — repaginar com hierarquia clara e foco na conversa | `Venus/Features/Chat/Presentation/**` | **concluído (T3)** — `...:f21-chat-revamp-r1`. Hierarquia header→mensagens→input; insights/plano em sheet secundário; haptics; build EXIT=0 |

As 3 frentes receberam as 3 imagens — com destaque para a imagem 3 (Day 1) como referência do painel de Prontidão.

### Resultado da rodada de ajustes
| Frente | Status | Evidência |
|---|---|---|
| F19 Home — toolbar real + Prontidão Day 1 | **concluído (T3)** | `.toolbar` com 4 `ToolbarItem(placement:)`; overlay antigo removido; painel estilo Day 1 (número grande, arco+5 pontos, CTA escuro); folga 90pt; build 0 |
| F20 Tab bar refinada | **concluído (T3)** | pill 58pt, "+" 50pt, ícones outline, halo sutil, sem rotação; build 0 |
| F21 Chat repaginado | **concluído (T3)** | header→mensagens→input; insights em sheet; build 0 |

**Gate final (rodada 2):** `bash scripts/gate_avatar.sh` → **4 pass / 0 fail**.
**Diff:** 38 arquivos, 2.554 inserções / 2.392 remoções + arquivos novos.
**Greps:** ultraThinMaterial=0 · VenusAvatar3DView=0 · navigationBarHidden=0 · ToolbarItem(placement:) na Home=4.
**Áreas vetadas:** vazias. **Estado:** não commitado (HEAD `f5c5b82`).
**Limitação:** sem verificação visual em simulador/dispositivo; validação por código, build, gate e grep.

---

## 10. Rodada F22 — voltar à TabView nativa
Pedido do usuário: "volta a tabbar nativa e remove o liquidglass dos botões da tabbar pq ela já vem com glass ali".
Escopo: `Venus/App/MainTabView.swift`, apagar `Venus/Core/UIComponents/VenusFloatingTabBar.swift`, ajustar a folga de 90pt em `Venus/Features/Home/Presentation/HomeView.swift`.
T3: `...:f22-native-tab-r1` — **concluído e verificado**. `TabView(selection:)` nativa com 4 `.tabItem`, zero `.glassEffect`/`GlassEffectContainer` no `MainTabView`, `VenusFloatingTabBar.swift` apagado (0 referências), `bottomClearance` 90→20, check-in flutuante simples (44pt, gradiente, sem vidro). Build EXIT=0, gate 4/0. Verificado pelo orquestrador via grep + gate.

---

## 11. Rodada ampla (usuário — sem perguntas, fazer o recomendado)

Diagnóstico inicial do orquestrador: build revalidado em 22/11 → **EXIT=0** (as redeclarações de `dailyProgress` já foram corrigidas pelo agente paralelo do usuário). Testes: scheme `Venus` não está configurado para `test action` (TEST_EXIT=66) — registrar como limitação, não erro de código. Já existe `Venus/Core/AI/VenusQuestionAgent.swift` (agente separado, modelos gratuitos `inclusionai/ling-3.2-flash:free`, `google/gemma-4-31b-it:free`, `openrouter/free`) — válido, só precisa de refinamento.

| # | Frente | Escopo exclusivo | Status |
|---|---|---|---|
| F23 | Chat — UX/design estilo ChatGPT limpo, animação de texto da Home, responsivo | `Venus/Features/Chat/**` | **concluído (T3)** — `...:f23-chat-ux-r1`. Spring da Home, typewriter ágil, cache do filtro, leitura paralela, insights no sheet, zero pensamento/JSON; build EXIT=0, 0 warnings |
| F24 | IA — velocidade, sem pensamento/JSON, filtros e modelos gratuitos | `Venus/Core/AI/{OpenRouterService,ThinkingStreamFilter,AIErrorsAndModels,VenusAIServiceProtocol}.swift` | **concluído (T3)** — `...:f24-ai-speed-r1`. Filtro ampliado, reasoning nunca devolvido, sessão reutilizada, timeout 45→20s/60→30s, 4/4 cenários do filtro PASS, build EXIT=0 |
| F25 | Venus desenhada — melhorar o mascot em código + tentar asset 3D idêntico | `Venus/Core/UIComponents/{VenusMoodSurfaceComponents,VenusMascotFaceView,VenusMascotHandsView,VenusMascotParticles}.swift`, `output/venus/**` | **concluído (T3)** — `...:f25-venus-visual-r1`. Refinos perolados no mascot (silhueta/paleta intactas) propagam-se aos 10 pontos de uso; USDZ 1,4MB em output/venus (usdchecker Success, não importado); build EXIT=0 |

### Entrega final da rodada ampla
| Frente | Status | Evidência |
|---|---|---|
| F23 Chat UX | concluído | spring da Home, typewriter ágil, cache do filtro, leitura paralela, insights no sheet; build 0 |
| F24 IA | concluído | filtro ampliado, reasoning nunca devolvido, timeouts 45→20/60→30, 4/4 cenários PASS; build 0 |
| F25 Venus | concluído | refinos perolados propagados; USDZ 1,4MB em output/venus (usdchecker Success, não importado); build 0 |
| F26 Onboarding | concluído | typewriter unificado, CTA preso ao safe area, teclado gerenciado, question agent timeout 6s; build 0 |
| F27 Auditoria | concluído | 1 bloqueante (A1 já corrigido), 9 importantes, 5 menores; 0 arquivos tocados |
| F28 Home | concluído | streak >7d, IA exibida, 3 rituais Duolingo, 12 órfãos removidos; build 0 |
| F29 Check-in | concluído | erro de salvamento com alert + haptic; build 0 |
| F30 Chat layout | concluído | GeometryReader/fixedSize removidos da raiz, containerRelativeFrame 82%, build 0 |

**Gate final:** `bash scripts/gate_avatar.sh` → **4 pass / 0 fail** (`sem-3d`, `sem-texto-pensamento`, `build`, `areas-vetadas`).
**Nota:** script de gate atualizado nesta rodada — `Core/AI` saiu da lista de áreas vetadas porque a F24 foi explicitamente autorizada a mexer lá.
**Greps finais:** `ultraThinMaterial=0` · `VenusAvatar3DView=0` · `fixedSize` no ChatMessageView=0 · `GeometryReader` no ChatMessageView=0 em código (2 menções em comentário) · termos de pensamento na UI=0 (1 menção em comentário).
**Limitação:** nenhuma captura do Chat foi possível — acesso a dispositivo do T3 desligado, sem CLI de toque, e diálogo de Health Access bloqueia o simulador. Validação por código/build/gate/grep.
**Estado:** não commitado. HEAD `64f0acb`.

### F30 — correção de layout do Chat (diagnóstico por código) — CONCLUÍDO (f30-chat-layout-r1)

---

## 12. Rodada de refinamento visual (23/11) — "app inteiro = check-in"

Pedido do usuário: (1) melhorar o desenho da Venus com **muitas mais reações**, expressões mais bonitas e transições entre expressões; (2) deixar **todo o app** com o visual da tela de check-in (lilás→rosa→branco, arco de progresso, tipografia fina, CTA escuro, menos texto, mais visualização, transições suaves); (3) **mock-up de teste para streaks**.

| # | Frente | Escopo exclusivo | clientRequestId |
|---|---|---|---|
| F31 | Venus — novas expressões/reações + transições | `Core/UIComponents/{VenusMascotFaceView,VenusMascotHandsView,VenusMascotParticles,VenusMoodSurfaceComponents,VenusCosmetics}.swift` | `f31-venus-expressions-r1` — **concluído**: 12 novos estados aditivos, olhos lua/coração/piscadela, novas bocas, 4 novos fabricantes de partículas, brilho no peito, transição phaseAnimator spring; build EXIT=0 |
| F32 | Design system da jornada compartilhado | `Core/UIComponents/VenusJourneyStyle.swift` (novo), `Core/Theme/{Colors,View+Modifiers}.swift`, `Features/MoodCheckIn/Presentation/Components/VenusJourneyDesign.swift` | `f32-journey-style-r1` — **concluído**: tokens lilás/rosa/céu light+dark, VenusJourneyStyle com background/arco/CTA/texto/haptics, modifiers `.venusJourneyCard/.venusJourneyText`, check-in intacto; build EXIT=0 |

Erros `switch must be exhaustive` em `VenusMascotFaceView.swift` são transitórios da F31 (novos casos `.amused`, `.surprised`, `.proud`... em inserção). Não intervir — a própria F31 deve fechar os switches antes de entregar. Gate consolidado só após todas as frentes.
| F33 | Home no visual jornada | `Features/Home/**` | `f33-home-journey-r1` — **concluído**: 0/3 rituais com arco, Venus central, saudação IA no hero, prontidão em pill, chips de modo, CTA escuro; screenshot `/tmp/f33-home.png`验证 visual claro; build EXIT=0 |

## 14. Rodada autônoma (usuário ausente — sem perguntas)
Pedido: "manda o antygravity melhorar as imagens e o 3d e as reacoes igual o duo... e simplifica mais ainda a ui da home sem perder o visual".

| # | Frente | Escopo exclusivo | clientRequestId |
|---|---|---|---|
| F41 | Antigravity/3D/imagens + reações Duolingo | `output/venus/**`, `Core/UIComponents/{VenusMascotParticles,VenusMoodSurfaceComponents,VenusCosmetics}.swift`, novo `Core/UIComponents/VenusCelebrationView.swift` | `f41-antigravity-r1` — **concluído**: Antigravity indisponível (credencial inválida, 6ª falha) → fallback procedural: USDZ 31 meshes (usdchecker Success), 4 renders PNG 1024² em output/venus/renders (gitignored), VenusCelebrationView + 4 novos bursts Duolingo; build EXIT=0 |

### Entrega final (rodada autônoma 23/11)
Gate: **4 pass / 0 fail**. Build `EXIT=0` em todas as frentes. Greps: GeometryReader real no ChatMessageView=0, fixedSize só em comentário, ultraThinMaterial=0, stopStreaming presente.
Renders 3D em `output/venus/renders/` (png transparente 1024²) — **limitação artística real**: resultado procedural é simples/achatado, não substitui arte premium; Antigravity não existe no catálogo e o gerador de imagens segue com credencial inválida.
Chat: performance (~6 escritas/s em vez de 18, ator background), shell estilo ChatGPT (Nova conversa, composer com Parar, empty state com sugestões, coluna 760pt), célula arejada com ações ao toque. Home: 4 blocos, visual preservado.
Próximo passo (não executado): commit/push automático.
| F42 | Home ainda mais simples (sem perder o visual) | `Features/Home/**` | `f42-home-simplify-r1` — **concluído**: 4 blocos (rituais → Venus+saudação → prontidão → CTA), título/rótulos duplicados e fileira de seixos movidos para sheet secundário, build EXIT=0 |

Nota Antigravity: catálogo só tem `opencode/grok-imagine-image-2.0` com credencial inválida (5 falhas). F41 deve verificar novamente e, se continuar indisponível, melhorar o USDZ procedural existente e gerar **renders PNG** dele (múltiplos estados) em `output/venus/renders/` — sem importar no app. Reações estilo Duolingo = confete/estrelas em marco, animação de sucesso com mola, feedback de streak.

## 13. Redesenho do Chat — performance + UI/UX estilo ChatGPT
Pedido: "redesenha chat para melhor performance nova UI e UX igual do chatgpt".
Diagnóstico: `VenusChatViewModel` (@Observable) muta `messages` ~18x/s no typewriter → invalida a tela inteira. `ChatMessage` já é Equatable/Identifiable.

| # | Frente | Escopo exclusivo | clientRequestId |
|---|---|---|---|
| F38 | Performance do streaming/ViewModel | `Features/Chat/Presentation/VenusChatViewModel.swift`, `Features/Chat/Domain/ChatSession.swift` (só se necessário) | `f38-chat-perf-r1` — **concluído**: stream em ator background, flush 150ms (~6 escritas/s vs 18), só a célula em streaming recalcula, `stopStreaming()` aditivo, cancelamento correto; build EXIT=0 |
| F39 | Shell/UI estilo ChatGPT | `Features/Chat/Presentation/VenusChatView.swift`, `Components/{VenusChatHeaderView,VenusChatVisualStyle}.swift` + novos `VenusChatComposerView.swift`, `VenusChatEmptyStateView.swift` | `f39-chat-shell-r1` — **concluído**: header 3 zonas com Nova conversa, composer via safeAreaInset com botão Parar, empty state com 4 sugestões, coluna centralizada 760pt; build EXIT=0 |
| F40 | Célula de mensagem + superfícies secundárias | `Components/{ChatMessageView,VenusThinkingView,VenusChatDetailsSheet,ChatPlanningProposalCard,VenusWelcomeMessage}.swift` | `f40-chat-cell-r1` — **concluído**: balões arejados, avatar Venus 28pt, barra de ações ao toque (copiar/reagir/responder/regenerar), context menu removido, sem GeometryReader/fixedSize, indicador sem texto; build EXIT=0 |

Regras: F39 é dono de `VenusChatVisualStyle` (F40 só lê, sem editar); ChatGPT-like = header limpo com "nova conversa", lista centralizada com largura máxima, estado vazio com sugestões, composer arredondado com anexo/mic e botão de parar durante streaming, ações de mensagem (copiar/regenerar/reação), streaming com cursor. Manter零 pensamento/JSON, foco na conversa e correção de layout (sem GeometryReader/fixedSize raiz).

### Entrega final da rodada de refinamento visual
- Gate: **4 pass / 0 fail** (gate_avatar.sh).
- Verificação visual real obtida pelo F33: `/tmp/f33-home.png` (claro) e `/tmp/f33-home-dark.png` (escuro). Home confere com a linguagem do check-in: gradiente lilás→rosa, arco de 3 rituais, Venus central, menos texto, CTA escuro, tab bar nativa.
- Estados: não commitado (HEAD `64f0acb`). Limitação: screenshots apenas da Home; Chat/Check-in não foi possível capturar por bloqueio de device.
| F34 | Chat no visual jornada | `Features/Chat/Presentation/**` | `f34-chat-journey-r1` — **concluído**: paleta lilás→rosa, glows 7s/9s, arco de 6 pontos no header, input em pílula escura, correção F30 mantida, gate 4/0 |
| F35 | Onboarding no visual jornada | `Features/Onboarding/**` | `f35-onboarding-journey-r1` — **concluído**: tela Day 1 (número gigante em degradê, frase curta), falas curtas da Venus, textos enxugados; build isolado EXIT=0 (workspace travado só pela F31 em edição) |
| F36 | Galaxy/Perfil/Ajustes/Assinatura no visual jornada | `Features/{Galaxy,Profile,Settings,Subscription}/**` (exceto `VenusStreakMockView.swift`) | `f36-other-journey-r1` — **concluído**: arco nos cabeçalhos (perfil 5 dimensões, ajustes 4 marcos, galaxy 7/14/30), céu lilás/rosa, menos texto, build EXIT=0 |
| F37 | Mock-up de streaks (debug/preview) | `Features/Settings/Presentation/Components/VenusStreakMockView.swift` (novo) | `f37-streak-mock-r1` — **concluído**: seletor 3/7/14/30, cosméticos reais, arco/pontos, CTA escuro, haptics, previews light/dark, build EXIT=0 |

Nota: resposta sobre autenticação dada ao usuário nesta rodada — recomendação: Sign in with Apple + CloudKit private DB, auth aditiva (local-first), `AdoptLocalDataUseCase`, outbox, Keychain, migração não destrutiva. Nenhuma frente de auth aberta ainda (aguardando pedido explícito de implementação).

Regra: F33–F36 implementam a linguagem visual localmente (paleta lilás/rosa/céu, gradiente suave, arco/pontos, menos texto, mais visual, transições springs, haptics) sem depender de API nova da F32 para não quebrar build paralelo; consolidação depois.

### F30 — correção de layout do Chat (diagnóstico por código)
Usuário relatou mensagens sobrepostas/desalinhadas. Tentei captura visual: há iPhone 17 Pro bootado, `simctl io` capturou a **Home** com sucesso, mas o acesso a dispositivo do T3 está **desligado** ("Agent device access is turned off") e não há `agent-device` CLI — não foi possível navegar até o Chat para screenshot. Diagnóstico por leitura integral: `ChatMessageView` tem `GeometryReader` como raiz + `.fixedSize(vertical: true)` dentro de `LazyVStack(spacing: 0)` — combinação que colapsa a altura das linhas e sobrepõe mensagens. Delegado `f30-chat-layout-r1` (escopo: ChatMessageView + VenusChatView) para eliminar o GeometryReader da raiz e garantir altura intrínseca.
| F26 | Onboarding — animação de texto, botões/teclado, perguntas IA refinadas | `Venus/Features/Onboarding/**`, `Venus/Core/AI/VenusQuestionAgent.swift` | **delegado (T3)** — `...:f26-onboarding-r1` |
| F27 | Auditoria app inteiro — redondo, Duolingo-like UX/algoritmo (somente leitura) | nenhum arquivo | **delegado (T3, role research)** — `...:f27-audit-r1` |

Nota: o provider de imagem anterior falhou com credencial inválida; a F25 foi instruída a pesquisar alternativas (inclusive "Antigravity") e, se não houver gerador disponível, usar SceneKit procedural sem importar o asset no app.

### Auditoria F27 — resultado e desdobramentos
Relatório lido: 1 bloqueante (A1), 9 importantes, 5 menores. Verificado pelo orquestrador que **A1 já foi corrigido** (AppConfig sem chave hardcoded — vem de env/Info.plist). Pontos fortes preservados: arquitetura, motores de prontidão/padrões, filtro de pensamento/JSON, animações/haptics, psicologia de streak/cosméticos.
Desdobramentos delegados:
| # | Frente | Escopo | clientRequestId |
|---|---|---|---|
| F28 | Home — A3 streak >7d, A4 IA desperdiçada exibida, A9 micro-celebrações Duolingo, A13 limpeza órfãos | Home/**, PatternEngineUseCase, SettingsView, VenusCosmetics | `f28-home-audit-r1` — **concluído**: streak com getAllMoods, aiGreeting no hero, patternSnapshot no callback async, VenusDailyRitualsView (3 rituais), 12 órfãos removidos, build EXIT=0 |
| F29 | Check-in — A5 erro de salvamento com voz (alert + haptic) | MoodCheckIn/Presentation/** | `f29-checkin-errors-r1` — **concluído**: errorMessage/showError/retrySave, defer limpa isSaving, alert acessível + haptic .error, build EXIT=0 |

Itens F26 (A7 haptics/cursor, A8 cascata do question agent) já cobertos no prompt da F26. Itens A6/A10-A15 ficam registrados como melhorias futuras (acessibilidade, sanitização única, acentos, tokens, testes).

Regras comuns: separar tudo em subagents (T3, lineage), nada de mostrar pensamento/JSON, Venus antiga preservada, escopo exclusivo, build com derivedData próprio.

Regras mantidas: Venus antiga (`VenusMoodOrb`), zero texto de processo da IA, Liquid Glass real, minimalismo, haptics/transições com propósito, escopo exclusivo. Imagem 3 (Day 1) é a referência principal da Prontidão; imagem 1 orienta a tab bar; imagem 2 a linguagem visual.

Regras de paralelismo: cada agente usa `--derivedDataPath "$PWD/build/DerivedData-<frente>"` diferente para não colidir builds. Gate (`scripts/gate_avatar.sh`) reescrito para checar ausência de `VenusAvatar3DView`, ausência de texto de pensamento, build e áreas vetadas.

Nota: as frentes F5/F6/F7/F8 rodaram em `subagent` nativo (fora do lineage) antes dessa correção — registrado para transparência.

### F10 — nova referência definitiva (substitui F8)
Usuário enviou nova imagem e pediu: "quero esta home agora, exatamente assim e no lugar do menino ali, a Venus".

Imagem: `/Users/kaua/.t3/userdata/attachments/85aa5342-7fb6-40ec-84d8-a3604a2ea507-80d7f6b6-286c-4b37-91e2-23748ff29c2a.png`

Elementos: fundo gradiente full-bleed (pêssego/laranja no topo com brilho solar, rosa/lavanda no meio, lilás/azul embaixo); dois botões circulares glass no topo (seta à esquerda, menu à direita) e um small sparkle central; silhueta humana iridescente ao centro → **substituir pela Venus**; painel glass grande arredondado na metade inferior com "m o o d", "Today I feel", anéis finos sobrepostos com nome do estado + porcentagem e um sparkle.

Mapeamento de dados: "Pacification / 48%" → estado + score de prontidão do Venus (mantendo tap → breakdown). Funções atuais ficam acessíveis pelo botão de menu superior direito. Liquid Glass real obrigatório. Loading da F5 segue no slot central.

### Brief de F2 (já preparado, aguardando F1)

- **API proposta:** `VenusAvatarView(state: VenusMascotState, size: CGFloat, isInteractive: Bool = true)`.
- **Mapa puro estado → asset** (função `static func assetName(for:)`):
  - `.thinking` → `VenusAvatarThinking`
  - `.celebrating`, `.excited` → `VenusAvatarCelebrating`
  - `.listening` → `VenusAvatarListening`
  - demais (`.idle`, `.welcoming`, `.speaking`, `.empathetic`, `.petting`, `.curious`, `.yawning`, `.sleeping`) → `VenusAvatarIdle`
- **Animações permitidas:** flutuar (y), respirar (scale), inclinar (rotation), cross-fade de opacity na troca de pose, tap com haptic + bounce suave. **Proibido:** redesenhar corpo/olhos/mãos; partículas em código; gestos de física complexa.
- **Escalonamento:** o PNG tem o personagem em ~65–70% da altura; preservar o tamanho percebido do orbe antigo (94pt na Home, 80pt no Onboarding) com uma única constante documentada, sem distorcer a proporção.
- **Pontos de uso:** `HomeHeroMascotView` (linha 65) e `OnboardingMascotCompanionView` (linha 86). `VenusThinkingView` do Chat **não** é ponto de uso do avatar (são só dots de texto) — fora de escopo.
- **Não apagar** `VenusMoodOrb`, `VenusMascotFaceView`, `VenusMascotHandsView`, `VenusMascotParticles`: outros fluxos ainda os usam; a frente apenas para de usá-los nos dois pontos acima.
| F3 | Gate de build + verificação | orquestrador | `scripts/gate_avatar.sh`, `build/` | pendente |
| F4 | Consolidação e entrega com evidência | orquestrador | `ORCHESTRATION.md` | pendente |

**Regra de não-sobreposição:** F2 não toca nenhum arquivo de F1 nem de F0. Nenhuma frente toca áreas vetadas.

---

## 5. Log de delegação

| Rodada | taskId / sessão | clientRequestId | Resultado | Evidência |
|---|---|---|---|---|
| F1-t1 | `image_1ff031c44001eCur049o4Oj5Ze` | `avatar-idle-r1` | **falhou** | `Invalid credential` — modelo padrão `opencode/grok-imagine-image-2.0` |
| F1-t2 | `image_1ff03e757001Az9qNvHkURKLUM` | `avatar-idle-r2` | **falhou** | `Invalid credential` — modelo explícito `opencode/grok-imagine-image-2.0` (ID confirmado via `opencode.models({type:"image"})`, único disponível) |
| F1-t3 | `image_1ff086a8e001pkABnKYV6siieB` | `avatar-idle-r3` | **falhou** | `Invalid credential` — após o usuário indicar que poderia corrigir a credencial; credencial ainda inválida |
| F5 | `ses_e00f6b62cffevuO3fz5mMsMzT9` | `home-loading-r1` | **concluído e verificado** | Build `EXIT=0`; 4 arquivos alterados; `git status` sem áreas vetadas; diff revisado pelo orquestrador (async let + request IDs + loading sem texto). Gate: 2 pass / 4 fail — só os 4 checks de PNG (frente cancelada) |
| F6 | `ses_e00f08b1bffe209PvEM396P7F1` | `venus-usdz-r1` | em andamento | Gerador SceneKit + Data Set no Assets; viabilidade do export confirmada antes de delegar |

Nota: `orchestrator_capabilities` não expõe nenhum provider de imagem alternativo; `request_secret` não pode ser aplicado à geração de imagens (o valor do segredo nunca é devolvido ao agente). Bloqueio é de infraestrutura, não do prompt.

---

## 5.1 Mudança de direção — modelo 3D real (decisão do usuário)

Usuário questionou a necessidade do provedor de imagem ("a Venus não é em 3D e movimento?") e escolheu **modelo 3D real (USDZ/RealityKit)**. Esclarecimento registrado: a Venus atual **não é 3D** — é ilusão 2.5D em SwiftUI (`VenusGhostBodyShape` + gradientes + blur + animações). PNGs seriam só imagem estática com aparência 3D.

Viabilidade confirmada localmente: `swift` + SceneKit exporta USDZ (`WRITE=true`, teste em `/private/var/folders/.../test.usdz`). `usdcat`/`usdchecker` disponíveis. Deployment target `iOS 26.0` → `RealityView` disponível. Nenhum asset 3D existente no projeto.

**Decisão:** gerar `VenusAvatar.usdz` proceduralmente com SceneKit (F6) e integrar com `RealityView` + animações 3D reais (F7). Qualidade artística será estilizada/simples — registrado como limitação conhecida, evolutível depois por um modelo profissional do usuário.

**Formato do asset:** Data Set dentro de `Assets.xcassets` (`VenusAvatar3D.dataset/`) para evitar editar `project.pbxproj` (área vetada). Carregamento em runtime via `NSDataAsset` → escrever em temp → `try await ModelEntity(contentsOf: url)` (API confirmada no swiftinterface do iOS 26 SDK, linha ~13818).

### Brief de F7 (já preparado, aguardando F6)
- Novo `Venus/Core/UIComponents/VenusAvatar3DView.swift`: `RealityView` com `ModelEntity` carregado do Data Set; câmera orthographic/perspectiva fixa, luz suave, fundo transparente.
- Animações **3D reais** (não SwiftUI): flutuar (posição Y), respirar (escala), inclinar (rotação), e variações por estado (`.thinking` inclina leve, `.celebrating` giro + partículas 3D, `.listening` leve aproximação). Usar `Entity.animate(...)` / `fromToByAction` com `TIMING` reversível.
- Mapa estado → animação reusa `VenusMascotState` existente; função pura.
- Substituir os dois pontos temporários do agente `home`: loading da Home (`HomeView`) e indicador do Chat (`VenusThinkingView`) pelo novo componente 3D. `HomeHeroMascotView` e Onboarding também passam a usar o modelo 3D.
- Fallback: se o USDZ falhar ao carregar, manter `VenusMoodOrb` — sem tela vazia, sem erro novo.
- Gate: `bash scripts/gate_avatar.sh` (já adaptado para USDZ) + `N pass / 0 fail`.

### Brief de F8 — Home no estilo da referência (decisão do usuário)
Referência anexada pelo usuário: `/Users/kaua/.t3/userdata/attachments/85aa5342-7fb6-40ec-84d8-a3604a2ea507-43fea5c7-d02f-4966-a230-a44d29dcc74c.png` (conceito "简约清爽界面" — interface simples e refrescante, app "Nextly").

Elementos a traduzir:
1. Topo com marca centralizada (3 barras verticais) + wordmark "Venus", sem nav bar carregada de ícones.
2. Hero arejado com gradiente pastel suave (branco/lavanda/pêssego) e o mascot como peça central difusa, com anotações finas ligadas por linha ("IA acolhedora", "Clareza diária", "Ritual leve").
3. Manchete grande com peso seletivo + label pequena acima ("Feita para mentes curiosas"), incorporando a saudação IA existente.
4. Ações em pills discretos no rodapé (check-in / conversar), com seta — em vez de botões grandes.
5. Funções atuais (score de prontidão, Meu Dia, streak, humor, galaxy, histórico, chat) **preservadas** e reorganizadas de forma ergonômica: score integrado ao hero (número sutil + arco fino), Meu Dia em card glass suave, demais acessos em ícones pequenos no rodapé.
6. Loading da F5 continua existindo e deve caber nesse hero (Venus pensando, sem texto de processo).
7. Mascot ainda é `VenusMoodOrb` nesta frente; a troca pelo USDZ 3D acontece na F7.

Restrição: não alterar o comportamento dos ViewModels além do estritamente necessário; não remover funções; não mexer no tema global (criar gradientes locais à Home se preciso).

---

## 6. Gate / Validação

A preencher em F3 com `N pass / 0 fail`, exit codes e diffs.

---

## 7. Entrega final

A preencher em F4.
