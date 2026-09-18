///|
test "default contract parses and validates" {
  let contract = parse_contract(default_contract_text()) catch {
    InvalidContract(message) => {
      println("parse error: " + message)
      panic()
    }
    _ => panic()
  }
  inspect(contract.schema, content="1")
  inspect(contract.name, content="demo-native-binding")
  inspect(contract.types.length(), content="1")
  inspect(contract.constants.length(), content="1")
  inspect(contract.symbols.length(), content="1")
}

///|
test "contract JSON round trips" {
  let contract = parse_contract(default_contract_text()) catch { _ => panic() }
  let parsed = parse_contract(contract_to_json(contract)) catch { _ => panic() }
  assert_true(parsed == contract)
}

///|
test "invalid C identifier is rejected" {
  let contract = parse_contract(default_contract_text()) catch { _ => panic() }
  let contract = {
    ..contract,
    types: [{ name: "bad-name", c_type: "bad_type", fields: [], }],
  }
  let result = try validate_contract(contract) catch {
    InvalidIdentifier(value) => value
    _ => "unexpected"
  } noraise {
    _ => "unexpected success"
  }
  inspect(result, content="bad-name")
}

///|
test "method calls are rejected in type names" {
  let contract = parse_contract(default_contract_text()) catch { _ => panic() }
  let contract = {
    ..contract,
    types: [{ name: "config", c_type: "config()", fields: [], }],
  }
  let result = try validate_contract(contract) catch {
    InvalidContract(value) => value
    _ => "unexpected"
  } noraise {
    _ => "unexpected success"
  }
  inspect(result, content="unsafe C type: config()")
}
