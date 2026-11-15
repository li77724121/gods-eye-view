# 本仓库的用途与部署说明

这是 [bilawalsidhu/gods-eye-view](https://github.com/bilawalsidhu/gods-eye-view) 的 fork，
用于搭建一个对外公开的在线站点：**https://gev.one1.kdns.fr/**

- 上游项目：God's Eye View — A spy-satellite simulator in your browser. Except the data is real.
- 授权：MIT（见 `LICENSE`，版权归 Bilawal Sidhu 及贡献者所有）。本 fork 保留原始署名，不改变授权。
- 本站改动：只加了一个启动脚本和这份部署说明，**未修改任何业务代码**，便于持续同步上游。

## 架构（重要）

上游的 `npm run dev` **就是整个应用**：Vite 负责前端，同时在同一个 Node 进程里跑
`/api/*` 的 Provider 代理中间件（ADS-B、AIS、Overpass、天气、OpenAI Realtime 等）。
因此：

- **不能**用 Cloudflare Pages / Netlify 之类的纯静态托管发布（`vite build` 出来的 `dist/`
  没有那些代理路由，图层会大面积不可用）。
- 正确做法：在一台常在线的主机上跑 `npm run dev`，再用 Cloudflare Tunnel / Nginx 反代到一个域名。
  官方 Docker 镜像（`compose.yaml`）走的是同一条路。

## 本机的部署方式

```bash
# Node 要求 24.14+（本机用 brew 的 node@24）
export PATH=/opt/homebrew/opt/node@24/bin:$PATH
npm ci --include=dev        # 注意：NODE_ENV=production 会跳过 devDependencies，导致 vite 不存在
./scripts/start-public.sh   # HOST=127.0.0.1 PORT=4190 GEV_ALLOWED_HOSTS=gev.one1.kdns.fr
```

Cloudflare Tunnel 里对应的一条 ingress：

```yaml
  - hostname: gev.one1.kdns.fr
    service: http://127.0.0.1:4190
```

DNS 由 `cloudflared tunnel route dns <tunnel-id> gev.one1.kdns.fr` 创建 CNAME。

## 安全红线：公开站点只跑 keyless

上游 README 明确警告：这台服务器会把**你配置的 Provider 密钥代理给任何能访问它的人**。
所以对外站点必须：

- `.env` 里**不要**写 `CESIUM_ION_TOKEN` / `GOOGLE_MAPS_API_KEY` / `OPENAI_API_KEY` /
  `AISSTREAM_API_KEY` / `FIRMS_MAP_KEY` / `TOMTOM_API_KEY` / `MAPILLARY_CLIENT_TOKEN` /
  `WORLDNEWSAPI_KEY` 等任何密钥。
- 想用需要密钥的图层（真实 3D 地形、3D 建筑、真船、火灾、街景、语音），
  请在自己电脑上本地跑一份加 `POWER UP → Provider Settings`，**不要**开在公网实例上。

上游对 Provider Settings 有防护，会拒绝带代理头（`X-Forwarded-For` 等）和 Host 非本机的请求，
所以公网访客无法通过该界面写入密钥；但这只是第二道防线，第一道是不要放钥匙。

## 已验证的公开能力（无需任何密钥）

卫星影像（Esri，OSM 兜底）、实时航班、军用航班、卫星轨道、地震、NASA FIRMS 之外的环境图层、
公开摄像头、无线电、发射任务、以及大部分 UI/搜索。缺密钥的图层会在面板上显示「等待密钥」。

## 同步上游

```bash
git fetch upstream && git merge upstream/main     # 本 fork 只在自己的分支上加文件，冲突面很小
```

## 运维

- 站点进程：`scripts/start-public.sh`（日志 `/tmp/gev-public.log`）
- 隧道：`launchctl kickstart -k gui/$(id -u)/com.leo.cloudflared`
- 健康检查：`curl -s -o /dev/null -w '%{http_code}\n' https://gev.one1.kdns.fr/`
