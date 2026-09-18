///|
pub enum CliCommand {
  Init
  Generate
  Import
  Inspect
  Check
  Report
  Help
  Version
} derive(Eq)

///|
pub enum CliFormat {
  TextOutput
  JsonOutput
  MarkdownOutput
  SarifOutput
} derive(Eq)

///|
pub struct CliOptions {
  command : CliCommand
  config_path : String
  lock_path : String
  format : CliFormat
  output_path : String?
  compiler : String?
  ast_path : String?
  headers : Array[String]
  project_name : String?
  force : Bool
  quiet : Bool
} derive(Eq)

///|
fn default_cli_options() -> CliOptions {
  {
    command: Help,
    config_path: "moonabi.json",
    lock_path: "moonabi.lock",
    format: TextOutput,
    output_path: None,
    compiler: None,
    ast_path: None,
    headers: [],
    project_name: None,
    force: false,
    quiet: false,
  }
}

///|
pub fn format_cli_help() -> String {
  (
    #|MoonABI - C ABI contract verification for MoonBit
    #|
    #|Usage:
    #|  moon run cmd/main -- <COMMAND> [OPTIONS]
    #|
    #|Commands:
    #|  init       Write a starter moonabi.json
    #|  generate   Generate the C ABI probe without compiling it
    #|  import     Import a contract from Clang AST JSON
    #|  inspect    Probe the C ABI and write moonabi.lock
    #|  check      Probe the current ABI and compare it with moonabi.lock
    #|  report     Render the current ABI lock
    #|  version    Print the MoonABI version
    #|  help       Show this help
    #|
    #|Options:
    #|  --config PATH    Contract path (default: moonabi.json)
    #|  --lock PATH      Lock path (default: moonabi.lock)
    #|  --format NAME    text, json, markdown, or sarif
    #|  --output PATH    Write the rendered output to a file
    #|  --cc NAME        Override the C compiler
    #|  --ast PATH       Clang AST JSON input for import
    #|  --header NAME    Header to include during import; repeatable
    #|  --name NAME      Contract name for import
    #|  --force          Overwrite an existing contract during init
    #|  --quiet          Do not print output to stdout
  )
}

///|
pub fn parse_cli_options(args : Array[String]) -> CliOptions raise MoonAbiError {
  let mut options = default_cli_options()
  let mut index = 0
  if args.length() > 0 &&
    !args[0].has_prefix("-") &&
    (args[0].has_suffix(".exe") || args[0].has_suffix(".wasm")) {
    index = 1
  }
  if index < args.length() && !args[index].has_prefix("-") {
    options = { ..options, command: parse_command(args[index]), }
    index = index + 1
  }
  while index < args.length() {
    let argument = args[index]
    if argument == "--config" {
      options = { ..options, config_path: option_value(args, index, argument), }
      index = index + 2
    } else if argument == "--lock" {
      options = { ..options, lock_path: option_value(args, index, argument), }
      index = index + 2
    } else if argument == "--format" {
      options = {
        ..options,
        format: parse_format(option_value(args, index, argument)),
      }
      index = index + 2
    } else if argument == "--output" || argument == "-o" {
      options = {
        ..options,
        output_path: Some(option_value(args, index, argument)),
      }
      index = index + 2
    } else if argument == "--cc" {
      options = {
        ..options,
        compiler: Some(option_value(args, index, argument)),
      }
      index = index + 2
    } else if argument == "--ast" {
      options = {
        ..options,
        ast_path: Some(option_value(args, index, argument)),
      }
      index = index + 2
    } else if argument == "--header" {
      options.headers.push(option_value(args, index, argument))
      index = index + 2
    } else if argument == "--name" {
      options = {
        ..options,
        project_name: Some(option_value(args, index, argument)),
      }
      index = index + 2
    } else if argument == "--force" {
      options = { ..options, force: true, }
      index = index + 1
    } else if argument == "--quiet" || argument == "-q" {
      options = { ..options, quiet: true, }
      index = index + 1
    } else if argument == "--help" || argument == "-h" {
      options = { ..options, command: Help, }
      index = index + 1
    } else {
      raise InvalidContract("unknown option " + argument)
    }
  }
  options
}

///|
fn parse_command(value : String) -> CliCommand raise MoonAbiError {
  match value.to_lower() {
    "init" => Init
    "generate" => Generate
    "import" => Import
    "inspect" => Inspect
    "check" => Check
    "report" => Report
    "version" => Version
    "help" => Help
    _ => raise InvalidContract("unknown command " + value)
  }
}

///|
fn parse_format(value : String) -> CliFormat raise MoonAbiError {
  match value.to_lower() {
    "text" | "txt" => TextOutput
    "json" => JsonOutput
    "markdown" | "md" => MarkdownOutput
    "sarif" => SarifOutput
    _ => raise InvalidContract("unknown output format " + value)
  }
}

///|
fn option_value(
  args : Array[String],
  index : Int,
  option : String,
) -> String raise MoonAbiError {
  if index + 1 >= args.length() {
    raise InvalidContract("missing value for " + option)
  }
  args[index + 1]
}

///|
fn with_compiler(contract : AbiContract, compiler : String?) -> AbiContract {
  match compiler {
    None => contract
    Some(value) => { ..contract, compiler: value, }
  }
}

///|
fn emit(options : CliOptions, content : String) -> Unit raise {
  match options.output_path {
    Some(path) => @fs.write_string_to_file(path, content)
    None => ()
  }
  if !options.quiet {
    println(content)
  }
}

///|
fn render_snapshot(snapshot : AbiSnapshot, format : CliFormat) -> String {
  match format {
    JsonOutput => snapshot_to_json(snapshot) + "\n"
    SarifOutput => snapshot_to_json(snapshot) + "\n"
    MarkdownOutput =>
      "# MoonABI Snapshot\n\n" +
      "- Target: `" +
      snapshot.target +
      "`\n- Compiler: `" +
      snapshot.compiler +
      "`\n- Fingerprint: `" +
      snapshot_fingerprint(snapshot) +
      "`\n- Types: **" +
      snapshot.types.length().to_string() +
      "**\n- Constants: **" +
      snapshot.constants.length().to_string() +
      "**\n- Symbols: **" +
      snapshot.symbols.length().to_string() +
      "**\n"
    TextOutput =>
      "MoonABI Snapshot\n" +
      "Target: " +
      snapshot.target +
      "\nCompiler: " +
      snapshot.compiler +
      "\nFingerprint: " +
      snapshot_fingerprint(snapshot) +
      "\nTypes: " +
      snapshot.types.length().to_string() +
      "\nConstants: " +
      snapshot.constants.length().to_string() +
      "\nSymbols: " +
      snapshot.symbols.length().to_string() +
      "\n"
  }
}

///|
fn render_report(report : CheckReport, format : CliFormat) -> String {
  match format {
    JsonOutput => format_report_json(report) + "\n"
    MarkdownOutput => format_report_markdown(report)
    SarifOutput => format_report_sarif(report)
    TextOutput => format_report_text(report)
  }
}

///|
pub fn run_cli(args : Array[String]) -> Int {
  let options = parse_cli_options(args) catch {
    error => {
      println("error: " + error_text(error))
      println(format_cli_help())
      return 2
    }
  }
  match options.command {
    Help => {
      println(format_cli_help())
      0
    }
    Version => {
      println("MoonABI 0.1.0")
      0
    }
    Init => {
      if @fs.path_exists(options.config_path) && !options.force {
        println("error: " + options.config_path + " already exists")
        return 2
      }
      @fs.write_string_to_file(options.config_path, default_contract_text()) catch {
        @fs.IOError(message) => {
          println("error: " + message)
          return 2
        }
      }
      println("wrote " + options.config_path)
      0
    }
    Generate => {
      let contract = load_contract(options.config_path) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      let contract = with_compiler(contract, options.compiler)
      let source = generate_probe_source(contract)
      emit(options, source) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      0
    }
    Import => {
      let ast_path = match options.ast_path {
        Some(value) => value
        None => {
          println("error: --ast is required for import")
          return 2
        }
      }
      if options.headers.length() == 0 {
        println("error: at least one --header is required for import")
        return 2
      }
      let name = match options.project_name {
        Some(value) => value
        None => "imported-binding"
      }
      let text = @fs.read_file_to_string(ast_path) catch {
        @fs.IOError(message) => {
          println("error: " + message)
          return 2
        }
      }
      let contract = import_clang_ast(text, name, options.headers) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      save_contract(options.config_path, contract) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      emit(options, contract_to_json(contract) + "\n") catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      0
    }
    Inspect => {
      let contract = load_contract(options.config_path) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      let contract = with_compiler(contract, options.compiler)
      let snapshot = run_probe(contract) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      save_snapshot(options.lock_path, snapshot) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      emit(options, render_snapshot(snapshot, options.format)) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      0
    }
    Check => {
      let contract = load_contract(options.config_path) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      let contract = with_compiler(contract, options.compiler)
      let expected = load_snapshot(options.lock_path) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      let actual = run_probe(contract) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      let report = compare_contract_snapshots(contract, expected, actual)
      emit(options, render_report(report, options.format)) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      if report.status == "failed" {
        1
      } else {
        0
      }
    }
    Report => {
      let snapshot = load_snapshot(options.lock_path) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      emit(options, render_snapshot(snapshot, options.format)) catch {
        error => {
          println("error: " + error.to_string())
          return 2
        }
      }
      0
    }
  }
}
