package compiler_diagnostic.semantic_trace

import std.collection.*
import compiler_diagnostic.common.*
import std.fs.*
import compiler_diagnostic.diagnostics.SourceLoc

// ===== JSON 值模型（仅用于反序列化，确定性、零网络） =====
public open class JsonNode {
    // 仓颉要求：可被子类 override 的成员必须显式声明 open，否则报 "cannot override function"。
    public open func asString(): String { return "" }
    public open func asInt(): Int64 { return 0 }
    public open func isNull(): Bool { return false }
    public open func getObject(): HashMap<String, JsonNode> { return HashMap<String, JsonNode>() }
    public open func getArray(): ArrayList<JsonNode> { return ArrayList<JsonNode>() }
}

public class JsonObject <: JsonNode {
    public let members: HashMap<String, JsonNode>
    public init(members!: HashMap<String, JsonNode>) { this.members = members }
    public override func getObject(): HashMap<String, JsonNode> { return this.members }
}

public class JsonArray <: JsonNode {
    public let items: ArrayList<JsonNode>
    public init(items!: ArrayList<JsonNode>) { this.items = items }
    public override func getArray(): ArrayList<JsonNode> { return this.items }
}

public class JsonString <: JsonNode {
    public let value: String
    public init(value!: String) { this.value = value }
    public override func asString(): String { return this.value }
}

public class JsonNumber <: JsonNode {
    public let value: Int64
    public init(value!: Int64) { this.value = value }
    public override func asInt(): Int64 { return this.value }
}

public class JsonBool <: JsonNode {
    public let value: Bool
    public init(value!: Bool) { this.value = value }
    public override func asInt(): Int64 { return if (this.value) { 1 } else { 0 } }
}

public class JsonNull <: JsonNode {
    public init() {}
    public override func isNull(): Bool { return true }
}

/// Trace 序列化 / 反序列化 + 文件导出 / 加载 + MAJOR 兼容校验。
public class TraceSerde {

    /// 序列化（参考 JSONOutput.cj 的 StringBuilder + escapeJson 风格，字段顺序稳定）
    public static func toJson(trace: Trace): String {
        let sb = StringBuilder()
        sb.append("{")
        sb.append("\"schemaVersion\":\"")
        sb.append(escapeJson(trace.schemaVersion))
        sb.append("\",\"generator\":{")
        sb.append("\"tool\":\"")
        sb.append(escapeJson(trace.generator.tool))
        sb.append("\",\"version\":\"")
        sb.append(escapeJson(trace.generator.version))
        sb.append("\",\"sdk\":\"")
        sb.append(escapeJson(trace.generator.sdk))
        sb.append("\"}")
        sb.append(",\"program\":{\"entry\":\"")
        sb.append(escapeJson(trace.program.entry))
        sb.append("\",\"args\":[")
        var firstArg = true
        for (a in trace.program.args) {
            if (!firstArg) { sb.append(",") }
            firstArg = false
            sb.append("\"")
            sb.append(escapeJson(a))
            sb.append("\"")
        }
        sb.append("]}")
        sb.append(",\"machineEvents\":[")
        var firstEv = true
        for (e in trace.machineEvents) {
            if (!firstEv) { sb.append(",") }
            firstEv = false
            sb.append(eventToJson(e))
        }
        sb.append("]")
        sb.append(",\"semanticEvents\":[]")
        sb.append("}")
        return sb.toString()
    }

    /// 导出到 .trace.json（写盘失败返回 Err）
    public static func exportToFile(trace: Trace, path: String): Result<Int64> {
        let json = TraceSerde.toJson(trace)
        // std.fs 真实契约：File.writeTo(String, Array<UInt8>) -> Unit，失败以异常抛出；
        // 不存在 std.fs.Result（Result 属 std.core，见 common/result.cj 说明），
        // 故改用 try/catch 收敛为本工程 Result<T>。
        try {
            File.writeTo(path, json.toArray())
            return Ok(0)
        } catch (e: Exception) {
            return Err("failed to write trace file: " + path)
        }
    }

    /// 反序列化 + MAJOR 校验（不兼容返回 Err，不静默损坏）
    public static func fromJson(text: String): Result<Trace> {
        let parser = JsonParser(text: text)
        let pr = parser.parse()
        if (pr.isErr()) {
            return Err("json parse error: " + text)
        }
        let root = match (pr) { case Ok(n) => n case Err(_) => JsonNull() }
        let obj = root.getObject()
        let sv = field(obj, "schemaVersion").asString()
        let major = parseMajor(sv)
        if (major != TRACE_SCHEMA_MAJOR) {
            return Err("schema version incompatible: expected major " + TRACE_SCHEMA_MAJOR.toString() +
                " but got " + major.toString())
        }
        let entry = field(field(obj, "program").getObject(), "entry").asString()
        let meArr = field(obj, "machineEvents").getArray()
        let events = ArrayList<MachineEvent>()
        for (node in meArr) {
            let evObj = node.getObject()
            let stepId = field(evObj, "stepId").asInt()
            let kind = field(evObj, "kind").asString()
            let loc = parseLoc(field(evObj, "loc"))
            let path = field(evObj, "path").asString()
            let exc = parseException(field(evObj, "exception"))
            events.add(MachineEvent(
                stepId: stepId,
                kind: kind,
                loc: loc,
                stack: Array<StackFrame>(),
                symbols: Array<SymbolValue>(),
                path: path,
                exception: exc))
        }
        let gen = GeneratorInfo(tool: "compiler_diagnostic/event_emitter", version: sv, sdk: "cangjie-1.1.3")
        let prog = ProgramInfo(entry: entry, args: Array<String>())
        return Ok(Trace(
            schemaVersion: sv,
            generator: gen,
            program: prog,
            machineEvents: events.toArray(),
            semanticEvents: Array<SemanticEvent>()))
    }

    /// 从 .trace.json 加载（文件不存在/解析失败返回 Err）
    public static func loadFromFile(path: String): Result<Trace> {
        // std.fs 真实契约：File.readFrom(String) -> Array<UInt8>，失败抛异常（已实测确认）。
        try {
            let bytes = File.readFrom(path)
            return TraceSerde.fromJson(String.fromUtf8(bytes))
        } catch (e: Exception) {
            return Err("failed to read trace file: " + path)
        }
    }

    // ===== 内部：序列化辅助 =====

    private static func eventToJson(e: MachineEvent): String {
        let sb = StringBuilder()
        sb.append("{")
        sb.append("\"stepId\":")
        sb.append(e.stepId.toString())
        sb.append(",\"kind\":\"")
        sb.append(escapeJson(e.kind))
        sb.append("\"")
        sb.append(",\"loc\":{")
        sb.append("\"line\":")
        sb.append(e.loc.line.toString())
        sb.append(",\"column\":")
        sb.append(e.loc.column.toString())
        sb.append(",\"file\":\"")
        sb.append(escapeJson(e.loc.file))
        sb.append("\"}")
        sb.append(",\"stack\":[]")
        sb.append(",\"symbols\":[]")
        sb.append(",\"path\":\"")
        sb.append(escapeJson(e.path))
        sb.append("\"")
        sb.append(",\"exception\":")
        sb.append(exceptionToJson(e.exception))
        sb.append("}")
        return sb.toString()
    }

    private static func exceptionToJson(exc: Option<ExceptionInfo>): String {
        match (exc) {
            case Some(e) => "{\"type\":\"" + escapeJson(e.`type`) + "\",\"message\":\"" + escapeJson(e.message) + "\"}"
            case None => "null"
        }
    }

    // ===== 内部：反序列化辅助 =====

    private static func field(obj: HashMap<String, JsonNode>, key: String): JsonNode {
        let o = obj.get(key)
        match (o) {
            case Some(n) => n
            case None => JsonNull()
        }
    }

    private static func parseMajor(sv: String): Int64 {
        let parts = sv.split(".")
        if (parts.size > 0) {
            return parseInt64(parts[0])
        }
        return 0
    }

    private static func parseLoc(node: JsonNode): SourceLoc {
        let o = node.getObject()
        let line = field(o, "line").asInt()
        let col = field(o, "column").asInt()
        let file = field(o, "file").asString()
        return SourceLoc(line: line, column: col, file: file)
    }

    private static func parseException(node: JsonNode): Option<ExceptionInfo> {
        if (node.isNull()) {
            return None
        }
        let o = node.getObject()
        let t = field(o, "type").asString()
        let m = field(o, "message").asString()
        return Some(ExceptionInfo(typeName: t, message: m))
    }

    private static func parseInt64(s: String): Int64 {
        var v = 0
        let runes = s.toRuneArray()
        for (ch in runes) {
            v = v * 10 + digitValue(ch)
        }
        return v
    }

    private static func digitValue(ch: Rune): Int64 {
        let zero = UInt32(r'0')
        let cp = UInt32(ch)
        return Int64(cp - zero)
    }

    // ===== 公共：JSON 转义（复用风格，转义 \" \\ \n \r \t 与控制字符） =====
    public static func escapeJson(s: String): String {
        var result = s
        result = result.replace("\\", "\\\\")
        result = result.replace("\"", "\\\"")
        result = result.replace("\n", "\\n")
        result = result.replace("\r", "\\r")
        result = result.replace("\t", "\\t")
        let sb = StringBuilder()
        let runes = result.toRuneArray()
        for (r in runes) {
            let cp = UInt32(r)
            if (cp < 32u32) {
                sb.append("\\u")
                sb.append(hexDigit(cp / 16u32))
                sb.append(hexDigit(cp % 16u32))
            } else {
                sb.append(runeToUtf8(r))
            }
        }
        return sb.toString()
    }

    private static func hexDigit(n: UInt32): String {
        match (n) {
            case 0u32 => "0"
            case 1u32 => "1"
            case 2u32 => "2"
            case 3u32 => "3"
            case 4u32 => "4"
            case 5u32 => "5"
            case 6u32 => "6"
            case 7u32 => "7"
            case 8u32 => "8"
            case 9u32 => "9"
            case 10u32 => "A"
            case 11u32 => "B"
            case 12u32 => "C"
            case 13u32 => "D"
            case 14u32 => "E"
            case _ => "F"
        }
    }

    private static func runeToUtf8(c: Rune): String {
        let cp = Int64(UInt32(c))
        return utf8Of(cp)
    }

    private static func utf8Of(cp: Int64): String {
        if (cp < 0x80) {
            return String.fromUtf8(Array<Byte>(1, { _ => UInt8(cp) }))
        } else if (cp < 0x800) {
            let b0 = 0xC0 + (cp / 64)
            let b1 = 0x80 + (cp % 64)
            return String.fromUtf8(Array<Byte>(2, { i => if (i == 0) { UInt8(b0) } else { UInt8(b1) } }))
        } else if (cp < 0x10000) {
            let b0 = 0xE0 + (cp / 4096)
            let b1 = 0x80 + ((cp / 64) % 64)
            let b2 = 0x80 + (cp % 64)
            return String.fromUtf8(Array<Byte>(3, { i =>
                if (i == 0) { UInt8(b0) } else if (i == 1) { UInt8(b1) } else { UInt8(b2) } }))
        } else {
            let b0 = 0xF0 + (cp / 262144)
            let b1 = 0x80 + ((cp / 4096) % 64)
            let b2 = 0x80 + ((cp / 64) % 64)
            let b3 = 0x80 + (cp % 64)
            return String.fromUtf8(Array<Byte>(4, { i =>
                if (i == 0) { UInt8(b0) } else if (i == 1) { UInt8(b1) }
                else if (i == 2) { UInt8(b2) } else { UInt8(b3) } }))
        }
    }
}

/// JSON 递归下降解析器（不依赖 stdx；确定性、零网络）。
class JsonParser {
    private let chars: Array<Rune>
    private var pos: Int64

    public init(text!: String) {
        this.chars = text.toRuneArray()
        this.pos = 0
    }

    public func parse(): Result<JsonNode> {
        this.skipWs()
        return this.parseValue()
    }

    private func skipWs(): Unit {
        while (this.pos < this.chars.size) {
            let c = this.chars[this.pos]
            if (c == r' ' || c == r'\n' || c == r'\r' || c == r'\t') {
                this.pos = this.pos + 1
            } else {
                break
            }
        }
    }

    private func parseValue(): Result<JsonNode> {
        if (this.pos >= this.chars.size) {
            return Err("unexpected end of json")
        }
        let c = this.chars[this.pos]
        match (c) {
            case r'{' => this.parseObject()
            case r'[' => this.parseArray()
            case r'"' => this.parseString()
            case r't' => this.parseLiteral("true", JsonBool(value: true))
            case r'f' => this.parseLiteral("false", JsonBool(value: false))
            case r'n' => this.parseLiteral("null", JsonNull())
            case _ => this.parseNumber()
        }
    }

    private func parseObject(): Result<JsonNode> {
        this.pos = this.pos + 1
        let m = HashMap<String, JsonNode>()
        this.skipWs()
        if (this.pos < this.chars.size && this.chars[this.pos] == r'}') {
            this.pos = this.pos + 1
            return Ok(JsonObject(members: m))
        }
        while (true) {
            this.skipWs()
            if (this.pos >= this.chars.size) {
                return Err("unterminated object")
            }
            if (this.chars[this.pos] != r'"') {
                return Err("expected string key in object")
            }
            let keyR = this.parseString()
            if (keyR.isErr()) {
                return Err("bad object key")
            }
            let keyNode = match (keyR) { case Ok(n) => n case Err(_) => JsonString(value: "") }
            let key = keyNode.asString()
            this.skipWs()
            if (this.pos >= this.chars.size || this.chars[this.pos] != r':') {
                return Err("expected colon in object")
            }
            this.pos = this.pos + 1
            let valR = this.parseValue()
            if (valR.isErr()) {
                return Err("bad object value")
            }
            let val = match (valR) { case Ok(n) => n case Err(_) => JsonNull() }
            m[key] = val
            this.skipWs()
            if (this.pos < this.chars.size && this.chars[this.pos] == r',') {
                this.pos = this.pos + 1
            } else if (this.pos < this.chars.size && this.chars[this.pos] == r'}') {
                this.pos = this.pos + 1
                return Ok(JsonObject(members: m))
            } else {
                return Err("expected , or } in object")
            }
        }
        // while 表达式类型为 Unit，而函数返回 Result；循环内各出口均已 return，此句不可达，仅为满足类型收尾。
        return Err("unterminated object")
    }

    private func parseArray(): Result<JsonNode> {
        this.pos = this.pos + 1
        let items = ArrayList<JsonNode>()
        this.skipWs()
        if (this.pos < this.chars.size && this.chars[this.pos] == r']') {
            this.pos = this.pos + 1
            return Ok(JsonArray(items: items))
        }
        while (true) {
            this.skipWs()
            let vR = this.parseValue()
            if (vR.isErr()) {
                return Err("bad array element")
            }
            let v = match (vR) { case Ok(n) => n case Err(_) => JsonNull() }
            items.add(v)
            this.skipWs()
            if (this.pos < this.chars.size && this.chars[this.pos] == r',') {
                this.pos = this.pos + 1
            } else if (this.pos < this.chars.size && this.chars[this.pos] == r']') {
                this.pos = this.pos + 1
                return Ok(JsonArray(items: items))
            } else {
                return Err("expected , or ] in array")
            }
        }
        // 同上：while 类型为 Unit，补 Result 收尾（不可达）。
        return Err("unterminated array")
    }

    private func parseString(): Result<JsonNode> {
        this.pos = this.pos + 1
        let sb = StringBuilder()
        while (this.pos < this.chars.size) {
            let c = this.chars[this.pos]
            if (c == r'"') {
                this.pos = this.pos + 1
                return Ok(JsonString(value: sb.toString()))
            } else if (c == r'\\') {
                this.pos = this.pos + 1
                if (this.pos >= this.chars.size) {
                    return Err("bad escape in string")
                }
                let e = this.chars[this.pos]
                match (e) {
                    case r'"' => sb.append("\"")
                    case r'\\' => sb.append("\\")
                    case r'/' => sb.append("/")
                    case r'n' => sb.append("\n")
                    case r't' => sb.append("\t")
                    case r'r' => sb.append("\r")
                    case r'b' => sb.append("\b")
                    case r'f' => sb.append("\f")
                    // 仓颉 match 分支体只能是"表达式"：`=>` 后的 {...} 会被解析为 lambda 字面量，
                    // 故多语句分支须合并为单表达式。求值顺序不变：先 parseHex4()（推进 pos），再 utf8OfTop。
                    case r'u' => sb.append(utf8OfTop(this.parseHex4()))
                    case _ => sb.append(runeToStrTop(e))
                }
                this.pos = this.pos + 1
            } else {
                sb.append(runeToStrTop(c))
                this.pos = this.pos + 1
            }
        }
        return Err("unterminated string")
    }

    private func parseHex4(): Int64 {
        var v = 0
        var i = 0
        while (i < 4 && this.pos < this.chars.size) {
            let c = this.chars[this.pos]
            v = v * 16 + hexValue(c)
            this.pos = this.pos + 1
            i = i + 1
        }
        return v
    }

    private func hexValue(c: Rune): Int64 {
        match (c) {
            case r'0' => 0
            case r'1' => 1
            case r'2' => 2
            case r'3' => 3
            case r'4' => 4
            case r'5' => 5
            case r'6' => 6
            case r'7' => 7
            case r'8' => 8
            case r'9' => 9
            case r'a' => 10
            case r'b' => 11
            case r'c' => 12
            case r'd' => 13
            case r'e' => 14
            case r'f' => 15
            case r'A' => 10
            case r'B' => 11
            case r'C' => 12
            case r'D' => 13
            case r'E' => 14
            case r'F' => 15
            case _ => 0
        }
    }

    private func parseLiteral(lit: String, node: JsonNode): Result<JsonNode> {
        let runes = lit.toRuneArray()
        var i = 0
        while (i < runes.size) {
            if (this.pos >= this.chars.size || this.chars[this.pos] != runes[i]) {
                return Err("invalid literal")
            }
            this.pos = this.pos + 1
            i = i + 1
        }
        return Ok(node)
    }

    private func parseNumber(): Result<JsonNode> {
        let start = this.pos
        if (this.pos < this.chars.size && this.chars[this.pos] == r'-') {
            this.pos = this.pos + 1
        }
        while (this.pos < this.chars.size) {
            let c = this.chars[this.pos]
            if (c >= r'0' && c <= r'9') {
                this.pos = this.pos + 1
            } else {
                break
            }
        }
        let numStr = this.substring(start, this.pos)
        return Ok(JsonNumber(value: parseInt64Top(numStr)))
    }

    private func substring(start: Int64, end: Int64): String {
        let sb = StringBuilder()
        var i = start
        while (i < end) {
            sb.append(runeToStrTop(this.chars[i]))
            i = i + 1
        }
        return sb.toString()
    }

    private func parseInt64Top(s: String): Int64 {
        var v = 0
        let runes = s.toRuneArray()
        for (ch in runes) {
            v = v * 10 + digitValueTop(ch)
        }
        return v
    }

    private func digitValueTop(ch: Rune): Int64 {
        let zero = UInt32(r'0')
        let cp = UInt32(ch)
        return Int64(cp - zero)
    }
}

// ===== 解析器内的辅助（避免跨类方法可见性歧义，独立函数） =====
func runeToStrTop(c: Rune): String {
    return utf8OfTop(Int64(UInt32(c)))
}

func utf8OfTop(cp: Int64): String {
    if (cp < 0x80) {
        return String.fromUtf8(Array<Byte>(1, { _ => UInt8(cp) }))
    } else if (cp < 0x800) {
        let b0 = 0xC0 + (cp / 64)
        let b1 = 0x80 + (cp % 64)
        return String.fromUtf8(Array<Byte>(2, { i => if (i == 0) { UInt8(b0) } else { UInt8(b1) } }))
    } else if (cp < 0x10000) {
        let b0 = 0xE0 + (cp / 4096)
        let b1 = 0x80 + ((cp / 64) % 64)
        let b2 = 0x80 + (cp % 64)
        return String.fromUtf8(Array<Byte>(3, { i =>
            if (i == 0) { UInt8(b0) } else if (i == 1) { UInt8(b1) } else { UInt8(b2) } }))
    } else {
        let b0 = 0xF0 + (cp / 262144)
        let b1 = 0x80 + ((cp / 4096) % 64)
        let b2 = 0x80 + ((cp / 64) % 64)
        let b3 = 0x80 + (cp % 64)
        return String.fromUtf8(Array<Byte>(4, { i =>
            if (i == 0) { UInt8(b0) } else if (i == 1) { UInt8(b1) }
            else if (i == 2) { UInt8(b2) } else { UInt8(b3) } }))
    }
}
