///|
test "probe source contains layout checks" {
  let contract = parse_contract(default_contract_text()) catch { _ => panic() }
  let source = generate_probe_source(contract)
  inspect(source.contains("sizeof(demo_config)"), content="true")
  inspect(source.contains("_Alignof(demo_config)"), content="true")
  inspect(source.contains("offsetof(demo_config, flags)"), content="true")
  inspect(source.contains("\\\"size\\\":\\\"%zu\\\""), content="true")
  inspect(source.contains("\\\"offset\\\":\\\"%zu\\\""), content="true")
  inspect(source.contains("(long long)(DEMO_FLAG_COMPRESSED)"), content="true")
  inspect(
    source.contains(
      "static demo_handle * (*moonabi_symbol_0)(const demo_config *) = demo_create;",
    ),
    content="true",
  )
}

///|
test "compile command contains include and output paths" {
  let contract = parse_contract(default_contract_text()) catch { _ => panic() }
  let command = compile_command(contract, ".moonabi/probe.c", ".moonabi/probe")
  inspect(command.contains("-std=c11"), content="true")
  inspect(command.contains("-I\".\""), content="true")
  inspect(command.contains("\".moonabi/probe.c\""), content="true")
  inspect(command.contains("\".moonabi/probe\""), content="true")
}
