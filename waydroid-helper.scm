;;; waydroid-helper.scm — waydroid-helper 的 Guix 打包脚本
;;;
;;; 用法（在仓库根目录）:
;;;   guix build -f waydroid-helper.scm                     构建主包
;;;   guix shell -f waydroid-helper.scm -- waydroid-helper  试运行
;;;   guix install -f waydroid-helper.scm                   装进用户 profile
;;;
;;; Guix 适配要点:
;;; - waydroid-helper.in 的 #!@PYTHON@ 由 meson 替换为构建用 python 的
;;;   store 绝对路径，天然满足 Guix 对解释器路径的要求。
;;; - data/scripts/ 与 waydroid-cli 的 shebang 已改为 #!/usr/bin/env bash，
;;;   bin 下两个入口都以 wrap-program 补 PATH，保证 env 能找到 bash。
;;; - Guix 无 systemd: 传空 -Dsystemd-* / -Ddbus-* 不装服务文件。
;;; - python-pywayland 上游 Guix 还没有，定义在本文件顶部（与 jeans channel
;;;   的 modules/jeans/packages/python-xyz.scm 里那份保持一致）。
;;; - waydroid 本体不是依赖: PATH 用 prefix 语义保留会话 PATH，
;;;   用户 profile 里的 waydroid（如 jeans channel 的包）照常可见。
;;; - wrapper 的 PATH / GI_TYPELIB_PATH / PYTHONPATH 一律用 gexp 直接展开
;;;   包引用，不走 label 查表: 查表法在 label 与包名漂移（例如查 "bash"
;;;   而输入给的是 bash-minimal）时会静默丢掉整条路径。

(use-modules (gnu packages)
             (gnu packages base)
             (gnu packages bash)
             (gnu packages check)
             (gnu packages freedesktop)
             (gnu packages gettext)
             (gnu packages gnome)
             (gnu packages glib)
             (gnu packages gtk)
             (gnu packages libffi)
             (gnu packages linux)
             (gnu packages pciutils)
             (gnu packages pkg-config)
             (gnu packages python)
             (gnu packages python-build)
             (gnu packages python-web)
             (gnu packages python-xyz)
             (guix build-system meson)
             (guix build-system pyproject)
             (guix download)
             (guix gexp)
             ((guix licenses) #:prefix license:)
             (guix packages)
             (guix utils))

;; Python bindings for the Wayland protocol — Guix 上游尚无此包。
;; cffi 在运行时 dlopen libwayland-client，故 wayland 进 inputs。
(define-public python-pywayland
  (package
    (name "python-pywayland")
    (version "0.4.19")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pywayland" version))
       (sha256
        (base32
         "17jlk1c8bylzvq2mhs4cqar50hdkx1gsb1fg7hrl0dfzn3spi14x"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))     ; 测试需要真实 Wayland 会话
    (propagated-inputs (list python-cffi))
    (inputs (list wayland))            ; cffi 运行时 dlopen libwayland-client
    (native-inputs (list pkg-config wayland-protocols python-setuptools)) ; scanner 用 pkg-config 定位协议 XML
    (synopsis "Python bindings for the Wayland protocol")
    (description "Python bindings for the Wayland protocol.  Core protocol
bindings are generated at build time with cffi from the protocol XML shipped
in the sdist.")
    (home-page "https://github.com/flacjacket/pywayland")
    (license license:expat)))

(define-public waydroid-helper
  (package
    (name "waydroid-helper")
    (version "0.2.9")
    (source
     (local-file (dirname (current-filename)) "waydroid-helper-src"
                 #:recursive? #t
                 #:select? (lambda (path stat)
                             (not (or (string-contains path "/.git/")
                                      (string-contains path "/build/")
                                      (string-contains path "/__pycache__/")
                                      (string-contains path ".pytest_cache")
                                      (string-suffix? ".scm" path))))))
    (build-system meson-build-system)
    (arguments
     (list
      ;; Guix 无 systemd / dbus-1 的 pc 文件: 显式传空关闭服务文件安装
      #:configure-flags #~(list "-Dsystemd-system-unit-dir="
                                "-Dsystemd-user-unit-dir="
                                "-Ddbus-service-dir="
                                "-Ddbus-policy-dir=")
      ;; Guix 构建容器无图形栈，pytest 用例要 import Gtk typelib，
      ;; 且 meson test 会重置环境变量导致 GI_TYPELIB_PATH 失效，
      ;; 故构建侧跳过测试；测试用 guix shell + pytest 在源码树单独跑
      #:tests? #f
      #:phases
      #~(let ((py-site
              (string-append "/lib/python"
                             #$(version-major+minor (package-version python))
                             "/site-packages")))
          (modify-phases %standard-phases
            (add-after 'install 'wrap-program-paths
              (lambda* (#:key outputs #:allow-other-keys)
                (let* ((out (assoc-ref outputs "out"))
                       ;; 路径一律由 gexp 直接展开包引用，不走 label 查表：
                       ;; 查表法在 label 与包名不一致时会静默丢掉整条路径
                       (path-dirs
                        (append
                         (list (string-append out "/bin"))
                         (map (lambda (pkg) (string-append pkg "/bin"))
                              (list #$bash-minimal
                                    #$coreutils
                                    #$grep
                                    #$sed
                                    #$tar
                                    #$pciutils
                                    #$fakeroot))))
                       ;; 运行时需要 typelib 的库（typelib 都在各包的 out output，
                       ;; 与下面 inputs 里的 gtk "out" 对应）
                       (gi-dirs
                        (map (lambda (pkg)
                               (string-append pkg "/lib/girepository-1.0"))
                             (list #$gtk
                                   #$libadwaita
                                   #$vte
                                   #$graphene
                                   #$gdk-pixbuf
                                   #$gobject-introspection
                                   #$pango
                                   #$harfbuzz
                                   #$cairo
                                   #$glib)))
                       ;; 运行时需要 import 的 python 库
                       (py-dirs
                        (map (lambda (pkg) (string-append pkg py-site))
                             (list #$python-pygobject
                                   #$python-pycairo
                                   #$python-pywayland
                                   #$python-dbus
                                   #$python-aiofiles
                                   #$python-httpx
                                   #$python-pyyaml))))
                  ;; GUI 主程序: 完整环境
                  (wrap-program (string-append out "/bin/waydroid-helper")
                    `("PATH" ":" prefix ,path-dirs)
                    `("GI_TYPELIB_PATH" ":" prefix ,gi-dirs)
                    `("PYTHONPATH" ":" prefix ,py-dirs)
                    `("GSETTINGS_SCHEMA_DIR" ":" prefix
                      (,(string-append out "/share/glib-2.0/schemas")))
                    `("XDG_DATA_DIRS" ":" prefix
                      (,(string-append out "/share"))))
                  ;; 特权 CLI: 只补 PATH（pkexec 环境下路径极简）
                  (wrap-program (string-append out "/bin/waydroid-cli")
                    `("PATH" ":" prefix ,path-dirs)))))))))
    (native-inputs
     `(("gettext-minimal" ,gettext-minimal)
       ("python-wrapper" ,python-wrapper)
       ("desktop-file-utils" ,desktop-file-utils)
       ("glib" ,glib)                   ; gio-2.0.pc (gnome.post_install 需要)
       ("glib:bin" ,glib "bin")         ; glib-compile-schemas
       ("gtk:bin" ,gtk "bin")))         ; gtk4-update-icon-cache（标签避开 inputs 的 gtk）
    (inputs
     (list bash-minimal
           coreutils
           grep
           sed
           tar
           pciutils
           fakeroot
           `(,gtk "out")                   ; typelib 在 out output（bin 里没有）
           libadwaita
           vte
           graphene
           gdk-pixbuf
           gobject-introspection
           glib
           pango
           harfbuzz
           cairo
           python-pygobject
           python-pycairo
           python-pywayland
           python-dbus
           python-aiofiles
           python-httpx
           python-pyyaml))
    (home-page "https://github.com/Jaoushingan/waydroid-helper")
    (synopsis "Helps you install Waydroid, configure key mapping, and install extensions")
    (description "Waydroid Helper is a GUI application written in GTK4 and
libadwaita for configuring Waydroid, managing key mappings and installing
extensions.  It ships a main GUI process, a separate key-mapper overlay
process, and a privileged helper CLI (waydroid-cli) invoked through pkexec.")
    (license license:gpl3)))

waydroid-helper
