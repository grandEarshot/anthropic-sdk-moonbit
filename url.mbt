///|
struct ParsedBaseUrl {
  origin : String
  prefix_path : String
} derive(Show)

///|
fn split_base_url(base_url : String) -> ParsedBaseUrl raise AnthropicError {
  let scheme_end = match base_url.find("://") {
    Some(index) => index
    None => raise InvalidBaseUrl("missing scheme in base_url `\{base_url}`")
  }
  let after_scheme = scheme_end + 3
  let slash = match base_url[after_scheme:].to_string().find("/") {
    Some(index) => index
    None => -1
  }
  if slash < 0 {
    return { origin: base_url, prefix_path: "" }
  }
  let absolute_slash = after_scheme + slash
  let origin = base_url[:absolute_slash].to_string()
  let prefix = base_url[absolute_slash:].to_string().trim_end(chars="/").to_string()
  { origin, prefix_path: if prefix == "/" { "" } else { prefix } }
}

///|
fn join_request_path(prefix_path : String, path : String, query? : String) -> String {
  let normalized_path = if path.has_prefix("/") { path } else { "/" + path }
  let full_path = if prefix_path == "" {
    normalized_path
  } else {
    prefix_path + normalized_path
  }
  match query {
    Some(query) if query != "" => full_path + "?" + query
    _ => full_path
  }
}
