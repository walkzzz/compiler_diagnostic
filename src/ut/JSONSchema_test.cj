package compiler_diagnostic.ut
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.output.*


@Test
class JSONSchemaTest {
    @TestCase func testSchemaNotEmpty(): Unit {
        let schema = JSONSchema.SCHEMA
        @Expect(schema.size > 100, true)
    }

    @TestCase func testSchemaContainsRequired(): Unit {
        let schema = JSONSchema.SCHEMA
        @Expect(schema.contains("\"required\""), true)
        @Expect(schema.contains("\"code\""), true)
        @Expect(schema.contains("\"message\""), true)
        @Expect(schema.contains("\"severity\""), true)
    }

    @TestCase func testSchemaDraft07(): Unit {
        let schema = JSONSchema.SCHEMA
        @Expect(schema.contains("draft-07"), true)
    }
}
