package compiler_diagnostic.hlt
import std.unittest.testmacro.*
import std.unittest.*
import compiler_diagnostic.output.*
// EXEC: cjpm build
// EXEC: cjpm test --filter "JSONSchemaValidTest"
// EXPECT: TOTAL:.*2
@Test
class JSONSchemaValidTest {
    @TestCase func testSchemaExists(): Unit {
        @Expect(JSONSchema.SCHEMA.contains("$schema"), true)
    }

    @TestCase func testSchemaDraft(): Unit {
        @Expect(JSONSchema.SCHEMA.contains("draft-07"), true)
    }
}
