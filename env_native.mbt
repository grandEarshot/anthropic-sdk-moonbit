///|
fn getenv(name : String) -> String? {
  match @sys.get_env_var(name) {
    Some(value) => if value == "" { None } else { Some(value) }
    None => None
  }
}
