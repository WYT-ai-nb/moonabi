///|
fn main {
  let code = @moonabi.run_cli(@env.args())
  @sys.exit(code)
}
