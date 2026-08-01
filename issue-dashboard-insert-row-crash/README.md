# Dashboard 插入行导致 Viewer 页面崩溃

## 环境

- macOS 26.5.2 (25F84)
- Node.js 24.15.0
- Univer CLI 0.3.9 (f3e7590)
- pnpm 11.9.0

## 从空目录复现

```bash
git clone https://github.com/stan373/univer-cli-repros.git
cd univer-cli-repros/issue-dashboard-insert-row-crash
npm install -g univer-cli@0.3.9
univer daemon start
univer open dashboard-insert-row-crash.univer --unit Ct1A0c
```

1. 在浏览器中打开上一步打印的 Viewer URL。
2. 打开 `Dashboard` 工作表。
3. 选择第 67 行（或该区域附近任一整行）。
4. 右键行号，点击 `Insert 1 rows above`（`Insert 1 rows after` 也可能触发）。

## 实际结果

Viewer 立即崩溃，页面显示 `This page crashed / 127.0.0.1 crashed unexpectedly`。

## 预期结果

成功插入一行；即使图表、嵌入简报或公式需要重新定位，Viewer 也不应崩溃。

## 复现文件

`dashboard-insert-row-crash.univer` 是 Harbourline 虚构饮料业务 Demo，不含真实客户、联系方式、本机路径、Token、Cookie 或密码。
