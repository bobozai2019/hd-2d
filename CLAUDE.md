# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4.6 椤圭洰 鈥?HD-2D 鎶€鏈獙璇侀」鐩€傜洰鏍囨槸鍦?Godot 涓鍒诲叓鏂规梾浜洪鏍肩殑 HD-2D 娓叉煋鏁堟灉锛?D 鍦板浘 + 2D 鍍忕礌瑙掕壊 + 鍏夊奖鍚庡鐞嗭級銆?
**褰撳墠闃舵**锛氭棭鏈熸妧鏈獙璇併€傚凡瀹屾垚鍩虹鐩告満鎺у埗鍜岃鑹插姩鐢?Sprite3D銆?
## Dev Commands

```bash
# 鍚姩 Godot 缂栬緫鍣紙闇€瑕?Godot 4.6 鍦?PATH 涓級
godot -e

# Headless 杩愯涓诲満鏅紙鐢ㄤ簬楠岃瘉鍦烘櫙鍔犺浇锛?godot --headless --quit

# 浣跨敤 GodotIQ 宸ュ叿楠岃瘉鍦烘櫙
# godotiq_check_errors / godotiq_verify_project_runs
```

鏃犳瀯寤烘楠ゃ€佹棤娴嬭瘯濂椾欢銆佹棤 lint銆傞」鐩湪 Godot 缂栬緫鍣ㄥ唴閫氳繃 F5 杩愯銆備娇鐢?GodotIQ MCP 宸ュ叿杩涜缂栬瘧妫€鏌ュ拰楠岃瘉銆?
## 浠撳簱鐩綍

- `project.godot` 鈥?Godot 椤圭洰閰嶇疆銆備富鍦烘櫙涓?`res://scenes/map3d/hd2d_effect_lab.tscn`銆?- `scripts/map3d/` 鈥?HD-2D 鐩稿叧鑴氭湰锛堢浉鏈烘帶鍒躲€佽鑹插姩鐢荤瓑锛夈€?- `scenes/map3d/` 鈥?HD-2D 鍦烘櫙鏂囦欢銆?- `scenes/map3d/characters/` 鈥?瑙掕壊 Sprite3D 鍦烘櫙銆?- `assets/generated/` 鈥?鐢熸垚鐨勭編鏈祫婧愶紙瑙掕壊鍔ㄧ敾甯х瓑锛夈€?- `docs/` 鈥?鎶€鏈枃妗ｅ拰鍙傝€冦€?- `docs/production/` 鈥?閲忎骇瑙勮寖锛堜唬鐮併€乁I銆佽祫浜с€佷粨搴撳崼鐢燂級銆?- `tasks/` 鈥?浠诲姟璁″垝鍜?PRD銆?- `addons/` 鈥?Godot 鎻掍欢锛坓odotiq銆乬odot_editor_logger銆乻cene_bundle锛夈€?- `.codex/skills/` 鍜?`.agents/skills/` 鈥?椤圭洰鏈湴浠ｇ悊宸ヤ綔娴併€傚綋浠诲姟鍖归厤鍏惰Е鍙戞潯浠舵椂浣跨敤銆?
### 鏂囨。瑙勮寖

docs/ 鐩綍缁撴瀯锛歚hd2d/`锛圚D-2D 鎶€鏈枃妗ｏ級銆乣production/`锛堥噺浜ц鑼冿級銆?
鍛藉悕瑙勫垯锛?- 璁捐鏂囨。锛歚鏁板瓧-涓枃鏍囬.md`
- 璁″垝鏂囨。锛歚YYYY-MM-DD-鑻辨枃鎻忚堪.md`

## 浠ｇ悊宸ヤ綔娴佽姹?
- 缂栬緫鍓嶅厛闃呰鐩稿叧宸叉湁浠ｇ爜銆傚尮閰嶆湰鍦版ā寮忥紝涓嶈寮曞叆鏂伴鏍笺€?- 淇濈暀鐢ㄦ埛鐨勫伐浣滃尯鍙樻洿銆傚伐浣滄爲鍙兘鏈夋湭鎻愪氦鐨勬敼鍔紱闄ら潪鏄庣‘瑕佹眰锛屼笉瑕?reset銆乧heckout 鎴栬繕鍘熸枃浠躲€?- 淇濇寔缂栬緫鑱氱劍浜庢墍璇锋眰鐨勮涓哄彉鏇淬€傞櫎闈炴纭€ч渶瑕侊紝鍚﹀垯閬垮厤澶ц寖鍥撮噸鏋勩€?- 瀹ｇО瀹屾垚涔嬪墠锛岃繍琛屾渶灏忚寖鍥寸殑鏈夋晥楠岃瘉鍛戒护骞舵姤鍛婃墽琛岀粨鏋溿€?- 閬囧埌 bug 鎴栨祴璇曞け璐ユ椂锛屽厛瀹氫綅鏍瑰洜鍐嶄慨鏀逛唬鐮併€?- 鍒涙剰鎬у姛鑳藉紑鍙戙€乁I 杞崲鎴栬緝澶ц妯＄殑瀹炵幇宸ヤ綔锛屽簲浣跨敤 `.agents/skills/` 鎴?`.codex/skills/` 涓尮閰嶇殑椤圭洰鎶€鑳姐€?- 褰撳墠浠撳簱绂佺敤鎵€鏈?`superpowers` 鐩稿叧 skills銆傚嚒鏄潵婧愪簬 `obra/superpowers` 鎴栧悕绉板寘鍚?`using-superpowers`銆乣test-driven-development`銆乣systematic-debugging`銆乣writing-plans`銆乣executing-plans`銆乣subagent-driven-development`銆乣verification-before-completion`銆乣finishing-a-development-branch`銆乣using-git-worktrees`銆乣requesting-code-review`銆乣receiving-code-review`銆乣dispatching-parallel-agents`銆乣brainstorming`銆乣writing-skills` 鐨勫伐浣滄祦锛屼竴寰嬩笉瑕佸湪鏈」鐩腑瑙﹀彂鎴栧紩鐢ㄣ€?
## Godot Project Config

- Renderer: **Forward Plus** (`rendering/renderer/rendering_method`)
- Physics: **Jolt Physics**
- Display: `canvas_items` stretch mode, `expand` aspect
- Window driver: `d3d12` (Windows)
- Main scene: `scenes/map3d/hd2d_effect_lab.tscn`
- Plugins: godotiq, godot_editor_logger, scene_bundle

## 浠ｇ爜瑙勮寖

杩涘叆閲忎骇鍚庯紝璇︾粏瑙勮寖浠?`docs/production/` 涓哄噯銆備互涓嬫槸绮剧畝閫熸煡銆?
### 鏂囦欢涓庣洰褰曞懡鍚?
| 绫诲瀷 | 瑙勮寖 | 绀轰緥 |
|------|------|------|
| GDScript (.gd) | snake_case | `hd2d_effect_lab.gd` |
| 鍦烘櫙 (.tscn) | snake_case | `hd2d_effect_lab.tscn` |
| 鏁版嵁 (.tres) | snake_case | `some_resource.tres` |
| 鐩綍 | snake_case | `scripts/map3d/`, `scenes/map3d/` |

### 绫诲０鏄?
- **閫昏緫灞?*锛氭牴鎹渶瑕佸０鏄?`class_name`锛孭ascalCase
- **UI 鑴氭湰**锛堝満鏅牴鑺傜偣锛夛細涓嶅０鏄?`class_name`锛屽尶鍚嶇被 `extends Control`
- **宸ュ叿鑴氭湰**锛氫笉澹版槑 `class_name`锛屽尶鍚嶇被 `extends SceneTree`
- 璺ㄦ枃浠剁被鍨嬪紩鐢?*蹇呴』**鐢?`preload()` 甯搁噺锛岀姝㈢洿鎺ョ敤 `class_name` 浣滅被鍨嬫敞瑙?
```gdscript
# 姝ｇ‘
const SomeModuleScript = preload("res://scripts/some_module.gd")
var _module: SomeModuleScript

# 閿欒 鈥?寰幆寮曠敤
var _module: SomeModule
```

鍚庣紑绾﹀畾锛歚Def`锛堣祫婧愬畾涔夛級銆乣State`锛堝彲鍙樼姸鎬侊級銆乣System`锛堥€昏緫绯荤粺锛夈€乣Context`锛圖I 瀹瑰櫒锛夈€乣Events`锛堜俊鍙锋€荤嚎锛夈€乣Manager`锛堢敓鍛藉懆鏈熺鐞嗗櫒锛?
### 鍙橀噺鍛藉悕

| 浣滅敤鍩?| 瑙勮寖 | 绀轰緥 |
|--------|------|------|
| 鍏叡瀛楁 | snake_case锛屾棤鍓嶇紑 | `var speed: float = 5.0` |
| 绉佹湁/鍐呴儴瀛楁 | `_` 鍓嶇紑 | `var _camera: Camera3D` |
| 鍦烘櫙鑺傜偣寮曠敤 | `@onready var _name: Type = $Path` | `@onready var _sprite: Sprite3D = $Sprite` |
| 甯搁噺锛堢被鍨嬪埆鍚嶏級 | PascalCase | `const SomeScript = preload(...)` |
| 甯搁噺锛堟暟鍊硷級 | SCREAMING_SNAKE_CASE | `const MAX_SPEED: float = 10.0` |

### 鍑芥暟鍛藉悕

| 绫诲瀷 | 瑙勮寖 | 绀轰緥 |
|------|------|------|
| 鍏叡鍑芥暟 | snake_case锛屽姩璇嶅紑澶?| `func setup(config) -> void:` |
| 绉佹湁鍑芥暟 | `_` 鍓嶇紑 | `func _update_camera() -> void:` |
| 淇″彿鍥炶皟 | `_on_` 鍓嶇紑 | `func _on_input_event() -> void:` |
| Godot 鐢熷懡鍛ㄦ湡 | 鏍囧噯鍛藉悕 | `func _ready() -> void:` |

- 鎵€鏈夊嚱鏁?*蹇呴』**澹版槑杩斿洖绫诲瀷锛坄-> void:`銆乣-> bool:`銆乣-> int:` 绛夛級
- 鍏叡 API 鍙傛暟搴旀坊鍔犵被鍨嬫彁绀?
### 淇″彿鍛藉悕

- **杩囧幓寮忓姩璇嶇煭璇?*锛宻nake_case
- 绂佹 `_signal` 鎴?`on_` 鍓嶇紑

```gdscript
signal position_changed(new_pos)    # 姝ｇ‘
signal animation_finished()          # 姝ｇ‘
signal on_position_changed()         # 閿欒 鈥?on_ 鍓嶇紑
signal position_change()             # 閿欒 鈥?闈炶繃鍘诲紡
```

### 娉ㄩ噴瑙勮寖

鍏佽锛氬尯鍩熷垎闅旓紙`# --- Section ---`锛夈€佺被鍨嬭ˉ鍏呫€佸垎缁勬爣棰樸€佸叧閿€昏緫璇存槑锛圵HY 涓嶆槸 WHAT锛?
绂佹锛歚##` docstring銆佸琛屾枃妗ｅ潡銆佽В閲?鍋氫粈涔?鐨勬敞閲娿€佹敞閲婃帀鐨勪唬鐮?
## 纭鍒?
### 绂佹鐩存帴璇诲浘

**Claude Code 涓嶅緱鐩存帴璇嗗埆浠讳綍鍥剧墖銆?* 鍖呮嫭浣嗕笉闄愪簬锛?
1. **绂佹**浣跨敤鍐呯疆澶氭ā鎬佽兘鍔涚洿鎺ュ垎鏋愮矘璐村埌娑堟伅涓殑鍥剧墖锛坆ase64 inline image锛?2. **绂佹**浣跨敤 Read 宸ュ叿璇诲彇鍥剧墖鏂囦欢璺緞
3. **蹇呴』**璋冪敤 `mcp__image-recognition__image_recognize` 宸ュ叿鏉ヨ瘑鍒浘鐗?
鏀寔鐨勫浘鐗囨牸寮忥細`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.bmp`, `.svg`, `.ico`, `.tga`

```bash
# 绂佹 鈥?鐩存帴鍒嗘瀽绮樿创鐨勫浘鐗?# 绂佹 鈥?鐢?Read 宸ュ叿璇诲浘鐗?
# 姝ｇ‘ 鈥?閫氳繃 MCP 鏈嶅姟璇嗗埆
mcp__image-recognition__image_recognize(image="screenshot.png", prompt="鎻忚堪鍥剧墖鍐呭")
```

**褰撶敤鎴风矘璐村浘鐗囧苟鎻愰棶鏃讹紝姝ｇ‘娴佺▼锛?*
1. 蹇界暐娑堟伅涓祵鍏ョ殑鍥剧墖鏁版嵁
2. 灏嗗浘鐗囦繚瀛樺埌涓存椂鏂囦欢锛堝鏋滈渶瑕侊級
3. 璋冪敤 `mcp__image-recognition__image_recognize` 璇嗗埆
4. 鍩轰簬 MCP 杩斿洖缁撴灉鍥炵瓟鐢ㄦ埛

## 璇█瑙勮寖

**鎵€鏈夋枃妗ｃ€佹妧鑳斤紙Skill锛夈€佸懡浠わ紙Command锛夈€丠ook 鏂囦欢蹇呴』浣跨敤涓枃缂栧啓銆?*

- 璁捐鏂囨。銆佽鍒掓枃妗ｃ€丳RD 绛夛細姝ｆ枃鐢ㄤ腑鏂?- `.agents/skills/*/SKILL.md`锛歞escription 瀛楁鍜屾鏂囩敤涓枃锛屼繚鐣?`name` 瀛楁涓鸿嫳鏂?- `.claude/commands/*.md`锛歞escription 瀛楁鍜屾鏂囩敤涓枃
- `.claude/hooks/*.md`锛氭鏂囩敤涓枃
- `.claude/knowledge/*.md`锛氭鏂囩敤涓枃
- 浠ｇ爜鍧楋紙GDScript銆乥ash銆丣SON 绛夛級鍐呭淇濇寔鍘熸牱锛屼笉缈昏瘧
- 鎶€鏈湳璇紙濡?HD-2D銆丮CP銆乀DD 绛夛級淇濇寔鑻辨枃
- 鏂囦欢璺緞淇濇寔鑻辨枃

## Knowledge Base

椤圭洰鐭ヨ瘑娌夋穩绯荤粺锛屼粠寮€鍙戜細璇濅腑鎹曡幏鏈変环鍊肩殑娲炲療锛屾寜棰嗗煙鍒嗙被瀛樺偍鍦?`.claude/knowledge/`銆?
寮€濮嬫煇棰嗗煙宸ヤ綔鍓嶏紝妫€鏌ュ搴斿垎绫绘枃浠惰幏鍙栧厛楠岀煡璇嗭細

- `.claude/knowledge/ui.md` 鈥?UI 妯″紡銆丆ontrol 鑺傜偣鍐崇瓥
- `.claude/knowledge/conventions.md` 鈥?浠ｇ爜椋庢牸鍜屾灦鏋勫喅绛?- `.claude/knowledge/debugging.md` 鈥?闄烽槺鍜岃皟璇曟妧宸?- `.claude/knowledge/godot.md` 鈥?寮曟搸鎬櫀鍜?workaround
- `.claude/knowledge/INDEX.md` 鈥?鐭ヨ瘑搴撶储寮?
浣跨敤 `/remember` 鎹曡幏鏂版礊瀵燂紝`/recall` 鎸夊叧閿瘝鎼滅储鐭ヨ瘑搴撱€?
## 楠岃瘉鎸囧紩

鏍规嵁淇敼鑼冨洿閫夋嫨楠岃瘉鏂瑰紡锛?
- 椤圭洰鏁翠綋瀹屾暣鎬э細`godot --headless --quit`
- 鑴氭湰缂栬瘧/杩愯鏃堕敊璇細浣跨敤 GodotIQ `godotiq_check_errors` / `godotiq_verify_project_runs`
- 璋冭瘯闃舵鎶ラ敊锛氫紭鍏堣鍙?`logs/godot.log`銆侴odotIQ 璋冭瘯鎺у埗鍙板彲鑳芥紡鎺?Debug/F5 杩愯鏃剁殑鍚庡彴閿欒锛屽挨鍏舵槸鐢ㄦ埛璇?鐐硅皟璇曟湁鎶ラ敊"鏃讹紝鍏堢湅姝ゆ棩蹇楀啀涓嬬粨璁恒€?- UI 甯冨眬/瑙嗚楠岃瘉锛歨eadless 鍦烘櫙鍔犺浇鎴栨埅鍥炬崟鑾?
濡傛灉鍥犵幆澧冧腑 PATH 鏈厤缃?Godot 鎴栫己灏戜緷璧栬€屾棤娉曡繍琛屽懡浠わ紝璇峰湪鏈€缁堝洖澶嶄腑濡傚疄璇存槑銆?
## 鏂囦欢鍜?Git 鍗敓

- 闄ら潪鐢ㄦ埛瑕佹眰锛屽惁鍒欎笉瑕佹彁浜ゃ€?- 闄ら潪浠诲姟鏄庣‘娑夊強锛屽惁鍒欎笉瑕佸皢 `.godot/`銆佹棩蹇椼€佹埅鍥炬垨鐢熸垚鐨?import 鏂囦欢浣滀负浠ｇ爜鍙樻洿鐨勪竴閮ㄥ垎淇敼銆?- 涓嶈浠呭洜涓虹湅璧锋潵鏈娇鐢ㄥ氨鍒犻櫎鏂囨。鎴栬祫婧愭枃浠躲€?- 鏂扮殑椤圭洰鏂囨。淇濇寔绠€娲佸拰鍙搷浣溿€?- 浠呭湪 Godot 纭疄闇€瑕佹垨灞炰簬宸茬紪杈戣祫婧愭祦绋嬫椂锛屾墠淇濈暀鐢熸垚鐨?`.uid` / `.import` 鏂囦欢銆?

<!-- myaitool-hub-start -->
## Shared myaitool hub

Shared skills, knowledge, and MCP management docs:
`D:/AIprogram/myaitool/docs/hub-management.md`

MCP server layout, distribution, security, and verification docs:
`D:/AIprogram/myaitool/docs/mcp-management.md`
<!-- myaitool-hub-end -->



