# 小白搜盘（fn-seekbox）

飞牛 fnOS 原生应用：在 NAS 上搜索百度、阿里云盘、夸克、天翼、UC、115、迅雷、123 等网盘链接。

- 包名：`fn-seekbox`
- 显示名：小白搜盘
- 仓库：https://github.com/kidoneself/fn-seekbox

安装后点击桌面图标即可使用。默认端口 `12668`。

## 目录

```
fn-seekbox/
├── manifest
├── ICON.PNG / ICON_256.PNG
├── app/bin/seekbox          # 后端
├── app/bin/gateway.py       # 静态页 + API 反代
├── app/web/                 # 前端构建产物
├── frontend/                # Vue 源码（改界面后 npm run build）
├── cmd/                     # 飞牛生命周期脚本
├── config/                  # privilege / resource
└── wizard/                  # 安装向导
```

不要把 `frontend/node_modules` 打进 FPK。
