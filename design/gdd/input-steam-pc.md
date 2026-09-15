# Steam PC 输入规格

> **Status**: In Review — 2026-09-11 fresh senior：STEAM_PC R3–R8局部APPROVED WITH ADVISORIES，R1/R2本地回归CLOSED；极小deadzone下溢P3、完整ABI/Windows/性能门OPEN，battle_ready=false。详见production/playtest-evidence/2026-09-11-pc-input-r3-r8.md。

## Overview

Windows首发采用WASD和映射后的手柄左摇杆移动、鼠标或键盘/手柄操作菜单。InputSystem采样与Player消费同tick完成；攻击自动释放。此文是PC来源、仲裁、输入生命周期和Meta UI的权威，移动端合同位于input-system.md的MOBILE_TOUCH章节。

## Player Fantasy

方向即身法：方向键改变即转向、松开即停止；摇杆超过死区后满速移动。暂停选择、失焦与重开不会让旧输入悄悄继续移动。

## Detailed Rules

1. `active_profile=STEAM_PC`、`profile_revision=1`；其它profile在当前生产入口返回INVALID_CONFIG。PC不创建VirtualJoystick、不配置shield capacity、不读取touch action。移动action只允许键盘绑定。
2. 只采已知映射控制器，device ID最小者为当前控制器；键盘任一方向按住优先（相反键同时按为ZERO，不能泄漏摇杆移动）。手柄连接/断开触发source retirement并要求所有来源中立。未知设备忽略。
3. source={NONE,KEYBOARD,GAMEPAD}；neutral→active或source改变checked递增generation，不因方向改变生成新press。同一keyboard epoch中的W→W+S→W保持generation，完整释放后再按恰增1；从其它source进入抵消ZERO会退休旧source，直到新的非零采样才递增。生成失败fail closed。ZERO carrier generation=-1；有效carrier为finite单位方向。
4. GameRoot创建每局carrier和PC phase context；context固定battle generation，单tick租约先采Input、再Player验证identity/tick/lease并消费一次、最后关闭租约。补帧每tick重新采样。旧/重复tick和旧context零位置修改。当前Stage/Save仍为ADR-0003运行适配，完整七phase ABI继续单列未完成。
5. 暂停标量commit先于任何setter：LOCK_PENDING、callbacks=true、runtime=false、shield_service=false；PC从不启touch service。清carrier后GameRoot冻结场景并呈现modal。重复cancel幂等；terminal先TERMINATED+所有writer关闭，再清理节点。
6. resume事务期间禁止重入Continue与gameplay tick；Input保持FROZEN，依次取得gate、unpause、隐藏modal/转移focus，每个可重入边界后校验同一battle identity、state及focus/revision。通过后才激活Input并释放gate，再复核一次。失焦或revision变化退回可交互暂停，Input关闭且carrier清零；回焦不得自动重试，须新的显式Continue。结束/替换的旧battle不得被恢复尾段覆盖；恢复首tickZERO。只在全部方向action释放且所有已知摇杆length<=deadzone的采样后解除neutral barrier。held-only是正常等待，可完成UI恢复但玩家仍不移动。释放后新输入下一tick生效。BattleUI只读neutral_required显示等待说明：普通暂停、升级modal和恢复/active hotplug的HUD均覆盖；等待解除后移除说明，UI不得再次采样或解除输入门。
7. focus loss暂停（升级选择保持），focus gain不自动恢复；失焦时禁止resume。失焦/重连使旧source失效。新战斗若输入原本中立可立即接受fresh input，若已按住则要求释放。
8. Meta bindings：Tab/DpadDown下一项、ShiftTab/DpadUp上一项、Left/DpadLeft左移、Right/DpadRight右移、Enter/Space/South激活、Escape/East返回、Plus/Equal/RightShoulder增、Minus/LeftShoulder减。P/Start可暂停，R只在普通暂停时继续；这些入口由同一GameRoot dispatcher处理。Echo和非press不激活；绑定事件即使是release、echo或被拒绝的设备也必须消费，不能再由Godot默认Control触发；BOOT清除规格外默认GUI导航/激活binding，Up/Down/KpEnter不作为额外别名。
9. Home焦点首选开始、可购买功法可循环；Battle焦点7001；modal只包含可见enabled选择，背景pause按钮disabled且FOCUS_NONE；关闭modal才恢复背景按钮与focus，焦点不外泄；Settlement为重开/首页。Back在升级选择无业务作用，普通暂停为继续，Settlement返回首页。增减目前无可调整控件时零业务作用。
10. 7001={screen_generation=battle_generation, layout_generation=1, monotonic event/command ID per screen}；GameRoot只接受当前generation内first-unseen正ID。新battle重置该generation高水位，旧callback与duplicate零effect。native accessibility按mobile future-port单列。

## Formulas

`d=stick_deadzone`，要求finite且`0<d<1`，默认0.20；比较前将d转换为与Godot Vector2分量相同的real_t精度，保证轴值0.20的闭边界一致；转换后仍须finite且0<d<1，否则INVALID_CONFIG且不发布carrier/callback。0.999999999→1与1e-50→0必须拒绝。键盘`k=(right-left,down-up)`；摇杆`j`来自所选mapped device，任一分量非finite为fault。键盘任一方向按下取`v=k`，否则`v=ZERO if length(j)<=d else j`。非零finite `s=max(abs(v.x),abs(v.y)); u=(v/s)/length(v/s)`，不会对已过死区的摇杆再次施加deadzone。neutral要求全部键盘action未按下且全部mapped stick在死区内。

## Edge Cases

对向键抵消不等于neutral；0.01漂移与边界0.20为ZERO；0.2001输出单位方向。对角长度1。held pause/reconnect/focus loss要求中立；UI继续不充当movement fresh edge。多fixed tick每次采样/消费独立，暂停和结束不再推进租约。未识别controller不能驱动。非法profile/deadzone配置拒绝初始化。

## Dependencies

上游GameRoot、ADR-0004/0005、生产config、Godot InputMap。下游PlayerController、BattleUI及Home/Settlement。F2/safe-area、VJ/Shield、ADR-0001、Android/iOS manifests仅MOBILE_TOUCH future-port，不是PC启动依赖。

## Tuning Knobs

`assets/config/production_defaults.json.input.stick_deadzone=0.20`；键盘和Meta绑定由项目表定义。修改profile或死区需新的证据hash。移动速度沿用Player配置，未用本次输入改动改变战斗数值。

## Acceptance Criteria

- PC01 配置：STEAM_PC成功且active_vj_count=0；未知profile及0/1/NaN死区拒绝。
- PC02 数学：0/0.01/0.20/0.2001、对角、NaN/Inf与键盘/摇杆同时输入各有唯一oracle。
- PC03 中立：W+S虽为ZERO仍阻断neutral；held键/轴跨pause不能自动移动；释放/回中后新press生效；恢复首tickZERO。
- PC04 租约：每个fixed tick恰一次Input/Player，重复、旧battle/context/lease拒绝且位置不改；hitch多个tick计数相等。
- PC05 生命周期：pause冻结位置与active ticks；focus loss冻结，回焦不恢复，失焦resume拒绝；teardown后carrier ZERO、context retired。
- PC06 设备：已知设备选择稳定，未知设备忽略；连接变化清source并要求neutral；Windows真机补disconnect/reconnect与Steam Input重映射。
- PC07 UI：八行binding及P/R shortcut的键码/修饰键/手柄按钮/事件数/deadzone精确存在，默认GUI事件表为空；真实Godot事件驱动Home→Battle→Pause/Upgrade→Settlement；一次press一次业务；echo零效果；modal焦点不外泄。
- PC08 identity：首局7001、重复拒绝、第二局首击成功、旧局命令拒绝。
- PC09 显示：1280×720及960×540可见焦点/按钮与neutral提示；导出后人工多分辨率复测。
- PC10 平台：Windows release exe+pck hash绑定物理WASD、至少一种mapped控制器、deadzone、remap、focus、held、第二局pause和完整菜单旅程。未运行记NOT_RUN。

PC01–09以本地明确范围测试给证据；PC10只由Windows设备填写。Input工作负载需独立测量，不以Stage绘制性能代替。
