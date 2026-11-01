#!/bin/bash
#=============================================================
# openwrt-6.18 DIY part 1
# 在官方 OpenWrt 源码根目录执行，feeds 更新之前
# 官方 main 分支 x86_64 默认内核即 6.18，无需指定 KERNEL_PATCHVER
#=============================================================

set -e

# 修改默认 LAN IP
sed -i 's/192.168.1.1/192.168.2.106/g' package/base-files/files/bin/config_generate
# 修改默认主机名
sed -i "s/hostname='OpenWrt'/hostname='OpenWrt-King'/g" ./package/base-files/files/bin/config_generate

# ---------- 第三方软件源 ----------
rm -rf package/ssr
git clone --depth 1 https://github.com/fw876/helloworld.git package/ssr
rm -rf package/openwrt-passwall
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/openwrt-passwall
rm -rf package/passwall
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/passwall
rm -rf package/passwall2
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall2.git package/passwall2

# 主题（argon / kucat 为 config 中启用的）
rm -rf package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
rm -rf package/luci-theme-kucat
git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat.git package/luci-theme-kucat
rm -rf package/luci-theme-liquid
git clone --depth 1 https://github.com/zzsj0928/luci-theme-liquid.git package/luci-theme-liquid
rm -rf package/luci-theme-glass
git clone --depth 1 https://github.com/rchen14b/luci-theme-glass.git package/luci-theme-glass

# mosdns（sbwml v5 分支）+ v2ray-geodata
find ./package -maxdepth 2 | grep Makefile | grep mosdns | xargs rm -f || true
rm -rf package/mosdns
git clone --depth 1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
find ./package -maxdepth 2 | grep Makefile | grep v2ray-geodata | xargs rm -f || true
rm -rf package/v2ray-geodata
git clone --depth 1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# diy-ziyong（提供 luci-app-adguardhome / luci-app-autotimeset）
rm -rf package/diy-ziyong
git clone --depth 1 https://github.com/firker/diy-ziyong.git package/diy-ziyong
# 修正 autotimeset 把 admin/system 顶层 order 顶成 44 的问题（菜单顺序）
sed -i 's/"System", 44/"System", 20/' package/diy-ziyong/package/luci-app-autotimeset/luasrc/controller/autotimeset.lua

# 零散 luci 应用
rm -rf package/luci-app-filetransfer
git clone --depth 1 https://github.com/DustReliant/luci-app-filetransfer.git package/luci-app-filetransfer
rm -rf package/istore
git clone --depth 1 https://github.com/linkease/istore.git package/istore
# 修正 istore 把 admin/store order 设为 31 的问题（菜单顺序，要排在服务之后）
sed -i 's/_("iStore"), 31/_("iStore"), 40/' package/istore/luci/luci-app-store/luasrc/controller/store.lua

# OpenClash
rm -rf /tmp/OpenClash
git clone --depth 1 --single-branch https://github.com/vernesong/OpenClash.git /tmp/OpenClash
rm -rf package/luci-app-openclash
mv /tmp/OpenClash/luci-app-openclash package/luci-app-openclash
rm -rf /tmp/OpenClash

# Nikki（mihomo 透明代理）：mihomo-meta 提供 mihomo 依赖，避免与 ssr-plus 的 mihomo 包冲突
rm -rf package/nikki
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/nikki
sed -i 's/+mihomo$/+mihomo-meta/' package/nikki/nikki/Makefile
grep -q '+mihomo-meta' package/nikki/nikki/Makefile || { echo "ERROR: nikki 依赖修补失败"; exit 1; }

# Honk（eBPF 透明代理）：内核要求 6.12+ 且开 BTF，6.18 满足；其 Makefile 下载预编译核心，
# 在本树编译时 kmod 依赖按本树内核生成（不用它的一键安装脚本，那个只认 25.12 的预编译包）
rm -rf package/honk
git clone --depth 1 https://github.com/kenzok8/openwrt-honk.git package/honk

# luci-app-zerotier：官方 luci 源中没有，从 coolsnowwolf/luci 取（sparse checkout）
rm -rf /tmp/luci-zt
git clone --depth 1 --branch openwrt-24.10 --sparse https://github.com/coolsnowwolf/luci.git /tmp/luci-zt
git -C /tmp/luci-zt sparse-checkout set applications/luci-app-zerotier
rm -rf package/luci-app-zerotier
cp -r /tmp/luci-zt/applications/luci-app-zerotier package/luci-app-zerotier
rm -rf /tmp/luci-zt
sed -i 's#include ../../luci.mk#include $(TOPDIR)/feeds/luci/luci.mk#' package/luci-app-zerotier/Makefile
[ -f package/luci-app-zerotier/Makefile ] || { echo "ERROR: luci-app-zerotier 拉取失败"; exit 1; }

# ---------- Turbo ACC（chenmozhijin 官方一键脚本，支持 6.18，带 SFE）----------
# 会下载 luci-app-turboacc / nft-fullcone / shortcut-fe，替换 firewall4、libnftnl、nftables，
# 并打上 952 / 953 / 613 内核补丁
rm -rf package/turboacc
curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o /tmp/add_turboacc.sh
bash /tmp/add_turboacc.sh
[ -d package/turboacc/luci-app-turboacc ] || { echo "ERROR: turboacc 集成失败"; exit 1; }
[ -d package/turboacc/shortcut-fe ] || { echo "ERROR: shortcut-fe 缺失"; exit 1; }

# ---------- 953 补丁适配 6.18.60 ----------
# 上游在 6.18.60 给 struct sk_buff 加了 tc_depth 字段，turboacc 自带的原版 953
# 补丁 skbuff.h 那处 hunk 打不上（上游 2026-07 后停更，只能本地修）。
# 内核小版本 >= 60 时用仓库里的修复版覆盖（只动了 skbuff.h 一个 hunk 的上下文），
# 低版本内核沿用 turboacc 原版.
KMINOR=$(sed -n 's/^LINUX_VERSION-6.18 = \.\([0-9]\+\)/\1/p' target/linux/generic/kernel-6.18)
if [ "${KMINOR:-0}" -ge 60 ] && [ -f "$GITHUB_WORKSPACE/953-fixed-6.18.60.patch" ]; then
  cp -f "$GITHUB_WORKSPACE/953-fixed-6.18.60.patch" target/linux/generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
  echo "953 补丁已替换为 6.18.60 适配版"
fi

echo "DIY part 1 done"
