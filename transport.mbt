///|
pub struct RawResponse {
  status : Int
  reason : String
  headers : Map[String, String]
  body : Bytes
} derive(Show)

///|
pub struct StreamConnection {
  client : @http.Client
  response : @http.Response
}

///|
pub fn RawResponse::request_id(self : RawResponse) -> String? {
  self.headers.get_from_string("request-id")
}

///|
pub fn RawResponse::text(self : RawResponse) -> String {
  @utf8.decode_lossy(self.body)
}

///|
pub fn RawResponse::json(self : RawResponse) -> Json raise AnthropicError {
  parse_json_text(self.text())
}

///|
fn should_retry_error(err : Error) -> Bool {
  match err {
    ConnectionError(_) => true
    TimeoutError(_) => true
    RateLimited(_) => true
    Overloaded(_) => true
    InternalServer(_) => true
    ApiStatusError(status, _, _) => status >= 500 || status == 429 || status == 529
    _ => false
  }
}

///|
fn decode_error_payload(
  response : RawResponse,
) -> ApiErrorPayload {
  let text = response.text()
  let json = parse_json_text(text) catch {
    _ => null
  }
  if json is Object(root) &&
     root.contains("error") &&
     root["error"] is Object(err) {
    let request_id = match json_object_string(root, "request_id") {
      Some(value) => Some(value)
      None => response.request_id()
    }
    return {
      type_: json_object_string(err, "type"),
      message: match json_object_string(err, "message") {
        Some(value) => Some(value)
        None => if text == "" { None } else { Some(text) }
      },
      request_id,
      raw: Some(json),
    }
  }
  {
    type_: None,
    message: if text == "" { None } else { Some(text) },
    request_id: response.request_id(),
    raw: if json is Null { None } else { Some(json) },
  }
}

///|
fn raise_status_error(response : RawResponse) -> Unit raise AnthropicError {
  let payload = decode_error_payload(response)
  match response.status {
    400 => raise BadRequest(payload)
    401 => raise AuthenticationFailed(payload)
    403 => raise PermissionDenied(payload)
    404 => raise NotFound(payload)
    409 => raise Conflict(payload)
    413 => raise RequestTooLarge(payload)
    422 => raise UnprocessableEntity(payload)
    429 => raise RateLimited(payload)
    529 => raise Overloaded(payload)
    code if code >= 500 => raise InternalServer(payload)
    _ => raise ApiStatusError(response.status, response.reason, payload)
  }
}

///|
async fn attempt_request(
  client : Client,
  request_method : @http.RequestMethod,
  path : String,
  request_headers : Map[String, String],
  timeout_ms : Int,
  body : Bytes?,
) -> RawResponse raise AnthropicError {
  try {
    @async.with_timeout(timeout_ms, () => {
      let http_client = @http.Client::new(
        client.parsed_base_url.origin,
        headers=request_headers,
      ) catch {
        err => raise ConnectionError(err.to_string())
      }
      defer http_client.close()
      let response = try {
        http_client.request(request_method, path)
        if body is Some(body) {
          http_client.write(body)
        }
        http_client.end_request()
      } catch {
        err => raise ConnectionError(err.to_string())
      }
      let response_body = try {
        http_client.read_all().binary()
      } catch {
        err => raise ConnectionError(err.to_string())
      }
      let raw = {
        status: response.code,
        reason: response.reason,
        headers: response.headers,
        body: response_body,
      }
      if raw.status < 200 || raw.status >= 300 {
        raise_status_error(raw)
      }
      raw
    }, error=TimeoutError("request to `\{path}` timed out"))
  } catch {
    TimeoutError(message) => raise TimeoutError(message)
    ConnectionError(message) => raise ConnectionError(message)
    RateLimited(payload) => raise RateLimited(payload)
    Overloaded(payload) => raise Overloaded(payload)
    InternalServer(payload) => raise InternalServer(payload)
    ApiStatusError(status, reason, payload) => raise ApiStatusError(status, reason, payload)
    err => raise ConnectionError(repr(err))
  }
}

///|
async fn request_raw(
  client : Client,
  request_method : @http.RequestMethod,
  path : String,
  options : RequestOptions?,
  content_type : String?,
  accept : String?,
  body : Bytes?,
) -> RawResponse raise AnthropicError {
  let timeout_ms = client.resolved_timeout_ms(options)
  let extra_headers = match options {
    Some(options) => options.headers
    None => None
  }
  let headers = resolve_request_headers(client, extra_headers, content_type, accept)
  let query = client.resolve_query(match options {
    Some(options) => options.query
    None => None
  })
  let request_path = join_request_path(client.parsed_base_url.prefix_path, path, query=encode_query(query))
  for attempt = 0; attempt <= client.config.max_retries; attempt = attempt + 1 {
    try {
      return attempt_request(
        client,
        request_method,
        request_path,
        headers,
        timeout_ms,
        body,
      )
    } catch {
      err if should_retry_error(err) && attempt < client.config.max_retries => {
        try {
          @async.sleep(100 * (attempt + 1))
        } catch {
          sleep_err => raise ConnectionError(repr(sleep_err))
        }
      }
      err => raise err
    }
  }
  raise ClientError("request retry limit exceeded")
}

async fn open_stream_connection(
  client : Client,
  request_method : @http.RequestMethod,
  path : String,
  options : RequestOptions?,
  content_type : String?,
  accept : String?,
) -> StreamConnection raise AnthropicError {
  let timeout_ms = client.resolved_timeout_ms(options)
  let extra_headers = match options {
    Some(options) => options.headers
    None => None
  }
  let headers = resolve_request_headers(
    client,
    extra_headers,
    content_type,
    Some(match accept {
      Some(accept) => accept
      None => "text/event-stream"
    }),
  )
  let query = client.resolve_query(match options {
    Some(options) => options.query
    None => None
  })
  let request_path = join_request_path(client.parsed_base_url.prefix_path, path, query=encode_query(query))
  let body = match options {
    Some(options) => match options.body {
      Some(body) => Some(@utf8.encode(body.stringify()))
      None => None
    }
    None => None
  }
  try {
    @async.with_timeout(timeout_ms, () => {
      let http_client = @http.Client::new(
        client.parsed_base_url.origin,
        headers=headers,
      ) catch {
        err => raise ConnectionError(err.to_string())
      }
      let response = try {
        http_client.request(request_method, request_path)
        if body is Some(body) {
          http_client.write(body)
        }
        http_client.end_request()
      } catch {
        err => {
          http_client.close()
          raise ConnectionError(err.to_string())
        }
      }
      if response.code < 200 || response.code >= 300 {
        let response_body = try {
          http_client.read_all().binary()
        } catch {
          err => {
            http_client.close()
            raise ConnectionError(err.to_string())
          }
        }
        let raw = {
          status: response.code,
          reason: response.reason,
          headers: response.headers,
          body: response_body,
        }
        http_client.close()
        raise_status_error(raw)
      }
      { client: http_client, response }
    }, error=TimeoutError("stream request to `\{path}` timed out"))
  } catch {
    TimeoutError(message) => raise TimeoutError(message)
    err => raise ConnectionError(repr(err))
  }
}

///|
fn resolve_request_headers(
  client : Client,
  extra_headers : Map[String, String]?,
  content_type : String?,
  accept : String?,
) -> Map[String, String] raise AnthropicError {
  let headers = client.resolve_headers(extra_headers)
  if content_type is Some(content_type) {
    headers["Content-Type"] = content_type
  }
  if accept is Some(accept) {
    headers["Accept"] = accept
  }
  headers
}

///|
fn multipart_body(
  fields : Array[(String, String)],
  files : Array[MultipartFile],
) -> (Bytes, String) {
  let boundary = "moonbit-anthropic-\{@env.now().to_string()}"
  let buffer = @buffer.new()
  for field in fields {
    let (name, value) = field
    buffer.write_string_utf8("--\{boundary}\r\n")
    buffer.write_string_utf8(
      "Content-Disposition: form-data; name=\"\{name}\"\r\n\r\n",
    )
    buffer.write_string_utf8(value)
    buffer.write_string_utf8("\r\n")
  }
  for file in files {
    buffer.write_string_utf8("--\{boundary}\r\n")
    buffer.write_string_utf8(
      "Content-Disposition: form-data; name=\"\{file.field_name}\"; filename=\"\{file.filename}\"\r\n",
    )
    buffer.write_string_utf8("Content-Type: \{file.content_type}\r\n\r\n")
    buffer.write_bytes(file.data)
    buffer.write_string_utf8("\r\n")
  }
  buffer.write_string_utf8("--\{boundary}--\r\n")
  (buffer.to_bytes(), "multipart/form-data; boundary=\{boundary}")
}
