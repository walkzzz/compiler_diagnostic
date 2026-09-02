package compiler_diagnostic.diagnostics
import std.collection.*

/// 诊断收集器，统一管理 Parser/Sema 诊断的生命周期
public class DiagnosticCollector {
    private var messages: List<DiagnosticMessage> = ArrayList<DiagnosticMessage>()

    /// 添加单条诊断消息
    public func add(message: DiagnosticMessage): Unit {
        this.messages.add(message)
    }

    /// 批量添加诊断消息
    public func addAll(messages: List<DiagnosticMessage>): Unit {
        for (msg in messages) {
            this.add(msg)
        }
    }

    /// 获取所有诊断消息
    public func getMessages(): List<DiagnosticMessage> {
        return this.messages
    }

    /// 获取诊断消息数量
    public func count(): Int64 {
        return this.messages.size
    }

    /// 清空所有诊断消息
    public func clear(): Unit {
        this.messages = ArrayList<DiagnosticMessage>()
    }

    /// 按错误码（稳定错误码字符串，如 E0001）分组诊断消息
    public func groupByCode(): Map<String, List<DiagnosticMessage>> {
        let result = HashMap<String, List<DiagnosticMessage>>()
        for (msg in this.messages) {
            let key = msg.code.code()
            if (result.contains(key)) {
                let existing = result.get(key).getOrThrow()
                existing.add(msg)
            } else {
                let newList: List<DiagnosticMessage> = ArrayList<DiagnosticMessage>()
                newList.add(msg)
                result[key] = newList
            }
        }
        return result
    }
}
