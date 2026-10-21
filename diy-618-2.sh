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

# 修复 tar-1.35 与 libacl 2.4.0 的符号冲突（上游 openwrt/packages PR #30837 同款补丁）
# libacl 2.4.0 在 sys/acl.h 新增 acl_get_file_at 等 at 变体声明，与 tar 内部同名
# 静态函数（src/xattrs.c）冲突，编译 tar 时报错；补丁把 tar 内部函数改名 tar_acl_*
mkdir -p ./feeds/packages/utils/tar/patches
cat > ./feeds/packages/utils/tar/patches/101-rename-acl-at-functions.patch <<'TAR_ACL_PATCH'
From abd4560c18f26296c666597ae9e8a4a44031ae5f Mon Sep 17 00:00:00 2001
From: Pavel Cahyna <pcahyna@redhat.com>
Date: Wed, 24 Jun 2026 18:45:30 +0200
Subject: [PATCH] Avoid acl_ prefix for functions

The acl.h header from libacl uses acl_ prefix for its functions. Avoid
defining functions with the same name in order to protect its namespace.

(cherry picked from commit 08c3fc2e9337094aff01a511170fd35fdb8f1ee3,
adjusted to the tar 1.35 call sites)
Signed-off-by: Daniel Golle <daniel@makrotopia.org>
---
 src/xattrs.c | 30 +++++++++++++++---------------
 1 file changed, 15 insertions(+), 15 deletions(-)

--- a/src/xattrs.c
+++ b/src/xattrs.c
@@ -139,13 +139,13 @@ static struct
 #ifdef HAVE_POSIX_ACLS
 
 /* acl-at wrappers, TODO: move to gnulib in future? */
-static acl_t acl_get_file_at (int, const char *, acl_type_t);
-static int acl_set_file_at (int, const char *, acl_type_t, acl_t);
+static acl_t tar_acl_get_file_at (int, const char *, acl_type_t);
+static int tar_acl_set_file_at (int, const char *, acl_type_t, acl_t);
 static int file_has_acl_at (int, char const *, struct stat const *);
-static int acl_delete_def_file_at (int, char const *);
+static int tar_acl_delete_def_file_at (int, char const *);
 
-/* acl_get_file_at */
-#define AT_FUNC_NAME acl_get_file_at
+/* tar_acl_get_file_at */
+#define AT_FUNC_NAME tar_acl_get_file_at
 #define AT_FUNC_RESULT acl_t
 #define AT_FUNC_FAIL (acl_t)NULL
 #define AT_FUNC_F1 acl_get_file
@@ -159,8 +159,8 @@ static int acl_delete_def_file_at (int,
 #undef AT_FUNC_POST_FILE_PARAM_DECLS
 #undef AT_FUNC_POST_FILE_ARGS
 
-/* acl_set_file_at */
-#define AT_FUNC_NAME acl_set_file_at
+/* tar_acl_set_file_at */
+#define AT_FUNC_NAME tar_acl_set_file_at
 #define AT_FUNC_F1 acl_set_file
 #define AT_FUNC_POST_FILE_PARAM_DECLS   , acl_type_t type, acl_t acl
 #define AT_FUNC_POST_FILE_ARGS          , type, acl
@@ -170,8 +170,8 @@ static int acl_delete_def_file_at (int,
 #undef AT_FUNC_POST_FILE_PARAM_DECLS
 #undef AT_FUNC_POST_FILE_ARGS
 
-/* acl_delete_def_file_at */
-#define AT_FUNC_NAME acl_delete_def_file_at
+/* tar_acl_delete_def_file_at */
+#define AT_FUNC_NAME tar_acl_delete_def_file_at
 #define AT_FUNC_F1 acl_delete_def_file
 #define AT_FUNC_POST_FILE_PARAM_DECLS
 #define AT_FUNC_POST_FILE_ARGS
@@ -299,10 +299,10 @@ xattrs__acls_set (struct tar_stat_info c
       /* No "default" IEEE 1003.1e ACL set for directory.  At this moment,
          FILE_NAME may already have inherited default acls from parent
          directory;  clean them up. */
-      if (acl_delete_def_file_at (chdir_fd, file_name))
+      if (tar_acl_delete_def_file_at (chdir_fd, file_name))
         WARNOPT (WARN_XATTR_WRITE,
                 (0, errno,
-                 _("acl_delete_def_file_at: Cannot drop default POSIX ACLs "
+                 _("tar_acl_delete_def_file_at: Cannot drop default POSIX ACLs "
                    "for file '%s'"),
                  file_name));
       return;
@@ -316,11 +316,11 @@ xattrs__acls_set (struct tar_stat_info c
       return;
     }
 
-  if (acl_set_file_at (chdir_fd, file_name, type, acl) == -1)
+  if (tar_acl_set_file_at (chdir_fd, file_name, type, acl) == -1)
     /* warn even if filesystem does not support acls */
     WARNOPT (WARN_XATTR_WRITE,
 	     (0, errno,
-	      _ ("acl_set_file_at: Cannot set POSIX ACLs for file '%s'"),
+	      _ ("tar_acl_set_file_at: Cannot set POSIX ACLs for file '%s'"),
 	      file_name));
 
   acl_free (acl);
@@ -357,10 +357,10 @@ acls_get_text (int parentfd, const char
   char *val = NULL;
   acl_t acl;
 
-  if (!(acl = acl_get_file_at (parentfd, file_name, type)))
+  if (!(acl = tar_acl_get_file_at (parentfd, file_name, type)))
     {
       if (errno != ENOTSUP)
-        call_arg_warn ("acl_get_file_at", file_name);
+        call_arg_warn ("tar_acl_get_file_at", file_name);
       return;
     }
 
TAR_ACL_PATCH

echo "DIY part 2 done"
