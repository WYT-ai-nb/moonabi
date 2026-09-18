///|
fn snapshot_fixture() -> AbiSnapshot {
  snapshot_with(size=16, flag=1, symbols=[
    { name: "demo_create", present: true, },
  ])
}

///|
fn snapshot_with(
  size~ : Int64,
  flag~ : Int64,
  symbols~ : Array[SymbolFact],
) -> AbiSnapshot {
  {
    schema: 1,
    target: "linux-x86_64",
    compiler: "clang",
    types: [
      {
        name: "demo_config",
        size,
        align: 8,
        fields: [
          { name: "flags", offset: 0, },
          { name: "timeout_ms", offset: size - 8, },
        ],
      },
    ],
    constants: [{ name: "DEMO_FLAG_COMPRESSED", value: flag, }],
    symbols,
  }
}

///|
test "identical snapshots pass" {
  let report = compare_snapshots(snapshot_fixture(), snapshot_fixture())
  inspect(report.status, content="passed")
  inspect(report.diagnostics.length(), content="0")
}

///|
test "field offset change is an error" {
  let actual = snapshot_with(size=24, flag=1, symbols=[
    { name: "demo_create", present: true, },
  ])
  let report = compare_snapshots(snapshot_fixture(), actual)
  inspect(report.status, content="failed")
  inspect(
    report.diagnostics.any(fn(item) {
      item.code == "ABI1104" &&
      item.subject == "demo_config.timeout_ms" &&
      item.expected == "8" &&
      item.actual == "16"
    }),
    content="true",
  )
}

///|
test "constant and symbol changes are reported" {
  let actual = snapshot_with(size=16, flag=2, symbols=[])
  let report = compare_snapshots(snapshot_fixture(), actual)
  inspect(report.status, content="failed")
  inspect(
    report.diagnostics.any(fn(item) { item.code == "ABI1201" }),
    content="true",
  )
  inspect(
    report.diagnostics.any(fn(item) { item.code == "ABI1300" }),
    content="true",
  )
}

///|
test "report formats include diagnostics" {
  let actual = snapshot_with(size=24, flag=1, symbols=[
    { name: "demo_create", present: true, },
  ])
  let report = compare_snapshots(snapshot_fixture(), actual)
  inspect(format_report_text(report).contains("ABI1101"), content="true")
  inspect(
    format_report_json(report).contains("\"status\": \"failed\""),
    content="true",
  )
  inspect(
    format_report_markdown(report).contains("MoonABI Check"),
    content="true",
  )
  inspect(
    format_report_sarif(report).contains("\"ruleId\": \"ABI1101\""),
    content="true",
  )
  let sarif = format_report_sarif(report)
  assert_true(@json.valid(sarif))
  let parsed = @json.parse(sarif) catch { _ => panic() }
  ignore(parsed)
}
