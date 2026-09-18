///|
test "imports supported Clang AST declarations" {
  let text = @fs.read_file_to_string("fixtures/clang/demo-ast.json") catch {
    _ => panic()
  }
  let contract = import_clang_ast(text, "demo-binding", ["demo.h"]) catch {
    _ => panic()
  }
  inspect(contract.name, content="demo-binding")
  inspect(contract.types.length(), content="1")
  inspect(contract.types[0].name, content="demo_config")
  inspect(contract.types[0].fields.length(), content="3")
  inspect(contract.constants.length(), content="2")
  inspect(contract.symbols.length(), content="3")
  assert_true(
    contract.symbols.any(fn(item) {
      item.name == "demo_create" &&
      item.returns == "demo_handle *" &&
      item.params.length() == 1 &&
      item.params[0] == "const demo_config *"
    }),
  )
}

///|
test "filters declarations from other headers" {
  let text = @fs.read_file_to_string("fixtures/clang/demo-ast.json") catch {
    _ => panic()
  }
  let contract = import_clang_ast(text, "demo-binding", ["demo.h"]) catch {
    _ => panic()
  }
  assert_true(
    !contract.symbols.any(fn(item) { item.name == "system_function" }),
  )
}
