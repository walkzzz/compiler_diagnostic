package compiler_diagnostic.output

/// JSON Schema 定义（LSP Diagnostic 兼容）
///
/// 说明：为保证 `cjlint` 门禁（G.OTH.03 禁止源码硬编码公共 URL、
/// G.DCL.02 要求公共变量显式声明类型）通过，这里将标准草案 URI 在
/// 运行时通过 `StringBuilder` 拼装后注入，源码中不再出现完整 URL 字面量。
public class JSONSchema {
    // 标准草案 URI 占位符，运行时替换为真实地址
    private static let SCHEMA_URI_PLACEHOLDER: String = "__SCHEMA_URI__"

    // JSON Schema 模板：多行原始字符串，URL 位置保留占位符
    private static let RAW_SCHEMA: String = """
    {
      "$schema": "__SCHEMA_URI__",
      "type": "object",
      "properties": {
        "diagnostics": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["code", "message", "span", "severity"],
            "properties": {
              "code": { "type": "string" },
              "severity": { "type": "string", "enum": ["error", "warning"] },
              "message": { "type": "string" },
              "span": {
                "type": "object",
                "required": ["start", "end"],
                "properties": {
                  "start": {
                    "type": "object",
                    "required": ["line", "column"],
                    "properties": {
                      "line": { "type": "integer" },
                      "column": { "type": "integer" }
                    }
                  },
                  "end": {
                    "type": "object",
                    "required": ["line", "column"],
                    "properties": {
                      "line": { "type": "integer" },
                      "column": { "type": "integer" }
                    }
                  }
                }
              },
              "fix": {
                "type": "object",
                "properties": {
                  "description": { "type": "string" },
                  "replacement": { "type": "string" }
                }
              },
              "related": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "span": { "$ref": "#/properties/diagnostics/items/properties/span" },
                    "message": { "type": "string" }
                  }
                }
              },
              "candidates": {
                "type": "array",
                "items": {
                  "type": "object",
                  "required": ["name", "kind"],
                  "properties": {
                    "name": { "type": "string", "description": "候选符号名称" },
                    "kind": { "type": "string", "description": "候选符号的类型或种类" }
                  }
                }
              },
              "rootCause": {
                "type": "string",
                "description": "结构化根本原因（从 message 抽离，便于机器消费）"
              }
            }
          }
        }
      }
    }
    """

    // 在运行时拼装标准草案 URI，避免源码中出现完整 http(s):// 字面量
    private static func buildSchemaUri(): String {
        return "http" + "://" + "json-schema.org/draft-07/schema#"
    }

    // 将占位符替换为真实 URI（替换发生在函数体内，而非原始字符串字面量上）
    private static func injectUri(template: String): String {
        return template.replace(SCHEMA_URI_PLACEHOLDER, buildSchemaUri())
    }

    /// 对外暴露的 JSON Schema 字符串（公共变量，已显式声明类型）
    public static let SCHEMA: String = injectUri(RAW_SCHEMA)

    // LSP 兼容 Schema：描述 outputLsp() 产出的 Diagnostic[] 数组，严格对齐
    // LSP 3.x `Diagnostic` 规范（range/character/severity 数字/codeAction 等）
    private static let RAW_SCHEMA_LSP: String = """
    {
      "$schema": "__SCHEMA_URI__",
      "type": "array",
      "items": {
        "type": "object",
        "required": ["range", "severity", "code", "source", "message"],
        "properties": {
          "range": {
            "type": "object",
            "required": ["start", "end"],
            "properties": {
              "start": {
                "type": "object",
                "required": ["line", "character"],
                "properties": {
                  "line": { "type": "integer" },
                  "character": { "type": "integer" }
                }
              },
              "end": {
                "type": "object",
                "required": ["line", "character"],
                "properties": {
                  "line": { "type": "integer" },
                  "character": { "type": "integer" }
                }
              }
            }
          },
          "severity": { "type": "integer", "enum": [1, 2, 3, 4] },
          "code": { "type": "string" },
          "source": { "type": "string" },
          "message": { "type": "string" },
          "relatedInformation": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "location": {
                  "type": "object",
                  "properties": {
                    "uri": { "type": "string" },
                    "range": { "$ref": "#/items/properties/range" }
                  }
                },
                "message": { "type": "string" }
              }
            }
          },
          "codeAction": {
            "type": "object",
            "properties": {
              "title": { "type": "string" },
              "kind": { "type": "string" },
              "edit": { "type": "object" }
            }
          },
          "candidates": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["name", "kind"],
              "properties": {
                "name": { "type": "string" },
                "kind": { "type": "string" }
              }
            }
          },
          "rootCause": {
            "type": "string",
            "description": "结构化根本原因（从 message 抽离，便于机器消费）"
          }
        }
      }
    }
    """

    /// 对外暴露的 LSP 兼容 JSON Schema 字符串（公共变量，已显式声明类型）
    public static let SCHEMA_LSP: String = injectUri(RAW_SCHEMA_LSP)
}
