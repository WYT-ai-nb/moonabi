///|
pub fn default_contract_text() -> String {
  (
    #|{
    #|  "schema": 1,
    #|  "name": "demo-native-binding",
    #|  "headers": [
    #|    "include/demo.h"
    #|  ],
    #|  "compiler": "",
    #|  "compiler_args": [
    #|    "-std=c11"
    #|  ],
    #|  "include_dirs": [
    #|    "."
    #|  ],
    #|  "sources": [],
    #|  "libraries": [],
    #|  "types": [
    #|    {
    #|      "name": "demo_config",
    #|      "c_type": "demo_config",
    #|      "fields": [
    #|        {
    #|          "name": "flags"
    #|        },
    #|        {
    #|          "name": "timeout_ms"
    #|        }
    #|      ]
    #|    }
    #|  ],
    #|  "constants": [
    #|    {
    #|      "name": "DEMO_FLAG_COMPRESSED"
    #|    }
    #|  ],
    #|  "symbols": [
    #|    {
    #|      "name": "demo_create",
    #|      "returns": "demo_handle *",
    #|      "params": [
    #|        "const demo_config *"
    #|      ],
    #|      "convention": "c"
    #|    }
    #|  ]
    #|}
  )
}

///|
pub fn empty_snapshot() -> AbiSnapshot {
  {
    schema: 1,
    target: "unknown",
    compiler: "unknown",
    types: [],
    constants: [],
    symbols: [],
  }
}

///|
pub fn parse_contract(text : String) -> AbiContract raise MoonAbiError {
  let json = try @json.parse(text) catch {
    error => raise InvalidContract(error.to_string())
  } noraise {
    value => value
  }
  let contract : AbiContract = try @json.from_json(json) catch {
    error => raise InvalidContract(error.to_string())
  } noraise {
    value => value
  }
  validate_contract(contract)
  contract
}

///|
pub fn parse_snapshot(text : String) -> AbiSnapshot raise {
  let json = @json.parse(text)
  let snapshot : AbiSnapshot = @json.from_json(json)
  snapshot
}

///|
pub fn contract_to_json(contract : AbiContract) -> String {
  @json.to_json(contract).stringify(indent=2)
}

///|
pub fn snapshot_to_json(snapshot : AbiSnapshot) -> String {
  @json.to_json(snapshot).stringify(indent=2)
}

///|
pub fn load_contract(path : String) -> AbiContract raise {
  parse_contract(@fs.read_file_to_string(path))
}

///|
pub fn load_snapshot(path : String) -> AbiSnapshot raise {
  if !@fs.path_exists(path) {
    raise MissingLockFile(path)
  }
  parse_snapshot(@fs.read_file_to_string(path))
}

///|
pub fn save_contract(path : String, contract : AbiContract) -> Unit raise {
  @fs.write_string_to_file(path, contract_to_json(contract) + "\n")
}

///|
pub fn save_snapshot(path : String, snapshot : AbiSnapshot) -> Unit raise {
  @fs.write_string_to_file(path, snapshot_to_json(snapshot) + "\n")
}

///|
pub fn validate_contract(contract : AbiContract) -> Unit raise MoonAbiError {
  if contract.schema != 1 {
    raise InvalidContract(
      "unsupported schema version " + contract.schema.to_string(),
    )
  }
  if contract.name.trim() == "" {
    raise InvalidContract("name must not be empty")
  }
  if contract.headers.length() == 0 {
    raise InvalidContract("at least one C header is required")
  }
  for header in contract.headers {
    if header.trim() == "" {
      raise InvalidContract("header paths must not be empty")
    }
  }
  for item in contract.types {
    require_identifier(item.name)
    require_c_type(item.c_type)
    let fields : Set[String] = Set([])
    for field in item.fields {
      require_identifier(field.name)
      if fields.contains(field.name) {
        raise InvalidContract("duplicate field " + item.name + "." + field.name)
      }
      fields.add(field.name)
    }
  }
  for item in contract.constants {
    require_identifier(item.name)
  }
  for item in contract.symbols {
    require_identifier(item.name)
    if item.returns.trim() == "" {
      raise InvalidContract("return type must not be empty for " + item.name)
    }
    for param in item.params {
      if param.trim() == "" {
        raise InvalidContract(
          "parameter type must not be empty for " + item.name,
        )
      }
    }
    let convention = item.convention.to_lower()
    if convention != "c" && convention != "system" {
      raise InvalidContract(
        "unsupported calling convention for " +
        item.name +
        ": " +
        item.convention,
      )
    }
  }
}

///|
fn require_identifier(value : String) -> Unit raise MoonAbiError {
  if value.length() == 0 {
    raise InvalidIdentifier(value)
  }
  for i, ch in value {
    let valid = if i == 0 {
      is_identifier_start(ch)
    } else {
      is_identifier_continue(ch)
    }
    if !valid {
      raise InvalidIdentifier(value)
    }
  }
}

///|
fn require_c_type(value : String) -> Unit raise MoonAbiError {
  let trimmed = value.trim()
  if trimmed == "" {
    raise InvalidContract("C type must not be empty")
  }
  for ch in trimmed {
    if ch == '\n' ||
      ch == '\r' ||
      ch == ';' ||
      ch == '(' ||
      ch == ')' ||
      ch == '{' ||
      ch == '}' ||
      ch == '[' ||
      ch == ']' ||
      ch == '#' {
      raise InvalidContract("unsafe C type: " + value)
    }
  }
}

///|
fn is_identifier_start(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

///|
fn is_identifier_continue(ch : Char) -> Bool {
  is_identifier_start(ch) || (ch >= '0' && ch <= '9')
}
