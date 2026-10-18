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
git clone --depth 1 https://github.com/fw876/helloworld.git package/ssr
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/openwrt-passwall
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall.git package/passwall
git clone --depth 1 https://github.com/Openwrt-Passwall/openwrt-passwall2.git package/passwall2

# 主题（argon / kucat 为 config 中启用的）
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat.git package/luci-theme-kucat

# mosdns（sbwml v5 分支）+ v2ray-geodata
find ./package -maxdepth 2 | grep Makefile | grep mosdns | xargs rm -f || true
git clone --depth 1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
find ./package -maxdepth 2 | grep Makefile | grep v2ray-geodata | xargs rm -f || true
git clone --depth 1 https://github.com/sbwml/v2ray-geodata package/v2ray-geodata

# diy-ziyong（提供 luci-app-adguardhome / luci-app-autotimeset）
git clone --depth 1 https://github.com/firker/diy-ziyong.git package/diy-ziyong

# 零散 luci 应用
git clone --depth 1 https://github.com/DustReliant/luci-app-filetransfer.git package/luci-app-filetransfer
git clone --depth 1 https://github.com/linkease/istore.git package/istore
git clone --depth 1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# OpenClash
git clone --depth 1 --single-branch https://github.com/vernesong/OpenClash.git /tmp/OpenClash
mv /tmp/OpenClash/luci-app-openclash package/luci-app-openclash
rm -rf /tmp/OpenClash

# Nikki（mihomo 透明代理）：mihomo-meta 提供 mihomo 依赖，避免与 ssr-plus 的 mihomo 包冲突
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/nikki
sed -i 's/+mihomo$/+mihomo-meta/' package/nikki/nikki/Makefile
grep -q '+mihomo-meta' package/nikki/nikki/Makefile || { echo "ERROR: nikki 依赖修补失败"; exit 1; }

# luci-app-zerotier：官方 luci 源中没有，从 coolsnowwolf/luci 取（sparse checkout）
rm -rf /tmp/luci-zt
git clone --depth 1 --branch openwrt-24.10 --sparse https://github.com/coolsnowwolf/luci.git /tmp/luci-zt
git -C /tmp/luci-zt sparse-checkout set applications/luci-app-zerotier
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

echo "DIY part 1 done"
