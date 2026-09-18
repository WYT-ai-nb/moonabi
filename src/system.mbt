///|
#cfg(platform="windows")
priv struct OsCommand(String)

///|
#warnings("-unused_constructor")
#cfg(not(platform="windows"))
priv struct OsCommand(Bytes)

///|
#cfg(platform="windows")
fn OsCommand::from_string(value : String) -> OsCommand {
  OsCommand(value)
}

///|
#cfg(not(platform="windows"))
fn OsCommand::from_string(value : String) -> OsCommand {
  OsCommand(@unicode.to_utf8_bytes(value) + Bytes::make(1, (0).to_byte()))
}

///|
#cfg(target="native")
extern "C" fn is_windows_ffi() -> Bool = "moonabi_is_windows"

///|
#cfg(target="native")
#borrow(command)
extern "C" fn run_command_ffi(command : OsCommand) -> Int = "moonabi_run_command"

///|
#cfg(not(target="native"))
fn is_windows_ffi() -> Bool {
  false
}

///|
#cfg(not(target="native"))
fn run_command_ffi(command : OsCommand) -> Int {
  ignore(command)
  127
}

///|
pub fn is_windows() -> Bool {
  is_windows_ffi()
}

///|
pub fn run_command(command : String) -> Int {
  run_command_ffi(OsCommand::from_string(command))
}
