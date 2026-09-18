///|
pub fn effective_compiler(contract : AbiContract) -> String {
  if contract.compiler.trim() == "" {
    default_compiler()
  } else {
    contract.compiler
  }
}

///|
fn default_compiler() -> String {
  if is_windows() {
    "clang"
  } else {
    "cc"
  }
}

///|
pub fn generate_probe_source(contract : AbiContract) -> String {
  let mut out = ""
  out = out + "#include <stddef.h>\n"
  out = out + "#include <stdint.h>\n"
  out = out + "#include <stdio.h>\n"
  out = out + "\n"
  for header in contract.headers {
    out = out + "#include " + c_include(header) + "\n"
  }
  out = out + "\n"
  for i, symbol in contract.symbols {
    if symbol.convention.to_lower() == "system" {
      out = out + "#ifdef _WIN32\n"
      out = out +
        "static " +
        symbol.returns +
        " (__stdcall *moonabi_symbol_" +
        i.to_string() +
        ")(" +
        c_params(symbol.params) +
        ") = " +
        symbol.name +
        ";\n"
      out = out + "#else\n"
    }
    out = out +
      "static " +
      symbol.returns +
      " (*moonabi_symbol_" +
      i.to_string() +
      ")(" +
      c_params(symbol.params) +
      ") = " +
      symbol.name +
      ";\n"
    if symbol.convention.to_lower() == "system" {
      out = out + "#endif\n"
    }
  }
  out = out + "\n"
  out = out + "static const char *moonabi_target(void) {\n"
  out = out +
    "#if defined(_WIN32) && defined(_M_ARM64)\n  return \"windows-arm64\";\n"
  out = out +
    "#elif defined(_WIN32) && defined(_M_X64)\n  return \"windows-x86_64\";\n"
  out = out +
    "#elif defined(_WIN32) && defined(_M_IX86)\n  return \"windows-x86\";\n"
  out = out +
    "#elif defined(__APPLE__) && defined(__aarch64__)\n  return \"macos-arm64\";\n"
  out = out +
    "#elif defined(__APPLE__) && defined(__x86_64__)\n  return \"macos-x86_64\";\n"
  out = out +
    "#elif defined(__linux__) && defined(__aarch64__)\n  return \"linux-arm64\";\n"
  out = out +
    "#elif defined(__linux__) && defined(__x86_64__)\n  return \"linux-x86_64\";\n"
  out = out + "#else\n  return \"unknown\";\n#endif\n}\n\n"
  out = out + "static const char *moonabi_compiler(void) {\n"
  out = out + "#if defined(__clang__)\n  return \"clang\";\n"
  out = out + "#elif defined(__GNUC__)\n  return \"gcc\";\n"
  out = out + "#elif defined(_MSC_VER)\n  return \"msvc\";\n"
  out = out + "#else\n  return \"unknown\";\n#endif\n}\n\n"
  out = out + "int main(void) {\n"
  out = out +
    "  printf(\"{\\\"schema\\\":1,\\\"target\\\":\\\"%s\\\",\\\"compiler\\\":\\\"%s\\\",\", moonabi_target(), moonabi_compiler());\n"
  out = out +
    (
      #|  printf("\"types\":["); 
    )
  for i, item in contract.types {
    if i > 0 {
      out = out + "printf(\",\");\n"
    }
    out = out +
      "  printf(\"{\\\"name\\\":\\\"%s\\\",\\\"size\\\":\\\"%zu\\\",\\\"align\\\":\\\"%zu\\\",\\\"fields\\\":[\", \"" +
      c_string(item.name) +
      "\", sizeof(" +
      item.c_type +
      "), _Alignof(" +
      item.c_type +
      "));\n"
    for j, field in item.fields {
      if j > 0 {
        out = out + "  printf(\",\");\n"
      }
      out = out +
        "  printf(\"{\\\"name\\\":\\\"%s\\\",\\\"offset\\\":\\\"%zu\\\"}\", \"" +
        c_string(field.name) +
        "\", offsetof(" +
        item.c_type +
        ", " +
        field.name +
        "));\n"
    }
    out = out + "  printf(\"]}\");\n"
  }
  out = out +
    (
      #|  printf("],\"constants\":["); 
    )
  for i, item in contract.constants {
    if i > 0 {
      out = out + "printf(\",\");\n"
    }
    out = out +
      "  printf(\"{\\\"name\\\":\\\"%s\\\",\\\"value\\\":\\\"%lld\\\"}\", \"" +
      c_string(item.name) +
      "\", (long long)(" +
      item.name +
      "));\n"
  }
  out = out +
    (
      #|  printf("],\"symbols\":["); 
    )
  for i, item in contract.symbols {
    if i > 0 {
      out = out + "printf(\",\");\n"
    }
    out = out +
      "  (void)moonabi_symbol_" +
      i.to_string() +
      ";\n  printf(\"{\\\"name\\\":\\\"%s\\\",\\\"present\\\":true}\", \"" +
      c_string(item.name) +
      "\");\n"
  }
  out = out + "  printf(\"]}\\n\");\n  return 0;\n}\n"
  out
}

///|
pub fn compile_command(
  contract : AbiContract,
  source_path : String,
  output_path : String,
) -> String {
  let mut command = shell_quote(effective_compiler(contract))
  for argument in contract.compiler_args {
    command = command + " " + argument
  }
  for directory in contract.include_dirs {
    command = command + " -I" + shell_quote(directory)
  }
  command = command + " " + shell_quote(source_path)
  for source in contract.sources {
    command = command + " " + shell_quote(source)
  }
  for library in contract.libraries {
    command = command + " -l" + shell_quote(library)
  }
  command + " -o " + shell_quote(output_path)
}

///|
pub fn probe_run_command(output_path : String, json_path : String) -> String {
  shell_quote(output_path) + " > " + shell_quote(json_path)
}

///|
pub fn run_probe(
  contract : AbiContract,
  directory? : String = ".moonabi",
) -> AbiSnapshot raise {
  validate_contract(contract)
  if !@fs.path_exists(directory) {
    @fs.create_dir(directory)
  }
  let source_path = directory + "/probe.c"
  let output_path = directory + "/probe"
  let json_path = directory + "/probe.json"
  @fs.write_string_to_file(source_path, generate_probe_source(contract))
  let compile = compile_command(contract, source_path, output_path)
  let compile_code = run_command(compile)
  if compile_code != 0 {
    raise ProbeFailed(
      "C compiler exited with " +
      compile_code.to_string() +
      " using " +
      effective_compiler(contract),
    )
  }
  let run_code = run_command(probe_run_command(output_path, json_path))
  if run_code != 0 {
    raise CommandFailed(run_code)
  }
  parse_snapshot(@fs.read_file_to_string(json_path))
}

///|
fn c_params(params : Array[String]) -> String {
  if params.length() == 0 {
    "void"
  } else {
    let mut out = ""
    for i, item in params {
      if i > 0 {
        out = out + ", "
      }
      out = out + item
    }
    out
  }
}

///|
fn c_include(path : String) -> String {
  "\"" + c_string(path.replace(old="\\", new="/")) + "\""
}

///|
fn c_string(value : String) -> String {
  let mut out = ""
  for ch in value {
    if ch == '\\' {
      out = out + "\\\\"
    } else if ch == '"' {
      out = out + "\\\""
    } else if ch == '\n' {
      out = out + "\\n"
    } else if ch == '\r' {
      out = out + "\\r"
    } else if ch == '\t' {
      out = out + "\\t"
    } else {
      out = out + ch.to_string()
    }
  }
  out
}

///|
fn shell_quote(value : String) -> String {
  "\"" + value.replace(old="\"", new="\\\"") + "\""
}
