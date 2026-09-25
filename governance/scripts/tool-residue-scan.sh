#!/usr/bin/env bash
# 扫描 codegraph / graphify 接入 Claude Code 后留下的东西。只读，不删任何文件。
# 用法：tool-residue-scan.sh <codegraph|graphify|all> [要查的目录，默认当前目录]
#   要查的目录：启动 Claude Code 的目录，以及每个登记的代码根，各跑一次。
# 输出为空 = 干净；每行一处残留：<类别>  <路径>  <命中的特征>
# 按注入特征匹配，不按工具名：权限里放行 `Bash(codegraph node:*)`、说明里写「查代码用 codegraph」都不算残留。
# 特征来源：codegraph 1.5.0 / graphify 0.9.37 在隔离 HOME 里实装后逐文件核对（2026-09-25）。
set -u

tool="${1:-all}"
target="$(cd "${2:-.}" && pwd)"
case "$tool" in
  codegraph|graphify|all) ;;
  *) echo "用法：$0 <codegraph|graphify|all> [要查的目录]" >&2; exit 2 ;;
esac
want() { [ "$tool" = all ] || [ "$tool" = "$1" ]; }

# 文本特征（grep -E）：
#   codegraph：MCP 权限放行、提示词 hook 命令、说明段起始标记
#   graphify：读前 hook 命令、说明段 / skill 登记段标题（整行 # graphify 或 ## graphify）
patterns=()
want codegraph && patterns+=('mcp__codegraph__' 'codegraph prompt-hook' 'CODEGRAPH_START')
want graphify  && patterns+=('graphify hook-guard' '^#{1,2} graphify[[:space:]]*$')

grep_features() {  # $1 类别 $2 文件
  local p
  [ -f "$2" ] || return 0
  for p in "${patterns[@]}"; do
    grep -qE -- "$p" "$2" && echo "$1  $2  「$p」"
  done
}

# MCP 注册：~/.claude.json 顶层与各项目下的 mcpServers，以及项目 .mcp.json
mcp_check() {  # $1 类别 $2 文件
  [ -f "$2" ] || return 0
  want codegraph || return 0
  python3 - "$1" "$2" <<'PY'
import json, sys
label, path = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except Exception:
    sys.exit(0)
if "codegraph" in (data.get("mcpServers") or {}):
    print(f"{label}  {path}  「mcpServers.codegraph」")
for proj, cfg in (data.get("projects") or {}).items():
    if "codegraph" in ((cfg or {}).get("mcpServers") or {}):
        print(f"{label}  {path}  「projects[{proj}].mcpServers.codegraph」")
PY
}

skill_check() {  # $1 类别 $2 skills 目录（-L 跟随软链：~/.claude/skills 常是软链）
  local name
  for name in codegraph graphify; do
    want "$name" || continue
    [ -e "$2/$name" ] && echo "$1  $2/$name  「skill 目录」"
  done
  return 0
}

# 全局
mcp_check "全局MCP" "$HOME/.claude.json"
for f in "$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json"; do
  grep_features "全局配置" "$f"
done
skill_check "全局skill" "$HOME/.claude/skills"

# 目录内（Claude Code 在这个目录启动时会读的文件）
cd "$target" || exit 2
mcp_check "项目MCP" "$target/.mcp.json"
for f in CLAUDE.md CLAUDE.local.md .claude/CLAUDE.md .claude/CLAUDE.local.md .claude/settings.json .claude/settings.local.json; do
  grep_features "项目配置" "$target/$f"
done
skill_check "项目skill" "$target/.claude/skills"
if want graphify; then
  for f in .claude/settings*.graphify-bak; do
    [ -e "$f" ] && echo "项目备份  $target/$f  「graphify 写 hook 前留的旧 settings」"
  done
fi

# 拆完后留下的空壳：git 未跟踪、内容只剩空结构
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files --others --exclude-standard -- .mcp.json .claude/settings.json .claude/settings.local.json 2>/dev/null |
  while read -r f; do
    case "$(tr -d ' \n\t' < "$f")" in
      '{}'|'{"hooks":{"PreToolUse":[]}}') echo "项目空壳  $target/$f  「未跟踪且只剩空结构」" ;;
    esac
  done
fi

# codegraph 遥测默认开启，会上报匿名使用统计
if want codegraph && command -v codegraph >/dev/null 2>&1; then
  codegraph telemetry status 2>/dev/null | grep -q "Telemetry: enabled" && echo "遥测开启  codegraph  「运行 codegraph telemetry off」"
fi
exit 0
