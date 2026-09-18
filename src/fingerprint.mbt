///|
pub fn fnv1a64(value : String) -> UInt64 {
  let mut hash = 0xCBF29CE484222325UL
  for byte in @unicode.to_utf8_bytes(value) {
    hash = (hash ^ byte.to_uint64()) * 0x100000001B3UL
  }
  hash
}

///|
pub fn fingerprint_text(value : String) -> String {
  "fnv1a64:" + fnv1a64(value).to_string()
}

///|
pub fn contract_fingerprint(contract : AbiContract) -> String {
  fingerprint_text(contract_to_json(contract))
}

///|
pub fn snapshot_fingerprint(snapshot : AbiSnapshot) -> String {
  fingerprint_text(snapshot_to_json(snapshot))
}
