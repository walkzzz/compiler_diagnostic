package compiler_diagnostic.common

/// 轻量结果类型。
///
/// 说明：Cangjie 1.1.3 的 `std.fs` 自带一个 `Result`，但与本工程的公共 API 语义
/// （`Result<T>` 单类型参、错误统一为 `String`）冲突，且路径不确定。为保证确定性、
/// 零依赖，此处独立定义单类型参版本，不依赖任何可能存在或不存在的 `std.result`。
public enum Result<T> {
    | Ok(T)
    | Err(String)

    public func isOk(): Bool {
        match (this) {
            case Ok(_) => true
            case Err(_) => false
        }
    }

    public func isErr(): Bool {
        match (this) {
            case Ok(_) => false
            case Err(_) => true
        }
    }

    /// 取出成功值；若为错误则返回给定的默认值（调用方需先确认 isOk）。
    public func getOrElse(default: T): T {
        match (this) {
            case Ok(v) => v
            case Err(_) => default
        }
    }
}
