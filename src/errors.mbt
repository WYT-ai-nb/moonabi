///|
pub suberror MoonAbiError {
  InvalidContract(String)
  InvalidIdentifier(String)
  ProbeFailed(String)
  MissingLockFile(String)
  CommandFailed(Int)
} derive(Eq)

///|
pub fn error_text(error : MoonAbiError) -> String {
  match error {
    InvalidContract(message) => "invalid contract: " + message
    InvalidIdentifier(value) => "invalid C identifier: " + value
    ProbeFailed(message) => "ABI probe failed: " + message
    MissingLockFile(path) => "ABI lock file not found: " + path
    CommandFailed(code) => "command failed with exit code " + code.to_string()
  }
}
