///|
pub struct ApiErrorPayload {
  type_ : String?
  message : String?
  request_id : String?
  raw : Json?
} derive(Show, ToJson)

///|
pub suberror AnthropicError {
  ClientError(String)
  InvalidBaseUrl(String)
  MissingAuthentication
  ConnectionError(String)
  TimeoutError(String)
  JsonError(String)
  ProtocolError(String)
  ApiStatusError(Int, String, ApiErrorPayload)
  BadRequest(ApiErrorPayload)
  AuthenticationFailed(ApiErrorPayload)
  PermissionDenied(ApiErrorPayload)
  NotFound(ApiErrorPayload)
  Conflict(ApiErrorPayload)
  RequestTooLarge(ApiErrorPayload)
  UnprocessableEntity(ApiErrorPayload)
  RateLimited(ApiErrorPayload)
  Overloaded(ApiErrorPayload)
  InternalServer(ApiErrorPayload)
} derive(Show, ToJson)
