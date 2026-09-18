///|
pub fn compare_snapshots(
  expected : AbiSnapshot,
  actual : AbiSnapshot,
) -> CheckReport {
  let diagnostics : Array[Diagnostic] = []
  if expected.target != actual.target {
    diagnostics.push(
      diagnostic(
        "ABI1000",
        "warning",
        "target",
        "the ABI lock was created for a different target",
        expected.target,
        actual.target,
      ),
    )
  }
  if expected.compiler != actual.compiler {
    diagnostics.push(
      diagnostic(
        "ABI1001",
        "warning",
        "compiler",
        "the ABI lock was created with a different compiler family",
        expected.compiler,
        actual.compiler,
      ),
    )
  }
  compare_types(expected.types, actual.types, diagnostics)
  compare_constants(expected.constants, actual.constants, diagnostics)
  compare_symbols(expected.symbols, actual.symbols, diagnostics)
  check_report(expected_name(expected), diagnostics)
}

///|
pub fn compare_contract_snapshots(
  contract : AbiContract,
  expected : AbiSnapshot,
  actual : AbiSnapshot,
) -> CheckReport {
  let report = compare_snapshots(expected, actual)
  { ..report, contract: contract.name, }
}

///|
fn expected_name(snapshot : AbiSnapshot) -> String {
  if snapshot.target == "unknown" {
    "moonabi"
  } else {
    "moonabi@" + snapshot.target
  }
}

///|
fn compare_types(
  expected : Array[TypeFact],
  actual : Array[TypeFact],
  diagnostics : Array[Diagnostic],
) -> Unit {
  for item in expected {
    match find_type(actual, item.name) {
      None =>
        diagnostics.push(
          diagnostic(
            "ABI1100",
            "error",
            item.name,
            "type is missing from the current probe",
            "present",
            "missing",
          ),
        )
      Some(current) => {
        if item.size != current.size {
          diagnostics.push(
            diagnostic(
              "ABI1101",
              "error",
              item.name,
              "type size changed",
              item.size.to_string(),
              current.size.to_string(),
            ),
          )
        }
        if item.align != current.align {
          diagnostics.push(
            diagnostic(
              "ABI1102",
              "error",
              item.name,
              "type alignment changed",
              item.align.to_string(),
              current.align.to_string(),
            ),
          )
        }
        for field in item.fields {
          match find_field(current.fields, field.name) {
            None =>
              diagnostics.push(
                diagnostic(
                  "ABI1103",
                  "error",
                  item.name + "." + field.name,
                  "field is missing from the current probe",
                  "present",
                  "missing",
                ),
              )
            Some(actual_field) =>
              if field.offset != actual_field.offset {
                diagnostics.push(
                  diagnostic(
                    "ABI1104",
                    "error",
                    item.name + "." + field.name,
                    "field offset changed",
                    field.offset.to_string(),
                    actual_field.offset.to_string(),
                  ),
                )
              }
          }
        }
      }
    }
  }
  for item in actual {
    if find_type(expected, item.name) is None {
      diagnostics.push(
        diagnostic(
          "ABI1190",
          "warning",
          item.name,
          "new type is not present in the ABI lock",
          "missing",
          "present",
        ),
      )
    }
  }
}

///|
fn compare_constants(
  expected : Array[ConstantFact],
  actual : Array[ConstantFact],
  diagnostics : Array[Diagnostic],
) -> Unit {
  for item in expected {
    match find_constant(actual, item.name) {
      None =>
        diagnostics.push(
          diagnostic(
            "ABI1200",
            "error",
            item.name,
            "constant is missing from the current probe",
            "present",
            "missing",
          ),
        )
      Some(current) =>
        if item.value != current.value {
          diagnostics.push(
            diagnostic(
              "ABI1201",
              "error",
              item.name,
              "constant value changed",
              item.value.to_string(),
              current.value.to_string(),
            ),
          )
        }
    }
  }
  for item in actual {
    if find_constant(expected, item.name) is None {
      diagnostics.push(
        diagnostic(
          "ABI1290",
          "warning",
          item.name,
          "new constant is not present in the ABI lock",
          "missing",
          "present",
        ),
      )
    }
  }
}

///|
fn compare_symbols(
  expected : Array[SymbolFact],
  actual : Array[SymbolFact],
  diagnostics : Array[Diagnostic],
) -> Unit {
  for item in expected {
    match find_symbol(actual, item.name) {
      None =>
        diagnostics.push(
          diagnostic(
            "ABI1300",
            "error",
            item.name,
            "symbol is missing from the current probe",
            "present",
            "missing",
          ),
        )
      Some(current) =>
        if item.present != current.present {
          diagnostics.push(
            diagnostic(
              "ABI1301",
              "error",
              item.name,
              "symbol presence changed",
              item.present.to_string(),
              current.present.to_string(),
            ),
          )
        }
    }
  }
  for item in actual {
    if find_symbol(expected, item.name) is None {
      diagnostics.push(
        diagnostic(
          "ABI1390",
          "warning",
          item.name,
          "new symbol is not present in the ABI lock",
          "missing",
          "present",
        ),
      )
    }
  }
}

///|
fn find_type(items : Array[TypeFact], name : String) -> TypeFact? {
  for item in items {
    if item.name == name {
      return Some(item)
    }
  }
  None
}

///|
fn find_field(items : Array[FieldFact], name : String) -> FieldFact? {
  for item in items {
    if item.name == name {
      return Some(item)
    }
  }
  None
}

///|
fn find_constant(items : Array[ConstantFact], name : String) -> ConstantFact? {
  for item in items {
    if item.name == name {
      return Some(item)
    }
  }
  None
}

///|
fn find_symbol(items : Array[SymbolFact], name : String) -> SymbolFact? {
  for item in items {
    if item.name == name {
      return Some(item)
    }
  }
  None
}

///|
pub fn format_report_json(report : CheckReport) -> String {
  @json.to_json(report).stringify(indent=2)
}

///|
pub fn format_report_text(report : CheckReport) -> String {
  let mut out = "MoonABI Check\n"
  out = out + "Status: " + report.status + "\n"
  out = out + "Diagnostics: " + report.diagnostics.length().to_string() + "\n"
  if report.diagnostics.length() == 0 {
    out + "No ABI changes detected.\n"
  } else {
    out = out + "\n"
    for item in report.diagnostics {
      out = out +
        "[" +
        item.severity +
        "] " +
        item.code +
        " " +
        item.subject +
        ": " +
        item.message +
        " (expected " +
        item.expected +
        ", actual " +
        item.actual +
        ")\n"
    }
    out
  }
}

///|
pub fn format_report_markdown(report : CheckReport) -> String {
  let mut out = "# MoonABI Check\n\n"
  out = out + "- Contract: `" + report.contract + "`\n"
  out = out + "- Status: **" + report.status + "**\n"
  out = out +
    "- Diagnostics: **" +
    report.diagnostics.length().to_string() +
    "**\n"
  if report.diagnostics.length() > 0 {
    out = out + "\n| Severity | Code | Subject | Expected | Actual |\n"
    out = out + "| --- | --- | --- | --- | --- |\n"
    for item in report.diagnostics {
      out = out +
        "| " +
        item.severity +
        " | `" +
        item.code +
        "` | `" +
        item.subject +
        "` | `" +
        item.expected +
        "` | `" +
        item.actual +
        "` |\n"
    }
  }
  out
}

///|
pub fn format_report_sarif(report : CheckReport) -> String {
  let mut out = "{\n"
  out = out +
    "  \"$schema\": \"https://json.schemastore.org/sarif-2.1.0.json\",\n"
  out = out + "  \"version\": \"2.1.0\",\n"
  out = out + "  \"runs\": [\n    {\n"
  out = out + "      \"tool\": {\n        \"driver\": {\n"
  out = out + "          \"name\": \"MoonABI\",\n"
  out = out + "          \"version\": \"0.1.0\",\n"
  out = out + "          \"rules\": ["
  for i, item in report.diagnostics {
    if i > 0 {
      out = out + ","
    }
    out = out +
      "\n            {\"id\": " +
      json_quote(item.code) +
      ", \"shortDescription\": {\"text\": " +
      json_quote(item.message) +
      "}}"
  }
  if report.diagnostics.length() > 0 {
    out = out + "\n          ]\n"
  } else {
    out = out + "]\n"
  }
  out = out + "        }\n      },\n"
  out = out + "      \"results\": ["
  for i, item in report.diagnostics {
    if i > 0 {
      out = out + ","
    }
    out = out + "\n        {\n"
    out = out + "          \"ruleId\": " + json_quote(item.code) + ",\n"
    out = out +
      "          \"level\": " +
      json_quote(sarif_level(item.severity)) +
      ",\n"
    out = out +
      "          \"message\": {\"text\": " +
      json_quote(item.subject + ": " + item.message) +
      "},\n"
    out = out +
      "          \"locations\": [{\"physicalLocation\": {\"artifactLocation\": {\"uri\": \"moonabi.json\"}, \"region\": {\"startLine\": 1}}}]\n"
    out = out + "        }"
  }
  if report.diagnostics.length() > 0 {
    out = out + "\n      ]\n"
  } else {
    out = out + "]\n"
  }
  out = out + "    }\n  ]\n}\n"
  out
}

///|
fn sarif_level(severity : String) -> String {
  if severity == "error" {
    "error"
  } else {
    "warning"
  }
}

///|
fn json_quote(value : String) -> String {
  @json.to_json(value).stringify()
}
