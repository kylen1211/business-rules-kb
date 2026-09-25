#!/usr/bin/env python3
"""sum-svg-diagram · 结构几何自检脚本(第四步"渲染自查"的可选补充闸门)

用途:对已按母版画好的派生 SVG,机械核验三类几何铁律有没有被破坏——
  1. 连线(<path>)不穿越任何内容卡片的实体矩形;
  2. 连线的端点(入口/出口落点)不落在任何泳道/层标签芯片的矩形范围内;
  3. 药丸/标签(pill/badge)之间、与卡片之间、与标签芯片之间无包围盒重叠。
分别对应 SKILL.md 的"连线不穿卡片"铁律、"通用走线附则·芯片避让"、"无标签重叠/无悬空标签"。

不做的事:不判断颜色/字体/文字内容是否正确,不识别业务语义,不替代人工渲染
自查——母版本身的视觉观感、内容忠实度仍需人读一遍截图。本脚本只做纯几何
检测,零业务词汇、零项目耦合,可以在任何一张按母版画出的派生图上直接跑。

用法:
    python3 geo_check.py <path/to/derived.svg>
退出码:0 = 全部通过;1 = 发现至少一处违规(详情打印到 stdout);2 = 用法/解析错误。
依赖:仅 Python 标准库(xml.etree.ElementTree / re / sys),不装任何第三方包。

分类方法(适用于两张母版 flow-master / architecture-master 派生图,靠两张母版
共用的作者约定识别元素类型,不依赖任何具体项目的坐标或命名):
  - 卡片(card):filter id 含 "card"(不分大小写,兼容 card-shadow 与 cardShadow
    两种命名)的 <g filter="..."> 组内,只取第一个 <rect> 作为卡片本体的包围盒;
    组内其余 rect(如卡片左上角的来源标签芯片)是卡片内部装饰,不重复归类、
    不再下钻。
  - 药丸/标签(pill):filter id 含 "badge" 或 "pill" 的元素——可能是包着 pill 的
    <g filter="...">(取组内第一个 rect),也可能是 filter 直接写在 <rect> 自身上
    (architecture-master 的画法)。
  - 泳道或层容器(lane):自身带 stroke-dasharray 且宽度 >800 的大尺寸矩形。
  - 标签芯片(chip):不在任何 card/pill 分组内、自身无 filter、小圆角(rx 4-8)、
    宽度 <400、高度 15-35 的矩形——两张母版里泳道/层左上角的名称芯片都是这种画法。
"""
import re
import sys
import xml.etree.ElementTree as ET


def local(tag):
    return tag.split('}')[-1] if '}' in tag else tag


def rect_box(el):
    try:
        x = float(el.get('x', 0))
        y = float(el.get('y', 0))
        w = float(el.get('width', 0))
        h = float(el.get('height', 0))
    except (TypeError, ValueError):
        return None
    if w <= 0 or h <= 0:
        return None
    return (x, y, x + w, y + h)


def filter_kind(filter_attr):
    if not filter_attr:
        return None
    v = filter_attr.lower()
    if 'card' in v:
        return 'card'
    if 'badge' in v or 'pill' in v:
        return 'pill'
    return None


def collect_rects(root):
    """单趟遍历,把 rect 分成 card / pill / lane / chip 四类(见模块 docstring)。"""
    cards, pills, lanes, chips = [], [], [], []

    def classify_group(g_el, kind):
        """组内只取第一个 <rect> 作为该分类的代表矩形,不下钻组内其余装饰元素。"""
        for child in g_el:
            if local(child.tag) == 'rect':
                box = rect_box(child)
                if box:
                    (cards if kind == 'card' else pills).append(box)
                break

    def walk(el):
        tag = local(el.tag)
        if tag == 'g':
            k = filter_kind(el.get('filter'))
            if k:
                classify_group(el, k)
                return  # 命中的分组到此为止,组内其余内容不再继续分类下钻
        elif tag == 'rect':
            own_kind = filter_kind(el.get('filter'))
            box = rect_box(el)
            if box:
                w, h = box[2] - box[0], box[3] - box[1]
                if own_kind == 'card':
                    cards.append(box)
                elif own_kind == 'pill':
                    pills.append(box)
                elif el.get('stroke-dasharray') and w > 800:
                    lanes.append(box)
                elif (not el.get('filter')
                      and el.get('rx') in ('4', '5', '6', '7', '8')
                      and w < 400 and 15 <= h <= 35):
                    chips.append(box)
        for child in el:
            walk(child)

    walk(root)
    return cards, pills, lanes, chips


def collect_paths(root):
    paths = []
    for el in root.iter():
        if local(el.tag) == 'path':
            d = el.get('d', '')
            coords = re.findall(r'[ML]\s*(-?[\d.]+)[,\s](-?[\d.]+)', d)
            pts = [(float(x), float(y)) for x, y in coords]
            if len(pts) >= 2:
                paths.append(pts)
    return paths


def seg_crosses_rect(p1, p2, rect, tol=0.5):
    """判断轴对齐线段 p1->p2 是否穿越 rect 内部(端点落在边界上不算穿越)。
    非正交线段(两张母版的连线画法不产生这种线)返回 None,调用方跳过不判。"""
    x1, y1 = p1
    x2, y2 = p2
    rx1, ry1, rx2, ry2 = rect
    rx1, ry1, rx2, ry2 = rx1 + tol, ry1 + tol, rx2 - tol, ry2 - tol
    if rx2 <= rx1 or ry2 <= ry1:
        return False
    if abs(y1 - y2) < 1e-6:
        if not (ry1 < y1 < ry2):
            return False
        xlo, xhi = sorted((x1, x2))
        return not (xhi <= rx1 or xlo >= rx2)
    if abs(x1 - x2) < 1e-6:
        if not (rx1 < x1 < rx2):
            return False
        ylo, yhi = sorted((y1, y2))
        return not (yhi <= ry1 or ylo >= ry2)
    return None


def rects_overlap(a, b):
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    return not (ax2 <= bx1 or bx2 <= ax1 or ay2 <= by1 or by2 <= ay1)


def point_in_rect(pt, rect, tol=0.5):
    x, y = pt
    rx1, ry1, rx2, ry2 = rect
    return rx1 + tol < x < rx2 - tol and ry1 + tol < y < ry2 - tol


def run_checks(cards, pills, lanes, chips, paths):
    violations = []

    for pi, pts in enumerate(paths):
        for i in range(len(pts) - 1):
            for ci, rect in enumerate(cards):
                if seg_crosses_rect(pts[i], pts[i + 1], rect) is True:
                    violations.append(
                        f"[连线穿卡片] path#{pi} 线段 {pts[i]}→{pts[i + 1]} 穿越 card#{ci} {rect}")

    for pi, pts in enumerate(paths):
        for pt in (pts[0], pts[-1]):
            for chi, rect in enumerate(chips):
                if point_in_rect(pt, rect):
                    violations.append(
                        f"[连线落芯片] path#{pi} 端点 {pt} 落在 chip#{chi} {rect} 范围内")

    for i in range(len(pills)):
        for j in range(i + 1, len(pills)):
            if rects_overlap(pills[i], pills[j]):
                violations.append(f"[药丸重叠] pill#{i} {pills[i]} 与 pill#{j} {pills[j]}")
        for ci, cr in enumerate(cards):
            if rects_overlap(pills[i], cr):
                violations.append(f"[药丸压卡片] pill#{i} {pills[i]} 与 card#{ci} {cr}")
        for chi, cr in enumerate(chips):
            if rects_overlap(pills[i], cr):
                violations.append(f"[药丸压芯片] pill#{i} {pills[i]} 与 chip#{chi} {cr}")

    return violations


def main():
    if len(sys.argv) != 2:
        print("用法: python3 geo_check.py <svg路径>")
        sys.exit(2)
    path = sys.argv[1]
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as e:
        print(f"XML 解析失败,先修 XML 语法再跑几何自检:{e}")
        sys.exit(2)

    cards, pills, lanes, chips = collect_rects(root)
    paths = collect_paths(root)
    violations = run_checks(cards, pills, lanes, chips, paths)

    print(f"解析到:{len(cards)} 张卡片 / {len(pills)} 个药丸 / "
          f"{len(lanes)} 条泳道或层容器 / {len(chips)} 个标签芯片 / {len(paths)} 条连线")

    if violations:
        print(f"\n发现 {len(violations)} 处几何违规:")
        for v in violations:
            print(" -", v)
        sys.exit(1)

    print("\n几何自检通过:连线不穿卡片、连线端点不落标签芯片、药丸无重叠。")
    sys.exit(0)


if __name__ == "__main__":
    main()
