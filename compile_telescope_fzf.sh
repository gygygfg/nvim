#!/bin/bash

# telescope-fzf-native.nvim 编译脚本
# 放在 Neovim 配置目录中，方便手动调用

set -e

echo "========================================="
echo "  telescope-fzf-native.nvim 编译脚本"
echo "========================================="
echo ""

# 获取插件目录
PLUGIN_DIR="$HOME/.local/share/nvim/lazy/telescope-fzf-native.nvim"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "错误: 插件目录不存在: $PLUGIN_DIR"
    echo "请先安装 telescope-fzf-native.nvim 插件"
    exit 1
fi

cd "$PLUGIN_DIR"

# 检测架构
ARCH=$(uname -m)
echo "检测到架构: $ARCH"

# 设置编译标志
CFLAGS="-Wall -fpic -std=gnu99"

# 根据架构调整编译选项
case "$ARCH" in
    aarch64|arm64)
        echo "检测到 ARM64 架构"
        CFLAGS="$CFLAGS -march=armv8-a"
        ;;
    armv7l|armv8l)
        echo "检测到 ARMv7 架构"
        CFLAGS="$CFLAGS -march=armv7-a -mfloat-abi=softfp -mfpu=neon"
        ;;
    x86_64|amd64)
        echo "检测到 x86_64 架构"
        ;;
    *)
        echo "警告: 未知架构 $ARCH，使用通用编译选项"
        ;;
esac

# 检查是否是 Termux 环境
if [ -d "/data/data/com.termux" ]; then
    echo "检测到 Termux 环境"
    if [ "$ARCH" = "aarch64" ]; then
        CFLAGS="$CFLAGS -march=armv8-a"
    elif [[ "$ARCH" =~ ^arm ]]; then
        CFLAGS="$CFLAGS -march=armv7-a -mfloat-abi=softfp -mfpu=neon"
    fi
fi

# 检查编译工具
echo "检查编译工具..."
if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
    echo "错误: 未找到 C 编译器 (gcc 或 clang)"
    echo ""
    echo "请根据你的系统安装编译器:"
    echo "  Termux:        pkg install gcc make"
    echo "  Ubuntu/Debian: apt install gcc make"
    echo "  Arch Linux:    pacman -S gcc make"
    echo "  macOS:         xcode-select --install"
    exit 1
fi

if ! command -v make &> /dev/null; then
    echo "错误: 未找到 make"
    echo ""
    echo "请根据你的系统安装 make:"
    echo "  Termux:        pkg install make"
    echo "  Ubuntu/Debian: apt install make"
    echo "  Arch Linux:    pacman -S make"
    echo "  macOS:         已包含在 Xcode 中"
    exit 1
fi

echo "编译工具检查通过"

# 执行编译
echo "开始编译..."
echo "编译选项: $CFLAGS"

# 清理旧的构建
if [ -d "build" ]; then
    echo "清理旧的构建..."
    rm -rf build
fi

# 使用 make 编译
if make CFLAGS="$CFLAGS"; then
    echo "✓ 编译成功!"
else
    echo "✗ 编译失败!"
    echo ""
    echo "尝试手动编译:"
    echo "  cd $PLUGIN_DIR"
    echo "  make clean"
    echo "  make"
    exit 1
fi

# 验证编译结果
echo "验证编译结果..."
if [ ! -f "build/libfzf.so" ]; then
    echo "错误: build/libfzf.so 不存在"
    exit 1
fi

# 检查文件信息
echo "二进制文件信息:"
file build/libfzf.so
ls -lh build/libfzf.so

# 确保文件可执行
chmod +x build/libfzf.so

echo ""
echo "========================================="
echo "        编译完成!"
echo "========================================="
echo "架构:        $ARCH"
echo "插件目录:    $PLUGIN_DIR"
echo "目标文件:    build/libfzf.so"
echo "编译时间:    $(date)"
echo "========================================="
echo ""
echo "现在可以:"
echo "1. 重启 Neovim"
echo "2. 运行 :checkhealth telescope 检查状态"
echo "3. 运行 :TelescopeCompileFZF 重新编译（如果需要在 Neovim 内）"
echo ""
echo "如果仍有问题，请检查:"
echo "1. 确保插件已正确安装"
echo "2. 检查架构是否匹配: uname -m"
echo "3. 尝试手动编译: cd $PLUGIN_DIR && make clean && make"
