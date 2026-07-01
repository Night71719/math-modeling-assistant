# 数学建模训练记录助手

一个面向数学建模训练小组的中文协作工作台。网页既可以纯本地使用，也可以连接 Supabase，通过项目分享码让三名队员联机同步。

## 直接使用

双击 `index.html` 即可进入本地模式。数据保存在当前浏览器的 `localStorage` 中。

联机模式建议通过 GitHub Pages 或其他静态网站服务打开，以避免浏览器对本地文件网络请求的限制。

## 开启 Supabase 联机

1. 登录 [Supabase](https://supabase.com/) 并新建项目。
2. 打开项目的 **SQL Editor**，复制并运行 `supabase-schema.sql` 的全部内容。
3. 打开 **Authentication → Providers → Anonymous Sign-Ins**，启用匿名登录。
4. 打开 **Project Settings → API**，找到：
   - Project URL
   - anon key 或 publishable key
5. 编辑 `config.js`：

```js
window.MCM_CLOUD_CONFIG = {
  url: "https://你的项目编号.supabase.co",
  anonKey: "你的匿名密钥"
};
```

匿名密钥本来就用于网页前端，可以随静态网站公开；不要把 `service_role` 密钥放进本项目。

完成后：

- 在某个训练项目中点击“开启本项目联机”；
- 将生成的分享码发给队友；
- 队友在首页点击“加入联机项目”，输入分享码；
- 页面会自动同步并接收 Supabase Realtime 更新。

当前同步方式为“项目级最后保存版本优先”。它适合三人训练原型，但不建议多人同时编辑同一段论文正文。

## 上传 GitHub

### 一键上传

1. 在 GitHub 新建一个空仓库；
2. 双击 `一键上传到GitHub.cmd`；
3. 首次运行时粘贴仓库 HTTPS 地址；
4. 脚本会初始化 Git、提交并推送到 `main` 分支。

上传完成后，在 GitHub 仓库的 **Settings → Pages** 中：

1. 将 Source 选择为 **Deploy from a branch**；
2. Branch 选择 **main**；
3. 文件夹选择 **/ (root)**；
4. 点击 **Save**。

后续修改后再次双击脚本即可继续上传。

### 手动上传

也可以把整个文件夹拖入 GitHub 网页，或使用普通 Git 命令提交。

## 文件说明

- `index.html`：完整网站。
- `config.js`：Supabase 前端配置。
- `supabase-schema.sql`：数据表、权限、分享码函数和 Realtime 初始化。
- `一键上传到GitHub.cmd`：Windows 一键提交和推送。

## 数据安全

- 数据库启用了 RLS。
- 匿名用户只能读取和修改自己已加入的项目。
- 分享码用于加入项目，请只发送给队友。
- 删除浏览器数据前，建议先使用网站内的 JSON 备份功能。
