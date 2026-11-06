# Platform Requirements
# 平台要求

One block per device the release checklist's platform argument names (`pc`,
`console`, `mobile`; `all` is all three). Copy only the blocks named. They hold
no certification or store-SDK rows: those are in the `certification-<tier>.md`
templates, chosen by `platform.cert_tier`, not by the device.
发布检查表的 platform 参数每指定一个设备（`pc`、
`console`、`mobile`；`all` 表示三者全部），这里就有一个对应的块。只复制被指定的块。这些块不含
认证或商店-SDK 相关条目：那些位于 `certification-<tier>.md`
模板中，由 `platform.cert_tier` 选择，而不是由设备决定。

### Platform Requirements: PC
### 平台要求：PC
- [ ] Minimum and recommended specs verified and documented
- [ ] 最低与推荐配置已验证并记录
- [ ] Keyboard+mouse controls fully functional
- [ ] 键鼠控制完全可用
- [ ] Controller support tested (Xbox, PlayStation, generic)
- [ ] 手柄支持已测试（Xbox、PlayStation、通用）
- [ ] Resolution scaling tested (1080p, 1440p, 4K, ultrawide)
- [ ] 分辨率缩放已测试（1080p、1440p、4K、超宽屏）
- [ ] Windowed, borderless, and fullscreen modes working
- [ ] 窗口、无边框与全屏模式均可正常工作
- [ ] Graphics settings save and load correctly
- [ ] 图形设置能正确保存与加载

### Platform Requirements: Console
### 平台要求：主机
- [ ] Platform-specific controller prompts display correctly
- [ ] 平台专属手柄按键提示显示正确
- [ ] Suspend/resume works correctly
- [ ] 挂起/恢复正常工作
- [ ] User switching handled properly
- [ ] 用户切换处理得当
- [ ] Network connectivity loss handled gracefully
- [ ] 网络连接中断时能优雅处理
- [ ] Storage full scenario handled
- [ ] 存储空间已满场景已处理

### Platform Requirements: Mobile
### 平台要求：移动端
- [ ] App store guidelines compliance verified
- [ ] 应用商店指南合规性已验证
- [ ] All required device permissions justified and documented
- [ ] 所有必需的设备权限均已说明理由并记录
- [ ] Privacy policy linked and accurate
- [ ] 隐私政策链接有效且内容准确
- [ ] Data safety/nutrition labels completed
- [ ] 数据安全/营养标签已完成
- [ ] Touch controls tested on multiple screen sizes
- [ ] 触控操作已在多种屏幕尺寸上测试
- [ ] Battery usage within acceptable range
- [ ] 电量消耗处于可接受范围
- [ ] Background behavior correct (pause, resume, terminate)
- [ ] 后台行为正确（暂停、恢复、终止）
- [ ] Push notification permissions handled correctly
- [ ] 推送通知权限处理正确
- [ ] In-app purchase flow tested (if applicable)
- [ ] 应用内购买流程已测试（如适用）
- [ ] App size within store limits
- [ ] 应用体积在商店限制之内
