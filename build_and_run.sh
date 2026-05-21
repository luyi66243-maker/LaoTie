#!/bin/bash

# 唠嗑小馆 (LaoTie) 项目构建和运行脚本
# 用于在 iOS 模拟器中构建并运行应用

set -e

# 项目信息
PROJECT_NAME="LaoTie"
SCHEME_NAME="LaoTie"
PROJECT_PATH="/Users/yi/Qoder/LaoTie/LaoTie.xcodeproj"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印信息函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Xcode 命令行工具是否安装
check_xcode() {
    print_info "检查 Xcode 命令行工具..."
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode 命令行工具未安装，请先运行: xcode-select --install"
        exit 1
    fi
    print_info "Xcode 命令行工具已就绪"
}

# 获取可用的模拟器列表
list_simulators() {
    print_info "获取可用的 iOS 模拟器列表..."
    xcrun simctl list devices available | grep -E "(iPhone|iPad)" || true
}

# 获取合适的模拟器设备 ID
get_simulator_id() {
    print_info "查找可用的 iPhone 模拟器..."
    
    # 尝试获取最新的 iPhone 模拟器
    SIMULATOR_ID=$(xcrun simctl list devices available | grep -E "iPhone (1[5-9]|20)" | head -1 | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}")
    
    if [ -z "$SIMULATOR_ID" ]; then
        # 如果没有找到，尝试获取任何 iPhone 模拟器
        SIMULATOR_ID=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}")
    fi
    
    if [ -z "$SIMULATOR_ID" ]; then
        print_error "未找到可用的 iPhone 模拟器，请确保已在 Xcode 中安装模拟器"
        exit 1
    fi
    
    print_info "找到模拟器设备 ID: $SIMULATOR_ID"
    echo "$SIMULATOR_ID"
}

# 启动模拟器
boot_simulator() {
    local SIMULATOR_ID=$1
    print_info "启动模拟器..."
    xcrun simctl boot "$SIMULATOR_ID" || true # 如果已经启动，忽略错误
}

# 构建项目
build_project() {
    local SIMULATOR_ID=$1
    print_info "开始构建项目..."
    
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "id=$SIMULATOR_ID" \
        -sdk iphonesimulator \
        clean build
    
    if [ $? -eq 0 ]; then
        print_info "项目构建成功"
    else
        print_error "项目构建失败"
        exit 1
    fi
}

# 安装并运行应用
install_and_run() {
    local SIMULATOR_ID=$1
    print_info "安装并运行应用..."
    
    # 查找构建好的 .app 文件
    DERIVED_DATA=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME_NAME" -showBuildSettings | grep "BUILD_DIR" | head -1 | sed 's/BUILD_DIR = //' | sed 's/[[:space:]]*$//')
    APP_PATH="${DERIVED_DATA}/Debug-iphonesimulator/${PROJECT_NAME}.app"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "找不到构建好的应用: $APP_PATH"
        exit 1
    fi
    
    print_info "应用路径: $APP_PATH"
    
    # 安装应用
    xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
    
    # 启动应用
    xcrun simctl launch "$SIMULATOR_ID" "com.laotie.LaoTie"
    
    print_info "应用已成功在模拟器中启动"
}

# 主函数
main() {
    echo "=========================================="
    echo "  唠嗑小馆 (LaoTie) 构建和运行脚本"
    echo "=========================================="
    echo ""
    
    check_xcode
    
    # 列出可用的模拟器（可选，用于调试）
    if [ "$1" == "--list" ]; then
        list_simulators
        exit 0
    fi
    
    SIMULATOR_ID=$(get_simulator_id)
    boot_simulator "$SIMULATOR_ID"
    build_project "$SIMULATOR_ID"
    install_and_run "$SIMULATOR_ID"
    
    echo ""
    print_info "完成！应用已在模拟器中运行"
    echo "提示: 你可以使用 --list 参数查看所有可用模拟器"
}

# 执行主函数
main "$@"
