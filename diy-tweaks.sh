#!/bin/bash
#=============================================================
# diy-tweaks.sh — OpenWrt 6.18 个人偏好四项固化脚本
#
# 每轮重编都要手工重做的四项偏好，一次收进这个脚本：
#   1. 菜单顺序（autotimeset、iStore 两个控制器里的 order 修正）
#   2. 剔除「系统 > 插件」入口
#   3. ipkg.lua 空壳模块
#   4. 中文语言包（CONFIG_LUCI_LANG_zh_Hans=y）
#
# 四项的命令逐字沿用 kingfree66/Openwrt-6.18 仓库里已验证的原文
# （diy-618-1.sh / diy-618-2.sh / 6.18.config /
#   files/usr/lib/lua/luci/model/ipkg.lua），本脚本只做打包和
# 分阶段调度，不改动任何一条已验证命令。全部可重复执行：
# sed 命中后模式不再匹配、rm 带 -f、config 行有 grep 防重复。
#
# 用法（接进现有 diy 流程，各加一句话）：
#   diy-618-1.sh 里 clone 完 diy-ziyong 与 istore 之后：
#       bash diy-tweaks.sh part1
#   diy-618-2.sh 里（feeds 安装之后）：
#       bash diy-tweaks.sh part2
#   第 3、4 项作用于构建仓库本身，在仓库根目录跑一次：
#       bash diy-tweaks.sh repo
#   不带参数（all）：三段依次执行，目标文件不在的项自动跳过，
#   在仓库根目录或源码根目录跑都安全。
#=============================================================

set -e

# ---------- 1. 菜单顺序 ----------
# 来源：diy-618-1.sh，2026-10-20 本地第五轮构建验证，用户截图确认
# 顺序为 状态→系统→服务→iStore→VPN→网络→退出，同日推送 GitHub。
# 原理：菜单 JSON 只定大顺序，autotimeset 的控制器把「系统」顶层
# order 写成 44、iStore 的控制器把自己写成 31，会盖过 JSON，
# 必须在源码里把这两个数改掉。
tweak_menu_order() {
    if [ -f package/diy-ziyong/package/luci-app-autotimeset/luasrc/controller/autotimeset.lua ]; then
        sed -i 's/"System", 44/"System", 20/' package/diy-ziyong/package/luci-app-autotimeset/luasrc/controller/autotimeset.lua
    fi
    if [ -f package/istore/luci/luci-app-store/luasrc/controller/store.lua ]; then
        sed -i 's/_("iStore"), 31/_("iStore"), 40/' package/istore/luci/luci-app-store/luasrc/controller/store.lua
    fi
}

# ---------- 2. 剔除「系统 > 插件」入口 ----------
# 来源：diy-618-2.sh，2026-10-21 本地第六轮构建验证，
# 同日随 commit 2580ad97 推送 GitHub。
# 「插件」是 luci-mod-system 的 admin/system/plugins。删 JSON 菜单项
# 的结束符只认一层缩进 /^\t},/，写宽了会先命中 action 子块的
# 闭合行、删半截毁掉整个 JSON（已模拟验证）。
tweak_remove_plugins() {
    if [ -f ./feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json ]; then
        sed -i '/"admin\/system\/plugins": {/,/^\t},/d' ./feeds/luci/modules/luci-mod-system/root/usr/share/luci/menu.d/luci-mod-system.json
    fi
    rm -f ./feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/plugins.js
}

# ---------- 3. ipkg.lua 空壳模块 ----------
# 来源：仓库 files/usr/lib/lua/luci/model/ipkg.lua（541 字节），
# 2026-10-21 随 commit 2580ad97 推送 GitHub。
# 上游 opkg→apk 迁移后删掉了 luci.model.ipkg，但 autotimeset 的
# base.lua 还在 require 它（模板残留行，无实际调用），缺了它页面
# 加载不了；放一个空壳模块把 require 顶住。下面 heredoc 内容与
# 仓库原件逐字节一致。
tweak_ipkg_stub() {
    mkdir -p files/usr/lib/lua/luci/model
    cat > files/usr/lib/lua/luci/model/ipkg.lua <<'IPKG_STUB_EOF'
-- luci.model.ipkg was removed upstream after the opkg -> apk migration,
-- but luci-app-autotimeset's model/cbi/autotimeset/base.lua still does
-- require "luci.model.ipkg" (leftover template line, no actual calls).
-- This empty stub keeps that require working so the page loads.
module("luci.model.ipkg", package.seeall)

function installed(pkg)
	return false
end

function status(pkg)
	return {}
end

function versions(pkg)
	return {}
end

function info(pkg)
	return {}
end

function compare_versions(ver1, comp, ver2)
	return false
end
IPKG_STUB_EOF
}

# ---------- 4. 中文语言包 ----------
# 来源：6.18.config 第 67 行，commit bef1c448；
# 2026-10-19 构建（release 202610191106）验证：16 个 luci-i18n
# 中文包全在。
# 技巧：不要直接选 luci-i18n-* 包名——那是无 prompt 的 HIDDEN 包，
# 写进 config 会被 make defconfig 静默丢弃；选 luci-base 翻译菜单
# 的 LUCI_LANG_zh_Hans，各模块翻译包靠 DEFAULT:=LUCI_LANG_zh_Hans
# 自动带入。
tweak_zh_hans() {
    if [ -f 6.18.config ] && ! grep -q '^CONFIG_LUCI_LANG_zh_Hans=y$' 6.18.config; then
        echo 'CONFIG_LUCI_LANG_zh_Hans=y' >> 6.18.config
    fi
}

case "${1:-all}" in
    part1) tweak_menu_order ;;
    part2) tweak_remove_plugins ;;
    repo)  tweak_ipkg_stub; tweak_zh_hans ;;
    all)   tweak_ipkg_stub; tweak_zh_hans; tweak_menu_order; tweak_remove_plugins ;;
    *) echo "用法: bash diy-tweaks.sh [part1|part2|repo|all]" >&2; exit 1 ;;
esac

echo "diy-tweaks done (${1:-all})"
