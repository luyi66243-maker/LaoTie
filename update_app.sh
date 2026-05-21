#!/bin/bash

# 更新唠嗑小馆 (LaoTie) 应用在模拟器中的版本
# 停止当前应用、清理构建、重新构建并安装

set -e

# 项目信息
PROJECT_NAME="LaoTie"
SCHEME_NAME="LaoTie"
PROJECT_PATH="/Users/yi/Qoder/LaoTie/LaoTie.xcodeproj"
BUNDLE_ID="com.laotie.LaoTie"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 停止正在运行的应用
stop_app() {
    print_info "尝试停止正在运行的应用..."
    xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true
    print_info "应用已停止"
}

# 获取已启动的模拟器
get_booted_simulator() {
    print_info "查找已启动的模拟器..."
    local BOOTED=$(xcrun simctl list devices | grep "Booted" | head -1)
    if [ -n "$BOOTED" ]; then
        local SIMULATOR_ID=$(echo "$BOOTED" | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}")
        print_info "找到已启动的模拟器: $SIMULATOR_ID"
        echo "$SIMULATOR_ID"
    else
        print_warning "没有找到已启动的模拟器，将查找可用的 iPhone 模拟器"
        # 尝试获取任何可用的 iPhone 模拟器
        local SIMULATOR_ID=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}")
        if [ -z "$SIMULATOR_ID" ]; then
            print_error "未找到可用的模拟器"
            exit 1
        fi
        print_info "找到模拟器: $SIMULATOR_ID"
        echo "$SIMULATOR_ID"
    fi
}

# 清理构建
clean_build() {
    print_info "清理旧的构建文件..."
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME_NAME" \
        clean
    print_info "清理完成"
}

# 重新构建
rebuild() {
    local SIMULATOR_ID=$1
    print_info "重新构建项目（这可能需要一些时间）..."
    xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "id=$SIMULATOR_ID" \
        -sdk iphonesimulator \
        build
    if [ $? -eq 0 ]; then
        print_info "构建成功"
    else
        print_error "构建失败"
        exit 1
    fi
}

# 卸载旧应用
uninstall_old() {
    local SIMULATOR_ID=$1
    print_info "卸载旧版本应用..."
    xcrun simctl uninstall "$SIMULATOR_ID" "$BUNDLE_ID" 2>/dev/null || true
    print_info "卸载完成"
}

# 安装新应用
install_new() {
    local SIMULATOR_ID=$1
    print_info "安装新版本应用..."
    
    # 获取构建路径
    DERIVED_DATA=$(xcodebuild -project "$PROJECT_PATH" -scheme "$SCHEME_NAME" -showBuildSettings | grep "BUILD_DIR" | head -1 | sed 's/BUILD_DIR = //' | sed 's/[[:space:]]*$//')
    APP_PATH="${DERIVED_DATA}/Debug-iphonesimulator/${PROJECT_NAME}.app"
    
    if [ ! -d "$APP_PATH" ]; then
        print_error "找不到构建好的应用: $APP_PATH"
        exit 1
    fi
    
    print_info "应用路径: $APP_PATH"
    xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
    print_info "安装完成"
}

# 启动应用
launch_app() {
    local SIMULATOR_ID=$1
    print_info "启动应用..."
    xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"
    print_info "应用已启动"
}

# 主函数
main() {
    echo "=========================================="
    echo "  唠嗑小馆 (LaoTie) 应用更新脚本"
    echo "=========================================="
    echo ""
    
    SIMULATOR_ID=$(get_booted_simulator)
    
    stop_app
    clean_build
    rebuild "$SIMULATOR_ID"
    uninstall_old "$SIMULATOR_ID"
    install_new "$SIMULATOR_ID"
    launch_app "$SIMULATOR_ID"
    
    echo ""
    print_info "完成！应用已更新到最新版本"
}

main "$@"
