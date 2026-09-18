///|
priv struct ClangImportBuilder {
  headers : Array[String]
  types : Array[TypeContract]
  constants : Array[ConstantContract]
  symbols : Array[SymbolContract]
}

///|
pub fn import_clang_ast(
  text : String,
  name : String,
  headers : Array[String],
) -> AbiContract raise {
  let json = @json.parse(text)
  let builder : ClangImportBuilder = {
    headers,
    types: [],
    constants: [],
    symbols: [],
  }
  import_decl(builder, json)
  let contract : AbiContract = {
    schema: 1,
    name,
    headers,
    compiler: "",
    compiler_args: ["-std=c11"],
    include_dirs: ["."],
    sources: [],
    libraries: [],
    types: builder.types,
    constants: builder.constants,
    symbols: builder.symbols,
  }
  validate_contract(contract)
  contract
}

///|
fn import_decl(builder : ClangImportBuilder, json : Json) -> Unit {
  if json_bool_field(json, "isImplicit") == Some(true) {
    return
  }
  match json_string_field(json, "kind") {
    Some("RecordDecl") =>
      import_record(builder, json, None, json_location_file(json))
    Some("TypedefDecl") =>
      match json_string_field(json, "name") {
        Some(typedef_name) =>
          match json_array_field(json, "inner") {
            Some(children) =>
              for child in children {
                if json_string_field(child, "kind") == Some("RecordDecl") {
                  import_record(
                    builder,
                    child,
                    Some(typedef_name),
                    json_location_file(json),
                  )
                }
              }
            None => ()
          }
        None => ()
      }
    Some("EnumConstantDecl") =>
      if source_matches(builder.headers, json_location_file(json)) {
        match json_string_field(json, "name") {
          Some(name) => add_constant(builder, name)
          None => ()
        }
      }
    Some("FunctionDecl") =>
      if source_matches(builder.headers, json_location_file(json)) &&
        json_string_field(json, "storageClass") != Some("static") {
        import_function(builder, json)
      }
    _ => ()
  }
  match json_array_field(json, "inner") {
    Some(children) =>
      for child in children {
        import_decl(builder, child)
      }
    None => ()
  }
}

///|
fn import_record(
  builder : ClangImportBuilder,
  json : Json,
  typedef_name : String?,
  inherited_source : String?,
) -> Unit {
  if json_bool_field(json, "completeDefinition") != Some(true) {
    return
  }
  let source = match json_location_file(json) {
    Some(value) => Some(value)
    None => inherited_source
  }
  if !source_matches(builder.headers, source) {
    return
  }
  let type_name = match typedef_name {
    Some(value) => Some(value)
    None => json_string_field(json, "name")
  }
  match type_name {
    None => ()
    Some(type_name) => {
      if type_name == "" || contains_type(builder.types, type_name) {
        return
      }
      let fields : Array[FieldContract] = []
      match json_array_field(json, "inner") {
        Some(children) =>
          for child in children {
            if json_string_field(child, "kind") == Some("FieldDecl") &&
              json_bool_field(child, "isImplicit") != Some(true) {
              match json_string_field(child, "name") {
                Some(field_name) =>
                  if field_name != "" {
                    fields.push({ name: field_name, })
                  }
                None => ()
              }
            }
          }
        None => ()
      }
      builder.types.push({ name: type_name, c_type: type_name, fields, })
    }
  }
}

///|
fn import_function(builder : ClangImportBuilder, json : Json) -> Unit {
  match json_string_field(json, "name") {
    None => ()
    Some(name) =>
      match json_type_name(json, "type") {
        None => ()
        Some(type_text) => {
          if name == "" ||
            name.has_prefix("__") ||
            contains_symbol(builder.symbols, name) {
            return
          }
          let (returns, params) = split_function_type(type_text)
          builder.symbols.push({ name, returns, params, convention: "c", })
        }
      }
  }
}

///|
fn split_function_type(value : String) -> (String, Array[String]) {
  match value.split_once("(") {
    None => (value.trim().to_owned(), [])
    Some((returns, rest)) => {
      let params_text = match rest.split_once(")") {
        Some((params, _)) => params
        None => rest
      }
      let params = if params_text.trim() == "" || params_text.trim() == "void" {
        []
      } else {
        [
          for item in params_text.split(",") => item.trim().to_owned()
        ]
      }
      (returns.trim().to_owned(), params)
    }
  }
}

///|
fn add_constant(builder : ClangImportBuilder, name : String) -> Unit {
  if name == "" || contains_constant(builder.constants, name) {
    return
  }
  builder.constants.push({ name, })
}

///|
fn contains_type(items : Array[TypeContract], name : String) -> Bool {
  items.any(fn(item) { item.name == name })
}

///|
fn contains_constant(items : Array[ConstantContract], name : String) -> Bool {
  items.any(fn(item) { item.name == name })
}

///|
fn contains_symbol(items : Array[SymbolContract], name : String) -> Bool {
  items.any(fn(item) { item.name == name })
}

///|
fn source_matches(headers : Array[String], source : String?) -> Bool {
  match source {
    None => false
    Some(path) => {
      let normalized = path.replace(old="\\", new="/")
      headers.any(fn(header) {
        let expected = header.replace(old="\\", new="/")
        normalized == expected || normalized.has_suffix("/" + expected)
      })
    }
  }
}

///|
fn json_member(json : Json, key : String) -> Json? {
  match json {
    Object(members) => members.get(key)
    _ => None
  }
}

///|
fn json_string_field(json : Json, key : String) -> String? {
  match json_member(json, key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn json_bool_field(json : Json, key : String) -> Bool? {
  match json_member(json, key) {
    Some(True) => Some(true)
    Some(False) => Some(false)
    _ => None
  }
}

///|
fn json_array_field(json : Json, key : String) -> Array[Json]? {
  match json_member(json, key) {
    Some(Array(values)) => Some(values)
    _ => None
  }
}

///|
fn json_type_name(json : Json, key : String) -> String? {
  match json_member(json, key) {
    Some(value) => json_string_field(value, "qualType")
    None => None
  }
}

///|
fn json_location_file(json : Json) -> String? {
  match json_string_field(json, "file") {
    Some(value) => Some(value)
    None => {
      for key in ["loc", "spellingLoc", "expansionLoc", "includedFrom"] {
        match json_member(json, key) {
          Some(value) =>
            match json_location_file(value) {
              Some(file) => return Some(file)
              None => ()
            }
          None => ()
        }
      }
      None
    }
  }
}
