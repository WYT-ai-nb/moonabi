///|
test "fingerprints are deterministic" {
  let contract = parse_contract(default_contract_text()) catch { _ => panic() }
  let first = contract_fingerprint(contract)
  let second = contract_fingerprint(contract)
  inspect(first, content=second)
  assert_true(first.has_prefix("fnv1a64:"))
}

///|
test "different snapshots have different fingerprints" {
  let first = {
    schema: 1,
    target: "linux-x86_64",
    compiler: "clang",
    types: [],
    constants: [],
    symbols: [],
  }
  let second = { ..first, target: "windows-x86_64", }
  assert_true(snapshot_fingerprint(first) != snapshot_fingerprint(second))
}
