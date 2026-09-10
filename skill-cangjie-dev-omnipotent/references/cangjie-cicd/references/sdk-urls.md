# Cangjie SDK 下载地址汇总

## 获取方式

SDK 地址在 cangjie-lang.cn 的 JS 文件中，不在静态 HTML 中。需要解析 version.js：

```bash
curl -s "https://csdnimg.cn/release/devpress-cangjie/public/js/chunk/organization/download/version.8e688f93.js" -o /tmp/version.js

python3 -c "
import re
with open('/tmp/version.js') as f:
    content = f.read()
pattern = r'downLoad\?nsId=(\d+)&fileName=(cangjie-sdk-[^&]+\.tar\.gz)&objectKey=([a-f0-9]+)\"'
for m in re.findall(pattern, content):
    if '1.1.3' in m[1] and 'android' not in m[1] and 'ohos' not in m[1] and 'ios' not in m[1]:
        print(f'{m[1]}  objectKey={m[2]}')
"
```

## 1.1.3 版本 (STS)

| SDK 文件 | objectKey | 大小 |
|---------|-----------|------|
| `cangjie-sdk-linux-x64-1.1.3.tar.gz` | `6a19349d21f5a8178d6fd22b` | ~403 MB |
| `cangjie-sdk-linux-aarch64-1.1.3.tar.gz` | `6a19350321f5a8178d6fd22c` | ~378 MB |
| `cangjie-sdk-mac-aarch64-1.1.3.tar.gz` | `6a19312721f5a8178d6fd225` | ~245 MB |

## URL 模式

```
https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName={sdk_file}&objectKey={object_key}
```

## 下载示例

```bash
wget --no-check-certificate \
  "https://cangjie-lang.cn/v1/files/auth/downLoad?nsId=142267&fileName=cangjie-sdk-linux-x64-1.1.3.tar.gz&objectKey=6a19349d21f5a8178d6fd22b" \
  -O cangjie-sdk-linux-x64-1.1.3.tar.gz
```

## SDK 目录结构

解压后得到 `cangjie/` 目录：

```
cangjie/
├── bin/
│   ├── cjc          # 仓颉编译器
│   └── cjpm         # 包管理器
├── lib/
│   ├── linux_x86_64_cjnative/
│   ├── linux_aarch64_cjnative/
│   └── darwin_aarch64_cjnative/
├── runtime/
│   └── lib/
│       ├── linux_x86_64_cjnative/
│       │   └── libcangjie-runtime.so
│       ├── linux_aarch64_cjnative/
│       │   └── libcangjie-runtime.so
│       └── darwin_aarch64_cjnative/
│           └── libcangjie-runtime.dylib
├── modules/
│   ├── linux_x86_64_cjnative/
│   ├── linux_aarch64_cjnative/
│   └── darwin_aarch64_cjnative/
├── third_party/
│   └── llvm/
│       └── bin/
│           ├── ld64.lld    # macOS 链接器
│           └── lld-link    # Windows 链接器
└── tools/
    └── bin/
```

## 环境变量

```bash
export CANGJIE_HOME="$(pwd)/cangjie"
export PATH="$CANGJIE_HOME/bin:$CANGJIE_HOME/tools/bin:$PATH"

# Linux
export LD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/$LIB_PATH:$CANGJIE_HOME/lib/$LIB_PATH"

# macOS
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:$CANGJIE_HOME/lib/darwin_aarch64_cjnative"
export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
```
