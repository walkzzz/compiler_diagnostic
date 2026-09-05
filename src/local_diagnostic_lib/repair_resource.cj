package compiler_diagnostic.local_diagnostic_lib

/// 修复文案 / 代码片段资源（被 `formal_library` 引用）。
/// 全部为确定性常量，无 IO、无随机、无网络（满足 NF-1/NF-2）。

public let RT_ARRAY_OOB_ROOT_CAUSE: String =
    "数组下标超出数组有效范围 [0, len)，运行时抛出 ArrayIndexOutOfBounds。"
public let RT_ARRAY_OOB_FIX_DESC: String = "添加边界检查或改用安全下标访问"
public let RT_ARRAY_OOB_CANDIDATE: String =
    "if (idx >= 0 && idx < arr.size) {\n    let v = arr[idx]\n} else {\n    // 处理越界情况\n}"

public let TP_TYPE_MISMATCH_ROOT_CAUSE: String =
    "赋值或传参时源类型与目标类型不一致，触发 TypeMismatch。"
public let TP_TYPE_MISMATCH_FIX_DESC: String = "显式类型转换或修正类型注解"
public let TP_TYPE_MISMATCH_CANDIDATE: String =
    "let x: Int64 = foo.toInt64()   // 显式转换；或修正声明的类型注解"

public let RT_USE_AFTER_MOVE_ROOT_CAUSE: String =
    "值在 move 之后被再次使用，触发 UseAfterMove。"
public let RT_USE_AFTER_MOVE_FIX_DESC: String = "避免 move 后使用，或改用 Copy / 借用"
public let RT_USE_AFTER_MOVE_CANDIDATE: String =
    "// 在 move 前完成所需使用，或改用 Clone / 借用\nlet y = x.clone()"

public let SE_NONEXHAUSTIVE_ROOT_CAUSE: String =
    "match 表达式未覆盖所有可能取值，缺少穷尽分支，触发 NonExhaustiveMatch。"
public let SE_NONEXHAUSTIVE_FIX_DESC: String = "补全分支或增加通配臂"
public let SE_NONEXHAUSTIVE_CANDIDATE: String =
    "match (x) {\n    case A => ...\n    case B => ...\n    case _ => ... // 通配臂\n}"
