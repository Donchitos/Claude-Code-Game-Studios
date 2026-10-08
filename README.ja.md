[English](README.md) | [简体中文](README.zh-CN.md) | **日本語**

<p align="center">
  <h1 align="center">Claude Code Game Studios</h1>
  <p align="center">
    1 つの Claude Code セッションを、完全なゲーム開発スタジオへ。
    <br />
    49 のエージェント。73 のスキル。連携する 1 つの AI チーム。
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT ライセンス"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 のエージェント"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/skills-73-green" alt="73 のスキル"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-12-orange" alt="12 のフック"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-11-red" alt="11 のルール"></a>
  <a href="https://docs.anthropic.com/en/docs/claude-code"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-f5f5f5?logo=anthropic" alt="Claude Code 向け"></a>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20this%20project-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee"></a>
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-Support%20this%20project-ea4aaa?logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

---

## このプロジェクトが存在する理由

AI を使って一人でゲームを開発することは強力ですが、単一のチャットセッションには構造がありません。マジックナンバーのハードコーディング、設計文書の省略、スパゲッティコードの記述を止める人はいません。QA 工程も設計レビューもなく、「これは本当にゲームのビジョンに合っているのか？」と問う人もいません。

**Claude Code Game Studios** は、AI セッションに実際のスタジオのような構造を与えることで、この問題を解決します。汎用アシスタント 1 つではなく、スタジオ階層で編成された 49 の専門エージェントを利用できます。ディレクターがビジョンを守り、部門リードが各領域を担当し、スペシャリストが実作業を行います。各エージェントには明確な責任、エスカレーション経路、品質ゲートがあります。

その結果、すべての決定を下すのは引き続きあなたですが、適切な質問をし、ミスを早期に見つけ、最初のブレインストーミングからリリースまでプロジェクトを整理して保つチームが加わります。

---

## 目次

- [含まれる内容](#含まれる内容)
- [スタジオ階層](#スタジオ階層)
- [スラッシュコマンド](#スラッシュコマンド)
- [はじめに](#はじめに)
- [アップグレード](#アップグレード)
- [プロジェクト構成](#プロジェクト構成)
- [仕組み](#仕組み)
- [設計思想](#設計思想)
- [カスタマイズ](#カスタマイズ)
- [対応プラットフォーム](#対応プラットフォーム)
- [コミュニティ](#コミュニティ)
- [プロジェクトを支援する](#プロジェクトを支援する)
- [ライセンス](#ライセンス)

---

## 含まれる内容

| カテゴリ | 数 | 説明 |
|----------|-------|-------------|
| **エージェント** | 49 | 設計、プログラミング、アート、オーディオ、ナラティブ、QA、制作を担う専門サブエージェント |
| **スキル** | 73 | あらゆるワークフローフェーズに対応するスラッシュコマンド（`/start`、`/design-system`、`/create-epics`、`/create-stories`、`/dev-story`、`/story-done` など） |
| **フック** | 12 | コミット、プッシュ、アセット変更、セッションライフサイクル、エージェント監査証跡、ギャップ検出の自動検証 |
| **ルール** | 11 | ゲームプレイ、エンジン、AI、UI、ネットワークコードなどの編集時に適用されるパススコープのコーディング標準 |
| **テンプレート** | 41 | GDD、UX 仕様、ADR、スプリント計画、HUD 設計、アクセシビリティなどの文書テンプレート |

## スタジオ階層

エージェントは、実際のスタジオの運営方法に合わせた 3 階層で編成されています：

```
Tier 1 — Directors (Opus)
  creative-director    technical-director    producer

Tier 2 — Department Leads (Sonnet)
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists (Sonnet/Haiku)
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

### エンジンスペシャリスト

このテンプレートには、主要 3 エンジンすべてのエージェントセットが含まれています。プロジェクトに合うセットを使用してください：

| エンジン | リードエージェント | サブスペシャリスト |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript、シェーダー、GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS、シェーダー/VFX、Addressables、UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS、Blueprint、Replication、UMG/CommonUI |

## スラッシュコマンド

Claude Code で `/` と入力すると、73 の全スキルにアクセスできます：

**オンボーディングとナビゲーション**
`/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt`

**ゲーム設計**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**アートとアセット**
`/art-bible` `/asset-spec` `/asset-audit`

**UX とインターフェース設計**
`/ux-design` `/ux-review`

**アーキテクチャ**
`/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**ストーリーとスプリント**
`/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**レビューと分析**
`/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA とテスト**
`/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**制作**
`/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**リリース**
`/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**クリエイティブとコンテンツ**
`/prototype` `/onboard` `/localize`

**チームオーケストレーション**（複数のエージェントを連携させ、1 つの機能に取り組ませます）
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## はじめに

### 前提条件

- [Git](https://git-scm.com/)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（`npm install -g @anthropic-ai/claude-code`）
- **推奨**：[jq](https://jqlang.github.io/jq/)（フック検証用）と Python 3（JSON 検証用）

オプションのツールがなくても、すべてのフックは正常にフォールバックします。何も壊れず、対応する検証機能だけが失われます。

### セットアップ

1. **リポジトリをクローンするか、テンプレートとして使用します**：
   ```bash
   git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
   cd my-game
   ```

2. **Claude Code を開き**、セッションを開始します：
   ```bash
   claude
   ```

3. **`/start` を実行します**。システムが現在の状況（アイデアなし、漠然としたコンセプト、
   明確な設計、既存の作業）を尋ね、決めつけることなく適切なワークフローへ案内します。

   必要なものがすでに分かっている場合は、特定のスキルに直接移動することもできます：
   - `/brainstorm`——ゼロからゲームのアイデアを探る
   - `/setup-engine godot 4.6`——使用するエンジンが決まっている場合に設定する
   - `/project-stage-detect`——既存プロジェクトを分析する

## アップグレード

このテンプレートの古いバージョンをすでに使用していますか？[UPGRADING.md](UPGRADING.md) には、
段階的な移行手順、バージョン間の変更内容、
上書きしても安全なファイルと手動マージが必要なファイルの説明があります。

## プロジェクト構成

```
CLAUDE.md                           # Master configuration
.claude/
  settings.json                     # Hooks, permissions, safety rules
  agents/                           # 49 agent definitions (markdown + YAML frontmatter)
  skills/                           # 73 slash commands (subdirectory per skill)
  hooks/                            # 12 hook scripts (bash, cross-platform)
  rules/                            # 11 path-scoped coding standards
  statusline.sh                     # Status line script (context%, model, stage, epic breadcrumb)
  docs/
    workflow-catalog.yaml           # 7-phase pipeline definition (read by /help)
    templates/                      # 41 document templates
src/                                # Game source code
assets/                             # Art, audio, VFX, shaders, data files
design/                             # GDDs, narrative docs, level designs
docs/                               # Technical documentation and ADRs
tests/                              # Test suites (unit, integration, performance, playtest)
tools/                              # Build and pipeline tools
prototypes/                         # Throwaway prototypes (isolated from src/)
production/                         # Sprint plans, milestones, release tracking
```

## 仕組み

### エージェントの連携

エージェントは構造化された委任モデルに従います：

1. **垂直委任**——ディレクターがリードに、リードがスペシャリストに委任します
2. **水平相談**——同じ階層のエージェントは互いに相談できますが、領域をまたぐ拘束力のある決定はできません
3. **競合解決**——意見の相違は共通の上位者へエスカレーションされます（設計は `creative-director`、技術は `technical-director`）
4. **変更の伝播**——部門横断の変更は `producer` が調整します
5. **領域境界**——明示的な委任がなければ、エージェントは担当領域外のファイルを変更しません

### 自律ではなく協働

これは自動操縦システムでは**ありません**。すべてのエージェントは厳格な協働プロトコルに従います：

1. **質問**——エージェントは解決策を提示する前に質問します
2. **選択肢の提示**——エージェントは長所と短所を含む 2～4 個の選択肢を示します
3. **あなたが決定**——決定するのは常にユーザーです
4. **下書き**——エージェントは確定前に作業内容を提示します
5. **承認**——あなたの承認なしには何も書き込まれません

主導権はあなたにあります。エージェントが提供するのは構造と専門知識であり、自律性ではありません。

### 自動安全機構

**フック**は各セッションで自動的に実行されます：

| フック | トリガー | 動作 |
|------|---------|--------------|
| `validate-commit.sh` | PreToolUse (Bash) | ハードコード値、TODO 形式、JSON の妥当性、設計文書のセクションを確認します。コマンドが `git commit` でなければ即座に終了します |
| `validate-push.sh` | PreToolUse (Bash) | 保護されたブランチへのプッシュを警告します。コマンドが `git push` でなければ即座に終了します |
| `validate-assets.sh` | PostToolUse (Write/Edit) | 命名規則と JSON 構造を検証します。ファイルが `assets/` 内になければ即座に終了します |
| `session-start.sh` | セッション開始 | 現在のブランチと最近のコミットを表示し、状況把握を助けます |
| `detect-gaps.sh` | セッション開始 | 新規プロジェクトを検出して `/start` を提案し、コードまたはプロトタイプがある場合は不足する設計文書を検出します |
| `pre-compact.sh` | コンパクション前 | セッションの進捗メモを保持します |
| `post-compact.sh` | コンパクション後 | Claude に `active.md` からセッション状態を復元するよう通知します |
| `notify.sh` | 通知イベント | PowerShell を介して Windows のトースト通知を表示します |
| `session-stop.sh` | セッション終了 | `active.md` をセッションログへアーカイブし、Git アクティビティを記録します |
| `log-agent.sh` | エージェント起動 | 監査証跡を開始し、サブエージェント呼び出しを記録します |
| `log-agent-stop.sh` | エージェント停止 | 監査証跡を終了し、サブエージェントの記録を完成させます |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | `/skill-test` を実行して `.claude/skills/` の変更を検証するよう勧めます |

> **注**：`validate-commit.sh`、`validate-assets.sh`、`validate-skill-change.sh` は Bash/Write ツールを呼び出すたびに発火し、コマンドまたはファイルパスが関係ない場合は即座に終了します（exit 0）。これは正常なフックの動作であり、パフォーマンス上の問題ではありません。

`settings.json` の**権限ルール**は、安全な操作（git status、テスト実行）を自動的に許可し、危険な操作（強制プッシュ、`rm -rf`、`.env` ファイルの読み取り）をブロックします。

### パススコープのルール

コーディング標準はファイルの場所に応じて自動的に適用されます：

| パス | 適用内容 |
|------|----------|
| `src/gameplay/**` | データ駆動の値、デルタ時間の使用、UI 参照の禁止 |
| `src/core/**` | ホットパスでのゼロアロケーション、スレッド安全性、API の安定性 |
| `src/ai/**` | パフォーマンス予算、デバッグ可能性、データ駆動パラメーター |
| `src/networking/**` | サーバー権威、バージョン付きメッセージ、セキュリティ |
| `src/ui/**` | ゲーム状態を所有しないこと、ローカライズ対応、アクセシビリティ |
| `design/gdd/**` | 必須の 8 セクション、数式形式、エッジケース |
| `tests/**` | テスト命名、カバレッジ要件、フィクスチャパターン |
| `prototypes/**` | 緩和された標準、README 必須、仮説の文書化 |

## 設計思想

このテンプレートは、プロフェッショナルなゲーム開発の実践に基づいています：

- **MDA フレームワーク**——ゲーム設計の Mechanics、Dynamics、Aesthetics 分析
- **自己決定理論**——自律性、有能感、関係性によるプレイヤーの動機付け
- **フロー状態設計**——プレイヤーを惹きつけるための挑戦とスキルの均衡
- **Bartle プレイヤータイプ**——対象ユーザーの設定と検証
- **検証駆動開発**——先にテストし、その後に実装

## カスタマイズ

これは固定されたフレームワークではなく、**テンプレート**です。すべてをカスタマイズできます：

- **エージェントの追加/削除**——不要なエージェントファイルを削除し、領域に応じた新しいエージェントを追加する
- **エージェントプロンプトの編集**——エージェントの動作を調整し、プロジェクト固有の知識を追加する
- **スキルの変更**——チームのプロセスに合わせてワークフローを調整する
- **ルールの追加**——プロジェクトのディレクトリ構成に対応するパススコープのルールを作成する
- **フックの調整**——検証の厳格さを調整し、新しいチェックを追加する
- **エンジンの選択**——Godot、Unity、Unreal のエージェントセットを使用する（使用しないことも可能）
- **レビュー強度の設定**——`full`（全ディレクターゲート）、`lean`（フェーズゲートのみ）、`solo`（なし）。`/start` 中に設定するか、`production/review-mode.txt` を編集します。任意のスキルで `--review solo` を使用すると、実行ごとに上書きできます。

## 対応プラットフォーム

主な開発とテストは、Git Bash を使用する **Windows 10** で行われています。すべてのフックは POSIX 互換パターン（`grep -E` を使用し、`grep -P` は使用しません）を使用し、ツールがない場合のフォールバックを備えているため、macOS と Linux でも動作するはずです。`notify.sh` フックは Windows のトースト通知に PowerShell を使用し、その他の環境では何もしません。macOS/Linux のデスクトップ通知はまだ接続されていません。クロスプラットフォームテストは継続中です。プラットフォーム固有の不具合があれば Issue を提出してください。

## コミュニティ

- **ディスカッション**——質問、アイデア、制作物の紹介には [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) を利用してください
- **Issue**——[バグ報告と機能リクエスト](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)

---

## プロジェクトを支援する

Claude Code Game Studios は無料のオープンソースです。時間の節約やゲームのリリースに役立った場合は、継続的な開発への支援をご検討ください：

<p>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee"></a>
  &nbsp;
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

- **[Buy Me a Coffee](https://www.buymeacoffee.com/donchitos3)**——1 回限りの支援
- **[GitHub Sponsors](https://github.com/sponsors/Donchitos)**——GitHub を通じた継続的な支援

スポンサーシップは、スキルの保守、新しいエージェントの追加、Claude Code とエンジン API の変更への追随、コミュニティの Issue への対応に費やす時間を支えます。

---

*Claude Code のために構築。保守と拡張を継続中です。[GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) からの貢献を歓迎します。*

## ライセンス

MIT ライセンスです。詳細は [LICENSE](LICENSE) を参照してください。
