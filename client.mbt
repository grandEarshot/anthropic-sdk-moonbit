///|
pub struct RequestOptions {
  headers : Map[String, String]?
  query : Map[String, String]?
  body : Json?
  timeout_ms : Int?
} derive(Show)

///|
pub struct ClientConfig {
  api_key : String?
  auth_token : String?
  base_url : String
  timeout_ms : Int
  max_retries : Int
  default_headers : Map[String, String]
  default_query : Map[String, String]
} derive(Show)

///|
pub struct Client {
  config : ClientConfig
  parsed_base_url : ParsedBaseUrl
} derive(Show)

///|
pub fn RequestOptions::new(
  headers? : Map[String, String],
  query? : Map[String, String],
  body? : Json,
  timeout_ms? : Int,
) -> RequestOptions {
  { headers, query, body, timeout_ms }
}

///|
pub fn Client::new(
  api_key? : String,
  auth_token? : String,
  base_url? : String = DEFAULT_BASE_URL,
  timeout_ms? : Int = DEFAULT_TIMEOUT_MS,
  max_retries? : Int = DEFAULT_MAX_RETRIES,
  default_headers? : Map[String, String] = {},
  default_query? : Map[String, String] = {},
) -> Client raise AnthropicError {
  let config = {
    api_key,
    auth_token,
    base_url,
    timeout_ms,
    max_retries,
    default_headers,
    default_query,
  }
  Client::{ config, parsed_base_url: split_base_url(base_url) }
}

///|
pub fn Client::from_env(
  base_url? : String = DEFAULT_BASE_URL,
  timeout_ms? : Int = DEFAULT_TIMEOUT_MS,
  max_retries? : Int = DEFAULT_MAX_RETRIES,
  default_headers? : Map[String, String] = {},
  default_query? : Map[String, String] = {},
) -> Client raise AnthropicError {
  let resolved_base_url = match getenv("ANTHROPIC_BASE_URL") {
    Some(url) => url
    None => base_url
  }
  let config = {
    api_key: getenv("ANTHROPIC_API_KEY"),
    auth_token: getenv("ANTHROPIC_AUTH_TOKEN"),
    base_url: resolved_base_url,
    timeout_ms,
    max_retries,
    default_headers,
    default_query,
  }
  { config, parsed_base_url: split_base_url(resolved_base_url) }
}

///|
fn Client::resolved_timeout_ms(
  self : Client,
  options : RequestOptions?,
) -> Int {
  match options {
    Some(options) => match options.timeout_ms {
      Some(timeout_ms) => timeout_ms
      None => self.config.timeout_ms
    }
    None => self.config.timeout_ms
  }
}

///|
fn Client::resolve_headers(
  self : Client,
  extra_headers : Map[String, String]?,
) -> Map[String, String] raise AnthropicError {
  let headers = self.config.default_headers.copy()
  headers["anthropic-version"] = DEFAULT_ANTHROPIC_VERSION
  headers["X-Stainless-Async"] = "async:moonbit"
  if self.config.api_key is Some(api_key) {
    headers["X-Api-Key"] = api_key
  }
  if self.config.auth_token is Some(auth_token) {
    headers["Authorization"] = "Bearer \{auth_token}"
  }
  if !headers.contains("X-Api-Key") && !headers.contains("Authorization") {
    raise MissingAuthentication
  }
  if extra_headers is Some(extra_headers) {
    for key, value in extra_headers {
      headers[key] = value
    }
  }
  headers
}

///|
fn Client::resolve_query(
  self : Client,
  extra_query : Map[String, String]?,
) -> Map[String, String] {
  let query = self.config.default_query.copy()
  if extra_query is Some(extra_query) {
    for key, value in extra_query {
      query[key] = value
    }
  }
  query
}

///|
fn encode_query(query : Map[String, String]) -> String {
  if query.is_empty() {
    return ""
  }
  let entries = []
  for key, value in query {
    entries.push("\{key}=\{value}")
  }
  entries.sort()
  entries.join("&")
}
