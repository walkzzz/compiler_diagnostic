# GitHub Actions Workflow 模板

## 完整多平台构建 + Release 模板

```yaml
name: Build Multi-Platform

"on":
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          # ── Linux x64 ──
          - os: ubuntu-22.04
            target: linux-x64
            sdk_file: cangjie-sdk-linux-x64-1.1.3.tar.gz
            sdk_url: "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.1.3.tar.gz&objectKey=6a19349d21f5a8178d6fd22b"
            artifact_name: app-linux-x64
            cjc_target: ''
            lib_path: 'linux_x86_64_cjnative'

          # ── macOS ARM64 ──
          - os: macos-14
            target: macos-aarch64
            sdk_file: cangjie-sdk-mac-aarch64-1.1.3.tar.gz
            sdk_url: "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-mac-aarch64-1.1.3.tar.gz&objectKey=6a19312721f5a8178d6fd225"
            artifact_name: app-macos-aarch64
            cjc_target: ''
            lib_path: 'darwin_aarch64_cjnative'

          # ── Windows x64 (交叉编译) ──
          - os: ubuntu-22.04
            target: windows-x64
            sdk_file: cangjie-sdk-linux-x64-1.1.3.tar.gz
            sdk_url: "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.1.3.tar.gz&objectKey=6a19349d21f5a8178d6fd22b"
            artifact_name: app-windows-x64.exe
            cjc_target: '--target x86_64-pc-windows-gnu'
            lib_path: 'linux_x86_64_cjnative'

    runs-on: ${{ matrix.os }}
    name: Build ${{ matrix.target }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Cangjie SDK
        run: |
          wget --no-check-certificate "${{ matrix.sdk_url }}" -O ${{ matrix.sdk_file }}
          tar -zxf ${{ matrix.sdk_file }}

      - name: Setup environment
        run: |
          SDK_DIR="$(pwd)/cangjie"
          echo "CANGJIE_HOME=$SDK_DIR" >> $GITHUB_ENV
          echo "$SDK_DIR/bin" >> $GITHUB_PATH
          echo "$SDK_DIR/tools/bin" >> $GITHUB_PATH
          if [ -d "$SDK_DIR/runtime/lib/${{ matrix.lib_path }}" ]; then
            echo "LD_LIBRARY_PATH=$SDK_DIR/runtime/lib/${{ matrix.lib_path }}:$SDK_DIR/lib/${{ matrix.lib_path }}" >> $GITHUB_ENV
          fi
          if [ -d "$SDK_DIR/runtime/lib/darwin_aarch64_cjnative" ]; then
            echo "DYLD_LIBRARY_PATH=$SDK_DIR/runtime/lib/darwin_aarch64_cjnative:$SDK_DIR/lib/darwin_aarch64_cjnative" >> $GITHUB_ENV
          fi

      - name: Setup macOS SDK
        if: runner.os == 'macOS'
        run: |
          echo "SDKROOT=$(xcrun --sdk macosx --show-sdk-path)" >> $GITHUB_ENV

      - name: Verify toolchain
        run: |
          cjc --version
          cjpm --version

      - name: Build
        run: |
          EXTRA_FLAGS=""
          if [ "${{ runner.os }}" = "macOS" ]; then
            SYSROOT=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null)
            if [ -n "$SYSROOT" ]; then
              EXTRA_FLAGS="-B $SYSROOT/usr/lib -B $SYSROOT/usr/lib/system"
            fi
          fi
          cjc src/main.cj ${{ matrix.cjc_target }} $EXTRA_FLAGS -s -o ${{ matrix.artifact_name }}
          file ${{ matrix.artifact_name }}
          ls -lh ${{ matrix.artifact_name }}

      - name: Test binary
        run: |
          if [ "${{ matrix.target }}" != "windows-x64" ]; then
            chmod +x ${{ matrix.artifact_name }}
            ./${{ matrix.artifact_name }} || true
          fi

      # ── Windows: 直接 .exe ──
      - name: Package Windows
        if: matrix.target == 'windows-x64'
        run: |
          sha256sum ${{ matrix.artifact_name }} > ${{ matrix.artifact_name }}.sha256

      # ── macOS: 创建 .dmg ──
      - name: Create macOS .dmg
        if: runner.os == 'macOS'
        run: |
          mkdir -p dmg_content
          cp ${{ matrix.artifact_name }} dmg_content/
          ln -s /Applications dmg_content/Applications
          DMG=app-v1.0.0-${{ matrix.target }}.dmg
          hdiutil create -volname "App" -srcfolder dmg_content -ov -format UDZO "$DMG"
          shasum -a 256 "$DMG" > "$DMG.sha256"

      # ── Linux: tar.gz ──
      - name: Create tarball
        run: |
          tar -czf app-v1.0.0-${{ matrix.target }}.tar.gz ${{ matrix.artifact_name }}
          if command -v sha256sum &> /dev/null; then
            sha256sum app-v1.0.0-${{ matrix.target }}.tar.gz > app-v1.0.0-${{ matrix.target }}.tar.gz.sha256
          else
            shasum -a 256 app-v1.0.0-${{ matrix.target }}.tar.gz > app-v1.0.0-${{ matrix.target }}.tar.gz.sha256
          fi

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-${{ matrix.target }}
          path: |
            ${{ matrix.artifact_name }}
            ${{ matrix.artifact_name }}.sha256
            app-v1.0.0-${{ matrix.target }}.tar.gz
            app-v1.0.0-${{ matrix.target }}.tar.gz.sha256
            app-v1.0.0-${{ matrix.target }}.dmg
            app-v1.0.0-${{ matrix.target }}.dmg.sha256

  release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    steps:
      - uses: actions/download-artifact@v4
        with:
          path: artifacts
      - uses: softprops/action-gh-release@v2
        with:
          files: |
            artifacts/**/app-*.tar.gz
            artifacts/**/app-*.tar.gz.sha256
            artifacts/**/app-*.exe
            artifacts/**/app-*.exe.sha256
            artifacts/**/app-*.dmg
            artifacts/**/app-*.dmg.sha256
          draft: false
          generate_release_notes: true
```

## 关键注意事项

1. **`"on"` 必须加引号** — YAML 1.1 将 `on` 解析为布尔值 `true`
2. **`permissions: contents: write`** — 创建 Release 的必需权限
3. **`fail-fast: false`** — 一个平台失败不影响其他平台
4. **SDK 架构匹配 Runner** — x64 runner 用 x64 SDK，ARM64 runner 用 aarch64 SDK
5. **macOS SDKROOT** — 不设置会导致链接器找不到 `_memcpy` 等系统符号
6. **glob 模式** — `artifacts/**/` 注意双星后要有斜杠
