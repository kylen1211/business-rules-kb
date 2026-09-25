#!/usr/bin/env bash
# 扫描 codegraph / graphify 接入 Claude Code 后留下的东西。只读，不删任何文件。
# 用法：tool-residue-scan.sh <codegraph|graphify|all> [项目根目录，默认当前目录]
# 输出为空 = 干净；每行一处残留：<类别>  <路径>
# 保留清单（不报）：命令行本体（~/.codegraph/、uv tool 目录）、项目索引 .codegraph/ 与 graphify-out/。
# 项目 .git/hooks 里的刷新钩子是可选保留项，只提示到 stderr。
set -u

tool="${1:-all}"
project="$(cd "${2:-.}" && pwd)"
case "$tool" in
  codegraph) pattern='codegraph' ;;
  graphify)  pattern='graphify' ;;
  all)       pattern='codegraph|graphify' ;;
  *) echo "用法：$0 <codegraph|graphify|all> [项目根目录]" >&2; exit 2 ;;
esac

# 两个工具接入 Claude Code 时会写的位置（codegraph 1.5.0 / graphify 0.9.37 实测）
global_files=("$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json")
project_files=(CLAUDE.md CLAUDE.local.md AGENTS.md .mcp.json .claude/CLAUDE.md .claude/CLAUDE.local.md
               .claude/settings.json .claude/settings.local.json)

# ~/.claude.json 里还记着 skill 使用次数等状态，只查 MCP 注册（全局与各项目）
if [ -f "$HOME/.claude.json" ]; then
  python3 - "$HOME/.claude.json" "$pattern" <<'PY'
import json, re, sys
data = json.load(open(sys.argv[1]))
hit = [k for k in (data.get("mcpServers") or {}) if re.search(sys.argv[2], k, re.I)]
for proj, cfg in (data.get("projects") or {}).items():
    hit += [f"{proj} → {k}" for k in ((cfg or {}).get("mcpServers") or {}) if re.search(sys.argv[2], k, re.I)]
for h in hit:
    print(f"全局MCP  ~/.claude.json：{h}")
PY
fi
for f in "${global_files[@]}"; do
  [ -f "$f" ] && grep -qiE "$pattern" "$f" && echo "全局配置  $f"
done
# skill 目录（-L 跟随软链：~/.claude/skills 常是指向配置仓库的软链）
find -L "$HOME/.claude/skills" -maxdepth 1 2>/dev/null | grep -iE "/[^/]*($pattern)[^/]*$" | sed 's#^#全局skill  #'

cd "$project" || exit 2
for f in "${project_files[@]}"; do
  [ -f "$f" ] && grep -qiE "$pattern" "$f" && echo "项目配置  $project/$f"
done
find -L .claude/skills -maxdepth 1 2>/dev/null | grep -iE "/[^/]*($pattern)[^/]*$" | sed "s#^#项目skill  $project/#"
# graphify 写读前 hook 前留的旧 settings 备份
[ "$tool" != codegraph ] && ls .claude/settings*.graphify-bak 2>/dev/null | sed "s#^#项目备份  $project/#"

# 拆完后留下的空壳：git 未跟踪、内容只剩空结构
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --others --exclude-standard -- .mcp.json .claude/settings.json .claude/settings.local.json 2>/dev/null |
  while read -r f; do
    case "$(tr -d ' \n\t' < "$f")" in
      '{}'|'{"hooks":{"PreToolUse":[]}}') echo "项目空壳  $project/$f" ;;
    esac
  done
fi

# codegraph 遥测默认开启，会上报匿名使用统计
if [ "$tool" != graphify ] && command -v codegraph >/dev/null 2>&1; then
  codegraph telemetry status 2>/dev/null | grep -q "Telemetry: enabled" && echo "遥测开启  运行 codegraph telemetry off"
fi

for h in post-commit post-checkout post-merge; do
  f="$project/.git/hooks/$h"
  [ -f "$f" ] && grep -qiE "$pattern" "$f" && echo "（可选保留）git 钩子  $f" >&2
done
exit 0
