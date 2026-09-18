///|
pub struct AbiContract {
  schema : Int
  name : String
  headers : Array[String]
  compiler : String
  compiler_args : Array[String]
  include_dirs : Array[String]
  sources : Array[String]
  libraries : Array[String]
  types : Array[TypeContract]
  constants : Array[ConstantContract]
  symbols : Array[SymbolContract]
} derive(ToJson, FromJson, Eq)

///|
pub struct TypeContract {
  name : String
  c_type : String
  fields : Array[FieldContract]
} derive(ToJson, FromJson, Eq)

///|
pub struct FieldContract {
  name : String
} derive(ToJson, FromJson, Eq)

///|
pub struct ConstantContract {
  name : String
} derive(ToJson, FromJson, Eq)

///|
pub struct SymbolContract {
  name : String
  returns : String
  params : Array[String]
  convention : String
} derive(ToJson, FromJson, Eq)

///|
pub struct AbiSnapshot {
  schema : Int
  target : String
  compiler : String
  types : Array[TypeFact]
  constants : Array[ConstantFact]
  symbols : Array[SymbolFact]
} derive(ToJson, FromJson, Eq)

///|
pub struct TypeFact {
  name : String
  size : Int64
  align : Int64
  fields : Array[FieldFact]
} derive(ToJson, FromJson, Eq)

///|
pub struct FieldFact {
  name : String
  offset : Int64
} derive(ToJson, FromJson, Eq)

///|
pub struct ConstantFact {
  name : String
  value : Int64
} derive(ToJson, FromJson, Eq)

///|
pub struct SymbolFact {
  name : String
  present : Bool
} derive(ToJson, FromJson, Eq)

///|
pub struct Diagnostic {
  code : String
  severity : String
  subject : String
  message : String
  expected : String
  actual : String
} derive(ToJson, FromJson, Eq)

///|
pub struct CheckReport {
  schema : Int
  contract : String
  status : String
  diagnostics : Array[Diagnostic]
} derive(ToJson, FromJson, Eq)

///|
pub fn diagnostic(
  code : String,
  severity : String,
  subject : String,
  message : String,
  expected : String,
  actual : String,
) -> Diagnostic {
  { code, severity, subject, message, expected, actual, }
}

///|
pub fn check_report(
  contract_name : String,
  diagnostics : Array[Diagnostic],
) -> CheckReport {
  let status = if diagnostics.any(fn(item) { item.severity == "error" }) {
    "failed"
  } else {
    "passed"
  }
  { schema: 1, contract: contract_name, status, diagnostics, }
}
