---
title: FlClash 链式代理接入 AdsPower 的完整排查记录
date: 2026-11-12 21:30:00
categories:
  - 工具实践
tags:
  - FlClash
  - Mihomo
  - AdsPower
  - Windows
  - 代理配置
  - 故障排查
description: 从日本前置连接住宅出口，到定位 AdsPower 协议错误、5 秒超时和 uTools 继承旧代理变量，记录配置、实测与最终修复。
---

我原本只想完成一条链路。赔钱机场的日本节点比较稳定，StepFly 里有多个标注“家宽”的节点，于是打算先经过日本，再连接住宅出口，最后交给 AdsPower 的 Windows 环境使用。

实际排查持续了几个小时。链式 YAML 生成以后，普通浏览器已经能访问目标网站，AdsPower 却反复提示“连接测试失败”和“未检测到系统代理”。中间经历了协议调整、ZeroOmega 对照测试、环境变量清理和临时白名单测试，最后追到了启动器进程的环境变量。

最终，AdsPower 的网络诊断成功显示了系统代理的台湾出口。这里把配置过程、走过的弯路和验证方法整理下来。

文中公网 IP 统一使用“系统出口 A”和“住宅出口 B”代称。配置示例使用占位节点，订阅地址、UUID、密码和原始日志中的签名参数均已脱敏。

<!-- more -->

## 运行环境与最初的目标

这次使用 Windows 10 专业版，系统构建为 19045。FlClash 安装中的内核报告为 Mihomo v1.19.33。AdsPower 客户端为 8.9.23，排查过程中补丁版本由 2.8.9.2 更新到 2.9.0.2，最终使用 SunBrowser 的 Windows 环境。

最初计划的链路是本机经过赔钱机场的日本节点，再到 StepFly 家宽节点，最终访问网站。日本节点负责连接入口，住宅节点负责最后一跳的出口。

本地 FlClash 里有三个订阅，合计 231 条节点记录，其中包含 5 条流量、到期或入口提示。筛选结果如下。

| 来源 | 本地记录数 | 本次关注的节点 |
| --- | ---: | --- |
| 赔钱机场 | 64 | 15 个日本节点 |
| StepFly | 123 | 30 个带“家宽”标签的节点 |
| Basic | 44 | 14 个带“住宅”标签的节点 |

最早手工计数时把 StepFly 家宽节点写成了 32 个，后续用配置解析脚本逐条筛选，修正为 30 个。后面的测试和配置均采用修正后的数量。

## 先把链路方向写对

Mihomo 可以通过节点的 `dialer-proxy` 指定它建立连接时使用的前置代理。下面这个结构表示，台湾出口通过日本前置建立连接，网站最终看到台湾出口的 IP。[Mihomo 官方说明](https://wiki.metacubex.one/config/proxies/dialer-proxy/)

```yaml
proxies:
  - name: 日本前置
    # 将日本节点的完整配置复制到这里

  - name: 台湾住宅出口
    # 将住宅节点的完整配置复制到这里
    dialer-proxy: 日本前置

rules:
  - MATCH,台湾住宅出口
```

实际使用时，需要复制订阅中的完整节点对象，保留其协议、服务器、端口、TLS、Reality、WebSocket 等字段，再调整名称和 `dialer-proxy`。

为了让 AdsPower 始终连接同一条链路，我给它安排了固定的本地入口 `127.0.0.1:17891`。这个入口使用 `mixed-port`，提供 HTTP 与 SOCKS5 两种接入方式。

## 节点自身延迟与整条链路的表现

第一轮测试先检测日本前置，然后用当时延迟最低的日本节点去连接 30 个 StepFly 家宽出口。结果差距很大。

- 多轮日本节点测试中，有 12 至 13 个节点通过。
- 一轮完整的 StepFly 家宽链式测试只有波兰出口通过。
- 同一轮 StepFly 家宽直连测试有 4 个出口通过。
- 再将 15 个日本前置与四个代表性出口组合测试，成功组合仍集中在波兰出口。

四个代表性出口分别采用香港 VLESS、台湾 AnyTLS、菲律宾 AnyTLS 和波兰 VLESS。还尝试过调整入口域名或固定入口 IP，观察到的成功出口仍是波兰。

选前置时，需要检测“日本前置连接指定出口”的完整路径。日本节点到某个测速网址的延迟，只覆盖了链路的一部分。

波兰出口后来完成了一次 1 MiB HTTPS 下载，端到端吞吐约为 0.94 Mbps。基础 IP 查询却把它标记为 `hosting=true`，ISP 名称中带有 `DataCenter VPS`。订阅里的“家宽”标签需要用实际出口属性继续核对。

### 最后选中了另一个订阅的台湾住宅节点

第三个订阅 Basic 里，台湾住宅 5 曾通过链式测试。最初配合日本 AWS02 时，它的表现波动明显。更换前置后，情况有所改善。

| 日本前置 | 台湾住宅 5 的三次测试 | 当时的观察 |
| --- | --- | --- |
| AWS02 | 失败、125 ms、失败 | 波动明显 |
| AWS05 | 125、122、123 ms | 三次均通过 |
| AWS06 | 135、122、139 ms | 三次均通过 |
| AWS09 | 132、119、129 ms | 三次均通过 |

最终选择了赔钱机场日本 AWS05 连接 Basic 台湾住宅 5。两个各为 1 MiB 的下载样本分别得到约 1.64 Mbps 和 3.35 Mbps。它们是短时端到端样本，覆盖建立连接和传输的开销，长期吞吐仍需要持续观察。

IP 查询显示台湾中华电信，基础数据库返回 `hosting=false`、`proxy=false`。几小时内，住宅出口 B 的实际地址发生过变化，因此后续验收记录运营商、地区和当时的地址。住宅属性、独享性、历史信誉与目标网站的访问表现，都需要各自的证据。

## 给 AdsPower 建一个固定入口

当时 FlClash 的主程序使用 `7890`，它承载日常系统代理，截图里显示系统出口 A。独立的 `17891` 承载日本 AWS05 到台湾住宅 5 的链式连接，对应住宅出口 B。

| 本地入口 | 用途 | 本次出口 |
| --- | --- | --- |
| `127.0.0.1:7890` | FlClash 主程序的系统代理 | 系统出口 A |
| `127.0.0.1:17891` | AdsPower 使用的固定链式入口 | 住宅出口 B |

两个入口同时存在，界面上就可能出现两个台湾 IP。核对出口时，必须连同端口一起记录。

专用配置的主体如下。下载模板后，用自己的订阅替换两个示例节点，保留实际协议需要的字段。

```yaml
mixed-port: 17891
allow-lan: false
bind-address: 127.0.0.1
mode: rule
log-level: warning
ipv6: false
tcp-concurrent: true
unified-delay: true

tun:
  enable: false

dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  respect-rules: true
  default-nameserver:
    - 223.5.5.5
    - 119.29.29.29
  proxy-server-nameserver:
    - https://dns.alidns.com/dns-query
    - https://doh.pub/dns-query
  nameserver:
    - https://1.1.1.1/dns-query#台湾住宅出口
    - https://8.8.8.8/dns-query#台湾住宅出口

proxies:
  # 在此填入完整的日本前置与台湾住宅节点

rules:
  - MATCH,台湾住宅出口
```

这次用一个隐藏运行的 PowerShell 辅助进程，启动已安装的 `FlClashCore.exe`，通过本地命名管道执行 `core.init`、`config.setup`、`listener.start`，并持续读取内核事件。内核退出时，辅助进程会尝试重启。

公开版本的脚本放在文末，可以检查代码后保存到本地使用。它依赖本次测试的 FlClashCore 接口，安装路径可以通过脚本参数调整。配置和凭据采用静态快照，订阅更新后需要同步维护。

## AdsPower 的第一次失败

环境创建页最初选择了 HTTPS，主机填写 `127.0.0.1`，端口填写 `17891`。测试失败后，又在网络诊断页把系统代理辅助功能调整为手动 SOCKS。

这两个设置分别对应环境代理和连接代理时使用的系统辅助代理。修改诊断页后，还需要检查环境创建页保存的代理类型。回读界面时，环境页一度仍显示 HTTPS。

将环境页改成 Socks5 后，失败继续出现。这时仅凭界面选择的协议，已经解释不了问题。

日志给出了更具体的错误。

```text
Protocol "http:" not supported. Expected "https:"
```

部分检测记录还显示固定的 5 秒超时。

```text
timeout of 5000ms exceeded
```

前一种错误在请求库处理协议时就发生，后一种错误表示请求在客户端的等待期限内没有完成。排查时分别记录了这两类结果。

## 用 ZeroOmega 做浏览器对照测试

按照 AdsPower 官方提供的本地浏览器排查方法，在 Chrome 中配置 ZeroOmega，再访问 IP 检测网站。这一步可以核对浏览器经指定端口访问网站时的实际出口。[官方测试教程](https://help.adspower.net/docs/3FYAHM)

ZeroOmega 的 `proxy` 情景填写如下。

| 字段 | 填写值 |
| --- | --- |
| Protocol | SOCKS5 |
| Server | `127.0.0.1` |
| Port | `17891` |
| 账号、密码 | 留空 |
| Proxy DNS requests via SOCKS proxy | 勾选 |

Bypass List 使用本地回环地址。

```text
127.0.0.1
::1
localhost
```

保存时先点击 `Apply changes`，再从扩展图标中启用 `proxy`。随后 BrowserScan 显示了住宅出口 B，运营商为中华电信，浏览器平台为 Windows 10。

这项结果验证了浏览器通过 `17891` 的可达性。BrowserScan 同时给出了语言和时区提示，这些项目应回到目标浏览器环境中继续核对。它显示的综合分数也有自己的判断规则。

## 清理代理环境变量后，为什么重开还会失败

AdsPower 的官方排查指引要求在 Windows 环境变量中检查 `HTTP_PROXY` 和 `HTTPS_PROXY`。这台电脑确实设置了它们，值都指向 `http://127.0.0.1:7890`。清理前先备份，再删除用户级设置。[官方指引](https://help.adspower.net/docs/Proxy-configuration-error)

排查请求库时，一度先检查了安装包里的 `node_modules/axios`。沿着运行时的加载路径继续追踪后，找到了 `cwd_global/lib/bundles.min.js` 中实际使用的实现，随后用诊断副本复现了错误。

对照测试使用同一个官方检测网址和代理 Agent，结果如下。

| 启动环境 | 测试结果 |
| --- | --- |
| 带有旧 `HTTPS_PROXY` | 复现 `ERR_INVALID_PROTOCOL` |
| 清理代理变量后 | 返回 HTTP 200 |

当时通过独立的诊断副本调用 IP 查询接口。

### uTools 又把旧变量传了回来

接下来读到了一项容易忽略的信息。运行中的 AdsPower 由 `uTools.exe` 启动，它的进程环境里仍然存在以下值。

```text
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
ALL_PROXY=http://127.0.0.1:7890
```

用户级变量已经清理，运行中的 uTools 仍保留着启动时的环境块。通过它重新打开 AdsPower，旧变量又进入了新进程。

Windows 默认让子进程继承父进程的环境变量。排查这种问题时，既要检查注册表里的用户变量，也要检查实际启动进程及其父进程。[Microsoft 进程环境变量说明](https://learn.microsoft.com/en-us/windows/win32/procthread/environment-variables)

实际检查只读取代理相关的变量名和值。整份进程环境可能包含其他凭据，诊断记录应限定字段。

### 用专用启动器清理这一次启动的环境

修复时先保存环境、完全退出 AdsPower，再通过专用脚本启动。脚本在创建 AdsPower 进程前，清理代理变量。

```powershell
$adsPowerPath = 'D:\AdsPower\AdsPower Global\AdsPower Global.exe'

foreach ($name in @(
    'HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'SOCKS_PROXY',
    'http_proxy', 'https_proxy', 'all_proxy', 'socks_proxy'
)) {
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}

Start-Process -FilePath $adsPowerPath
```

下载包里的启动器会先检查 AdsPower 是否仍在运行。存在运行进程时，它会提示先保存并退出。随后启动本地链式代理，再以清理后的环境打开 AdsPower。

电脑重启后，再用同一个启动器恢复本地代理入口和 AdsPower。

辅助代理脚本使用 PowerShell 7。它们执行进程启动和本地网络配置，通常可以使用普通用户权限。

## 再用 AdsPower 自带请求库比较 HTTP 与 SOCKS5

普通浏览器的测试通过以后，还需要尽量贴近 AdsPower 的请求方式。

这一轮使用当前安装版本实际加载的请求库和代理 Agent，访问三个官方 IP 检测接口，并采用客户端使用的 5 秒超时。表中的 IP 已用出口代称替换。

| 入口与协议 | check.myclientip.com | ip-scan.adspower.net | check.adspower.com | 出口 |
| --- | ---: | ---: | ---: | --- |
| `17891` SOCKS5 | 超时 | 超时 | 2648 ms | 住宅出口 B |
| `17891` HTTP | 2295 ms | 2410 ms | 2127 ms | 住宅出口 B |
| `7890` SOCKS5 | 761 ms | 835 ms | 564 ms | 系统出口 A |
| `7890` HTTP | 765 ms | 761 ms | 568 ms | 系统出口 A |

这组结果让我把环境页的接入方式调整为 HTTP。`17891` 是 mixed 入口，因此可以在同一条上游链路上更换本地接入协议。

HTTPS 网站可以通过 HTTP 代理的 CONNECT 隧道访问。配置中的代理类型描述的是浏览器连接代理入口的方式。这里选择 HTTP，并要求网站连接继续使用 HTTPS。[HTTP CONNECT 标准](https://www.rfc-editor.org/rfc/rfc9110.html#name-connect)

上述耗时来自当次诊断，协议表现会受到客户端实现、链路状态和连接建立开销影响。HTTP 在本次三个接口的测试中全部通过。

## 临时安全白名单这一轮查到了什么

还按排查思路检查过安全软件和防火墙。

当时联网使用的专用网络防火墙处于关闭状态，公共网络防火墙也已关闭。Windows Defender 实时防护开启，最近八小时未找到与 AdsPower、FlClash 相关的拦截事件。

随后给 AdsPower 和 FlClashCore 添加了三分钟的临时进程白名单，并为 `127.0.0.1:17891` 添加回环防火墙放行规则。测试期间，系统代理检测仍有 5 秒超时，未观察到改善。新增项目在测试结束后全部撤销，撤销记录无错误。

公开脚本仅包含普通启动流程。安全软件白名单测试需要管理员权限，执行前应记录已有设置，测试结束后撤销本次新增项目。

## 环境代理与系统代理辅助功能怎么填

本次专用链式入口的环境页配置如下。

| 环境代理项目 | 填写值 |
| --- | --- |
| 代理方式 | 自定义 |
| 代理类型 | HTTP |
| 主机 | `127.0.0.1` |
| 端口 | `17891` |
| 账号、密码、刷新 URL | 留空 |
| IP 查询渠道 | ip-api |

这里的日本前置已经由本地内核处理。采用这个方案时，可以关闭“使用系统代理连接代理”，点击“保存设置”，再从环境页检查 `17891`。

FlClash 主程序的系统代理端口则为 `7890`。如果要单独核对 AdsPower 的系统代理辅助功能，可以先确认该端口的实际检测结果，再选择自动检测，或在手动 HTTP 模式中填写 `127.0.0.1` 和 `7890`。修改这项功能后，也要保存设置。

AdsPower 官方排查文章提到，本地网络已经显示海外出口、系统代理检测为空时，可以继续核对代理配置和代理有效性。本次 ZeroOmega 的成功结果，正是后续定位客户端处理差异的依据。[AdsPower 排查文章](https://zhuanlan.zhihu.com/p/2030003130021193726)

### Windows 环境里的其他项目

这次选择 SunBrowser 和 Windows。时区、地理位置与语言按出口 IP 匹配，地理位置权限使用每次询问，分辨率采用预定义的 User-Agent 匹配方式。

WebRTC 需要结合业务需求和代理的 UDP 支持设置。本文验证了 TCP、HTTP、HTTPS 请求，UDP 专项测试仍待完成。视频会议等功能应在对应业务页面单独验收。[AdsPower 指纹参数说明](https://help.adspower.com/docs/browser_fingerprint)

## 最后成功时，界面显示了什么

最后的网络诊断截图已经能显示系统代理信息。

| 检测项 | 最终截图的记录 |
| --- | --- |
| 网络状态 | 正常 |
| 本地网络 | 中国大陆 IPv6，地址已脱敏 |
| 本地检测耗时 | 86 ms |
| 系统代理 | 系统出口 A，台湾台北 |
| 系统代理检测耗时 | 587 ms |
| 系统代理连接功能 | 开启，自动检测模式 |

这张截图验证了系统代理检测恢复。前面的 ZeroOmega 和请求库测试验证了专用住宅链路。打开具体 AdsPower 环境后，还需要在那个浏览器窗口中核对出口 B。

本地 IPv6 和系统代理出口可以在诊断面板中同时出现。示例 YAML 中的 `ipv6: false` 配置作用于代理内核，Windows 网络接口的 IPv6 状态需要单独核查。

回看整次排查，最耗时间的是启动路径。用户变量清理以后，我几次把“重新打开程序”当成已经读取新环境，直到实际检查 AdsPower 的父进程和环境块，才找到 uTools 传入的旧值。以后遇到代理参数已经填写正确、客户端仍报协议错误的情况，我会更早检查这一项。

## 配置模板与启动脚本

以下文件均为可公开的模板。下载到同一个目录后，将 `config.template.yaml` 另存为 `config.yaml`，填入自己的完整节点字段，再运行启动脚本。

- [config.template.yaml](/downloads/adspower-chain/config.template.yaml)
- [serve.ps1](/downloads/adspower-chain/serve.ps1)
- [start-chain.ps1](/downloads/adspower-chain/start-chain.ps1)
- [start-adspower.ps1](/downloads/adspower-chain/start-adspower.ps1)
- [Start-AdsPower.cmd](/downloads/adspower-chain/Start-AdsPower.cmd)

`serve.ps1` 默认读取 `D:\FlClash\FlClashCore.exe`，`start-adspower.ps1` 默认读取 `D:\AdsPower\AdsPower Global\AdsPower Global.exe`。安装位置不同，可以修改对应默认路径或通过参数指定。配置模板中的 `REPLACE_` 字段需要填写后再启动。

这些脚本配合本文记录的版本验证过启动结构。FlClashCore 的本地接口和 AdsPower 的代理实现可能随版本更新，迁移时应重新检查日志、监听端口和实际浏览器出口。
