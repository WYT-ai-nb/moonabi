///|
test "CLI parses inspect options" {
  let options = parse_cli_options([
    "moonabi.exe", "inspect", "--config", "abi.json", "--lock", "abi.lock", "--format",
    "json", "--cc", "clang",
  ]) catch {
    _ => panic()
  }
  assert_true(options.command == Inspect)
  inspect(options.config_path, content="abi.json")
  inspect(options.lock_path, content="abi.lock")
  assert_true(options.format == JsonOutput)
  assert_true(options.compiler == Some("clang"))
}

///|
test "CLI rejects unknown commands" {
  let result = try parse_cli_options(["moonabi.exe", "unknown"]) catch {
    InvalidContract(value) => value
    _ => "unexpected"
  } noraise {
    _ => "unexpected success"
  }
  inspect(result, content="unknown command unknown")
}

///|
test "CLI parses import options" {
  let options = parse_cli_options([
    "moonabi.exe", "import", "--ast", "demo-ast.json", "--header", "demo.h", "--name",
    "demo-binding",
  ]) catch {
    _ => panic()
  }
  assert_true(options.command == Import)
  assert_true(options.ast_path == Some("demo-ast.json"))
  inspect(options.headers.length(), content="1")
  inspect(options.headers[0], content="demo.h")
  assert_true(options.project_name == Some("demo-binding"))
}
