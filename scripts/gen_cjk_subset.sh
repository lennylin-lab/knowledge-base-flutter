#!/usr/bin/env bash
# 再生成子集化中文字体：收集 lib/**/*.dart 中的唯一汉字 + 常用中文标点，
# 从系统 Noto Sans CJK SC 抽取字形，输出 assets/fonts/NotoSansSC-Subset.ttf。
# 依赖: pip install fonttools brotli
set -euo pipefail

SRC_TTC="${NOTO_CJK_TTC:-/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc}"
OUT_DIR="assets/fonts"
OUT="$OUT_DIR/NotoSansSC-Subset.ttf"

[[ -f "$SRC_TTC" ]] || { echo "字体源不存在: $SRC_TTC（可用 NOTO_CJK_TTC 覆盖）" >&2; exit 1; }
mkdir -p "$OUT_DIR"

# 1) lib 下唯一汉字 + 3500 常用字（覆盖服务端动态内容）+ 常用中文标点 + 全角空格
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CHARS=$(grep -rhoP '[\x{4e00}-\x{9fff}]' lib/ --include='*.dart' | sort -u | tr -d '\n')
COMMON=$(python3 -c "
import sys; s = open('$SCRIPT_DIR/cjk_common_3500.txt', encoding='utf-8-sig').read()
print(''.join(dict.fromkeys(c for c in s if '\u4e00' <= c <= '\u9fff')))")
CHARS="$CHARS$COMMON，。！？：；「」『』（）《》〈〉【】……——·、％　"

# 2) 抽取 SC face 并子集化（含 ASCII 可打印区，保证 UI 文本全走该字体）
python3 - "$SRC_TTC" "$OUT" "$CHARS" <<'EOF'
import sys
from fontTools.ttLib import TTCollection
from fontTools.subset import Subsetter, Options

src, out, chars = sys.argv[1], sys.argv[2], sys.argv[3]
ttc = TTCollection(src)
font = next(f for f in ttc.fonts
            if f['name'].getDebugName(16) == 'Noto Sans CJK SC'
            or (f['name'].getDebugName(1) or '').startswith('Noto Sans CJK SC'))
opts = Options()
opts.layout_features = ['*']
opts.name_IDs = ['*']
opts.hinting = False
opts.drop_tables += ['FFTM']
opts.notdef_outline = True
subsetter = Subsetter(options=opts)
subsetter.populate(text=chars + ''.join(chr(c) for c in range(0x20, 0x7F)))
subsetter.subset(font)
font.save(out)
EOF

ls -lh "$OUT"
