# openwrt-6.18

官方 OpenWrt 源码（main 分支）编译的 x86_64 固件，内核 6.18。

插件与设置对标 `kingfree66/openwrt` 的 OpenWrt-lede6.6（LEDE 6.6）：passwall / passwall2 / ssr-plus / openclash / nikki(mihomo-meta) / mosdns(sbwml v5) / adguardhome / zerotier / turboacc(SFE_CM) / istore / openappfilter / ttyd / wol / upnp / vlmcsd / filetransfer / autotimeset / docker 等；默认 LAN 192.168.2.106，主机名 OpenWrt-King，argon 为默认主题。

与 LEDE 版的主要区别：
- 源码为官方 openwrt/openwrt main，内核 6.18（官方默认，无需指定）
- Turbo ACC 通过 chenmozhijin 官方一键脚本集成（含 6.18 内核补丁 952/953/613、shortcut-fe、nft-fullcone）
- 默认主题通过 `files/etc/uci-defaults/99-custom-settings` 在首次开机设置（官方无 LEDE 的 default-settings 包）
- ssr-plus 的 Mihomo 选项默认关闭，避免与 mihomo-meta 文件冲突（与 LEDE 版同）
- luci-app-adbyby-plus 暂无可靠的官方源，`make defconfig` 会静默跳过，不影响编译
