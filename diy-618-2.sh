#!/bin/bash
#=============================================================
# openwrt-6.18 DIY part 2
# 在官方 OpenWrt 源码根目录执行，feeds 更新并安装之后
#=============================================================

set -e

# 去掉与第三方源冲突的官方 feed 包（用我们 clone 的版本）
rm -rf ./feeds/packages/net/mosdns
rm -rf ./feeds/packages/net/v2ray-geodata
rm -rf ./feeds/luci/applications/luci-app-mosdns

# diy-ziyong 里不需要的组件（smartdns 未选用）
rm -rf ./package/diy-ziyong/smartdns

# 默认主题 argon 由 files/etc/uci-defaults/99-custom-settings 在首次开机时设置
# （luci-theme-bootstrap 自带 30_luci-theme-bootstrap 会把默认主题设回 bootstrap，
#  99-custom-settings 执行顺序靠后，会覆盖它）
# uci-defaults 脚本必须可执行（经 GitHub API 推送的文件默认无执行位，这里补上）
chmod +x ./files/etc/uci-defaults/99-custom-settings

# 去掉 luci-light 对 luci-theme-bootstrap 的硬依赖（我们不用 bootstrap/material 主题）
sed -i '/+luci-theme-bootstrap/d' ./feeds/luci/collections/luci-light/Makefile

# 去掉"系统"菜单下的"插件"入口（luci-mod-system 的 admin/system/plugins）
# 结束符只认一层缩进 /^\t},/，写宽了会先命中 action 子块闭合行、删半截毁掉整个 JSON
sed -i '/"admin\/system\/plugins": {/,/^\t},/d' ./feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json
rm -f ./feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/plugins.js

echo "DIY part 2 done"
