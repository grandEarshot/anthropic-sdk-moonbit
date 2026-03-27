///|
pub struct CountTokensParams {
  messages : Array[MessageInput]
  model : String
  system : Json?
  tools : Array[Json]?
  thinking : Json?
  tool_choice : Json?
  output_config : Json?
  cache_control : Json?
} derive(Show)

///|
pub struct ModelsApi {
  client : Client
  is_beta : Bool
} derive(Show)

///|
pub struct MessagesApi {
  client : Client
  is_beta : Bool
} derive(Show)

///|
pub struct BatchesApi {
  client : Client
  is_beta : Bool
} derive(Show)

///|
pub struct CompletionsApi {
  client : Client
} derive(Show)

///|
pub struct FilesApi {
  client : Client
} derive(Show)

///|
pub struct SkillsApi {
  client : Client
} derive(Show)

///|
pub struct SkillVersionsApi {
  client : Client
} derive(Show)

///|
pub struct BetaApi {
  client : Client
} derive(Show)

///|
pub fn CountTokensParams::new(
  messages : Array[MessageInput],
  model : String,
  system? : Json,
  tools? : Array[Json],
  thinking? : Json,
  tool_choice? : Json,
  output_config? : Json,
  cache_control? : Json,
) -> CountTokensParams {
  {
    messages,
    model,
    system,
    tools,
    thinking,
    tool_choice,
    output_config,
    cache_control,
  }
}

///|
const FILES_BETA_VERSION : String = "files-api-2025-04-14"

///|
const SKILLS_BETA_VERSION : String = "skills-2025-10-02"

///|
fn merge_request_options(
  options : RequestOptions?,
  extra_headers : Map[String, String],
  extra_query : Map[String, String],
  body : Json?,
) -> RequestOptions {
  let headers = match options {
    Some(options) => match options.headers {
      Some(headers) => headers.copy()
      None => {}
    }
    None => {}
  }
  let query = match options {
    Some(options) => match options.query {
      Some(query) => query.copy()
      None => {}
    }
    None => {}
  }
  for key, value in extra_headers {
    headers[key] = value
  }
  for key, value in extra_query {
    query[key] = value
  }
  {
    headers: if headers.is_empty() { None } else { Some(headers) },
    query: if query.is_empty() { None } else { Some(query) },
    body: match body {
      Some(body) => Some(body)
      None => match options {
        Some(options) => options.body
        None => None
      }
    },
    timeout_ms: match options {
      Some(options) => options.timeout_ms
      None => None
    },
  }
}

///|
fn[T] decode_json_or_error(
  json : Json,
  decode : (Json) -> T raise @json.JsonDecodeError,
) -> T raise AnthropicError {
  decode(json) catch {
    err => raise JsonError(repr(err))
  }
}

///|
fn message_input_json(message : MessageInput) -> Json {
  json_object([
    ("role", Some(Json::string(message.role))),
    ("content", Some(message.content)),
  ])
}

///|
fn message_create_body(params : MessageCreateParams, stream : Bool) -> Json {
  json_object([
    ("max_tokens", json_int(Some(params.max_tokens))),
    ("messages", Some(Json::array(params.messages.map(message_input_json)))),
    ("model", Some(Json::string(params.model))),
    ("system", params.system),
    ("metadata", params.metadata),
    ("stop_sequences", json_string_array(params.stop_sequences)),
    ("stream", json_bool(Some(stream))),
    ("temperature", json_double(params.temperature)),
    ("top_k", json_int(params.top_k)),
    ("top_p", json_double(params.top_p)),
    ("tools", json_array(params.tools, value => value)),
    ("tool_choice", params.tool_choice),
    ("thinking", params.thinking),
    ("output_config", params.output_config),
    ("cache_control", params.cache_control),
    ("container", params.container),
    ("inference_geo", json_string(params.inference_geo)),
    ("service_tier", json_string(params.service_tier)),
    ("mcp_servers", json_array(params.mcp_servers, value => value)),
    ("context_management", params.context_management),
    ("speed", json_string(params.speed)),
    ("output_format", params.output_format),
  ])
}

///|
fn count_tokens_body(params : CountTokensParams) -> Json {
  json_object([
    ("messages", Some(Json::array(params.messages.map(message_input_json)))),
    ("model", Some(Json::string(params.model))),
    ("system", params.system),
    ("tools", json_array(params.tools, value => value)),
    ("thinking", params.thinking),
    ("tool_choice", params.tool_choice),
    ("output_config", params.output_config),
    ("cache_control", params.cache_control),
  ])
}

///|
fn completion_create_body(params : CompletionCreateParams, stream : Bool) -> Json {
  json_object([
    ("max_tokens_to_sample", json_int(Some(params.max_tokens_to_sample))),
    ("model", Some(Json::string(params.model))),
    ("prompt", Some(Json::string(params.prompt))),
    ("metadata", params.metadata),
    ("stop_sequences", json_string_array(params.stop_sequences)),
    ("stream", json_bool(Some(stream))),
    ("temperature", json_double(params.temperature)),
    ("top_k", json_int(params.top_k)),
    ("top_p", json_double(params.top_p)),
  ])
}

///|
fn list_params_query(params : ListParams?) -> Map[String, String] {
  let query : Map[String, String] = {}
  if params is Some(params) {
    if params.after_id is Some(value) {
      query["after_id"] = value
    }
    if params.before_id is Some(value) {
      query["before_id"] = value
    }
    if params.limit is Some(value) {
      query["limit"] = value.to_string()
    }
  }
  query
}

///|
fn cursor_list_query(params : CursorListParams?) -> Map[String, String] {
  let query : Map[String, String] = {}
  if params is Some(params) {
    if params.limit is Some(value) {
      query["limit"] = value.to_string()
    }
    if params.page is Some(value) {
      query["page"] = value
    }
    if params.source is Some(value) {
      query["source"] = value
    }
  }
  query
}

///|
fn batch_requests_body(requests : Array[BatchRequest]) -> Json {
  Json::object({
    "requests": Json::array(requests.map(request =>
      Json::object({
        "custom_id": Json::string(request.custom_id),
        "params": request.params,
      }))),
  })
}

///|
pub fn Client::models(self : Client) -> ModelsApi {
  { client: self, is_beta: false }
}

///|
pub fn Client::messages(self : Client) -> MessagesApi {
  { client: self, is_beta: false }
}

///|
pub fn Client::completions(self : Client) -> CompletionsApi {
  { client: self }
}

///|
pub fn Client::beta(self : Client) -> BetaApi {
  { client: self }
}

///|
pub fn BetaApi::models(self : BetaApi) -> ModelsApi {
  { client: self.client, is_beta: true }
}

///|
pub fn BetaApi::messages(self : BetaApi) -> MessagesApi {
  { client: self.client, is_beta: true }
}

///|
pub fn BetaApi::files(self : BetaApi) -> FilesApi {
  { client: self.client }
}

///|
pub fn BetaApi::skills(self : BetaApi) -> SkillsApi {
  { client: self.client }
}

///|
pub fn MessagesApi::batches(self : MessagesApi) -> BatchesApi {
  { client: self.client, is_beta: self.is_beta }
}

///|
pub fn SkillsApi::versions(self : SkillsApi) -> SkillVersionsApi {
  { client: self.client }
}

///|
pub async fn ModelsApi::retrieve_raw(
  self : ModelsApi,
  model_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {},
    if self.is_beta { {"beta": "true"} } else { {} },
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/models/\{model_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn ModelsApi::list_raw(
  self : ModelsApi,
  params? : ListParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = list_params_query(params)
  if self.is_beta {
    query["beta"] = "true"
  }
  let request_options = merge_request_options(options, {}, query, None)
  request_raw(
    self.client,
    Get,
    "/v1/models",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn ModelsApi::retrieve(
  self : ModelsApi,
  model_id : String,
  options? : RequestOptions,
) -> ModelInfo raise AnthropicError {
  decode_json_or_error(
    self.retrieve_raw(model_id, options?).json(),
    decode_model_info,
  )
}

///|
pub async fn ModelsApi::list(
  self : ModelsApi,
  params? : ListParams,
  options? : RequestOptions,
) -> Page[ModelInfo] raise AnthropicError {
  decode_json_or_error(
    self.list_raw(params?, options?).json(),
    json => decode_page(json, decode_model_info),
  )
}

///|
pub async fn MessagesApi::create_raw(
  self : MessagesApi,
  params : MessageCreateParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = if self.is_beta { {"beta": "true"} } else { {} }
  let body = message_create_body(params, false)
  let request_options = merge_request_options(options, {}, query, Some(body))
  request_raw(
    self.client,
    Post,
    "/v1/messages",
    Some(request_options),
    Some("application/json"),
    Some("application/json"),
    Some(@utf8.encode(body.stringify())),
  )
}

///|
pub async fn MessagesApi::count_tokens_raw(
  self : MessagesApi,
  params : CountTokensParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = if self.is_beta { {"beta": "true"} } else { {} }
  let body = count_tokens_body(params)
  let request_options = merge_request_options(options, {}, query, Some(body))
  request_raw(
    self.client,
    Post,
    "/v1/messages/count_tokens",
    Some(request_options),
    Some("application/json"),
    Some("application/json"),
    Some(@utf8.encode(body.stringify())),
  )
}

///|
pub async fn MessagesApi::create(
  self : MessagesApi,
  params : MessageCreateParams,
  options? : RequestOptions,
) -> Message raise AnthropicError {
  decode_json_or_error(
    self.create_raw(params, options?).json(),
    decode_message,
  )
}

///|
pub async fn MessagesApi::count_tokens(
  self : MessagesApi,
  params : CountTokensParams,
  options? : RequestOptions,
) -> MessageTokensCount raise AnthropicError {
  decode_json_or_error(
    self.count_tokens_raw(params, options?).json(),
    decode_message_tokens_count,
  )
}

///|
pub async fn MessagesApi::stream(
  self : MessagesApi,
  params : MessageCreateParams,
  options? : RequestOptions,
) -> MessageStream raise AnthropicError {
  let query = if self.is_beta { {"beta": "true"} } else { {} }
  let request_options = merge_request_options(
    options,
    {},
    query,
    Some(message_create_body(params, true)),
  )
  let connection = open_stream_connection(
    self.client,
    Post,
    "/v1/messages",
    Some(request_options),
    Some("application/json"),
    None,
  )
  { connection: Some(connection), snapshot: None, final_text: "" }
}

///|
pub async fn MessagesApi::create_stream(
  self : MessagesApi,
  params : MessageCreateParams,
  options? : RequestOptions,
) -> MessageStream raise AnthropicError {
  self.stream(params, options?)
}

///|
pub async fn BatchesApi::create_raw(
  self : BatchesApi,
  requests : Array[BatchRequest],
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = if self.is_beta { {"beta": "true"} } else { {} }
  let body = batch_requests_body(requests)
  let request_options = merge_request_options(
    options,
    {},
    query,
    Some(body),
  )
  request_raw(
    self.client,
    Post,
    "/v1/messages/batches",
    Some(request_options),
    Some("application/json"),
    Some("application/json"),
    Some(@utf8.encode(body.stringify())),
  )
}

///|
pub async fn BatchesApi::retrieve_raw(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {},
    if self.is_beta { {"beta": "true"} } else { {} },
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/messages/batches/\{message_batch_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn BatchesApi::list_raw(
  self : BatchesApi,
  params? : ListParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = list_params_query(params)
  if self.is_beta {
    query["beta"] = "true"
  }
  let request_options = merge_request_options(options, {}, query, None)
  request_raw(
    self.client,
    Get,
    "/v1/messages/batches",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn BatchesApi::delete_raw(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {},
    if self.is_beta { {"beta": "true"} } else { {} },
    None,
  )
  request_raw(
    self.client,
    Delete,
    "/v1/messages/batches/\{message_batch_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn BatchesApi::cancel_raw(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let body = Json::object({})
  let request_options = merge_request_options(
    options,
    {},
    if self.is_beta { {"beta": "true"} } else { {} },
    Some(body),
  )
  request_raw(
    self.client,
    Post,
    "/v1/messages/batches/\{message_batch_id}/cancel",
    Some(request_options),
    Some("application/json"),
    Some("application/json"),
    Some(@utf8.encode(body.stringify())),
  )
}

///|
pub async fn BatchesApi::create(
  self : BatchesApi,
  requests : Array[BatchRequest],
  options? : RequestOptions,
) -> MessageBatch raise AnthropicError {
  decode_json_or_error(
    self.create_raw(requests, options?).json(),
    decode_message_batch,
  )
}

///|
pub async fn BatchesApi::retrieve(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> MessageBatch raise AnthropicError {
  decode_json_or_error(
    self.retrieve_raw(message_batch_id, options?).json(),
    decode_message_batch,
  )
}

///|
pub async fn BatchesApi::list(
  self : BatchesApi,
  params? : ListParams,
  options? : RequestOptions,
) -> Page[MessageBatch] raise AnthropicError {
  decode_json_or_error(
    self.list_raw(params?, options?).json(),
    json => decode_page(json, decode_message_batch),
  )
}

///|
pub async fn BatchesApi::delete(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> DeletedResult raise AnthropicError {
  decode_json_or_error(
    self.delete_raw(message_batch_id, options?).json(),
    decode_deleted_result,
  )
}

///|
pub async fn BatchesApi::cancel(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> MessageBatch raise AnthropicError {
  decode_json_or_error(
    self.cancel_raw(message_batch_id, options?).json(),
    decode_message_batch,
  )
}

///|
pub async fn BatchesApi::results(
  self : BatchesApi,
  message_batch_id : String,
  options? : RequestOptions,
) -> JsonlReader raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {},
    if self.is_beta { {"beta": "true"} } else { {} },
    None,
  )
  let connection = open_stream_connection(
    self.client,
    Get,
    "/v1/messages/batches/\{message_batch_id}/results",
    Some(request_options),
    None,
    Some("application/x-ndjson"),
  )
  { connection: Some(connection) }
}

///|
pub async fn CompletionsApi::create_raw(
  self : CompletionsApi,
  params : CompletionCreateParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let body = completion_create_body(params, false)
  let request_options = merge_request_options(
    options,
    {},
    {},
    Some(body),
  )
  request_raw(
    self.client,
    Post,
    "/v1/complete",
    Some(request_options),
    Some("application/json"),
    Some("application/json"),
    Some(@utf8.encode(body.stringify())),
  )
}

///|
pub async fn CompletionsApi::create(
  self : CompletionsApi,
  params : CompletionCreateParams,
  options? : RequestOptions,
) -> Completion raise AnthropicError {
  decode_json_or_error(
    self.create_raw(params, options?).json(),
    decode_completion,
  )
}

///|
pub async fn CompletionsApi::stream(
  self : CompletionsApi,
  params : CompletionCreateParams,
  options? : RequestOptions,
) -> CompletionStream raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {},
    {},
    Some(completion_create_body(params, true)),
  )
  let connection = open_stream_connection(
    self.client,
    Post,
    "/v1/complete",
    Some(request_options),
    Some("application/json"),
    None,
  )
  { connection: Some(connection), chunks: [] }
}

///|
pub async fn CompletionsApi::create_stream(
  self : CompletionsApi,
  params : CompletionCreateParams,
  options? : RequestOptions,
) -> CompletionStream raise AnthropicError {
  self.stream(params, options?)
}

///|
pub async fn FilesApi::list_raw(
  self : FilesApi,
  params? : ListParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = list_params_query(params)
  query["beta"] = "true"
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": FILES_BETA_VERSION},
    query,
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/files",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn FilesApi::retrieve_metadata_raw(
  self : FilesApi,
  file_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": FILES_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/files/\{file_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn FilesApi::delete_raw(
  self : FilesApi,
  file_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": FILES_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Delete,
    "/v1/files/\{file_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn FilesApi::download_raw(
  self : FilesApi,
  file_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": FILES_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/files/\{file_id}/content",
    Some(request_options),
    None,
    Some("application/binary"),
    None,
  )
}

///|
pub async fn FilesApi::upload_raw(
  self : FilesApi,
  file : MultipartFile,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let (body, content_type) = multipart_body([], [file])
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": FILES_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Post,
    "/v1/files",
    Some(request_options),
    Some(content_type),
    Some("application/json"),
    Some(body),
  )
}

///|
pub async fn FilesApi::list(
  self : FilesApi,
  params? : ListParams,
  options? : RequestOptions,
) -> Page[FileMetadata] raise AnthropicError {
  decode_json_or_error(
    self.list_raw(params?, options?).json(),
    json => decode_page(json, decode_file_metadata),
  )
}

///|
pub async fn FilesApi::retrieve_metadata(
  self : FilesApi,
  file_id : String,
  options? : RequestOptions,
) -> FileMetadata raise AnthropicError {
  decode_json_or_error(
    self.retrieve_metadata_raw(file_id, options?).json(),
    decode_file_metadata,
  )
}

///|
pub async fn FilesApi::delete(
  self : FilesApi,
  file_id : String,
  options? : RequestOptions,
) -> DeletedResult raise AnthropicError {
  decode_json_or_error(
    self.delete_raw(file_id, options?).json(),
    decode_deleted_result,
  )
}

///|
pub async fn FilesApi::download(
  self : FilesApi,
  file_id : String,
  options? : RequestOptions,
) -> Bytes raise AnthropicError {
  self.download_raw(file_id, options?).body
}

///|
pub async fn FilesApi::upload(
  self : FilesApi,
  file : MultipartFile,
  options? : RequestOptions,
) -> FileMetadata raise AnthropicError {
  decode_json_or_error(self.upload_raw(file, options?).json(), decode_file_metadata)
}

///|
pub async fn SkillsApi::create_raw(
  self : SkillsApi,
  params : SkillCreateParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let fields = match params.display_title {
    Some(title) => [("display_title", title)]
    None => []
  }
  let (body, content_type) = multipart_body(fields, params.files)
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Post,
    "/v1/skills",
    Some(request_options),
    Some(content_type),
    Some("application/json"),
    Some(body),
  )
}

///|
pub async fn SkillsApi::retrieve_raw(
  self : SkillsApi,
  skill_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/skills/\{skill_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn SkillsApi::list_raw(
  self : SkillsApi,
  params? : CursorListParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = cursor_list_query(params)
  query["beta"] = "true"
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    query,
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/skills",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn SkillsApi::delete_raw(
  self : SkillsApi,
  skill_id : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Delete,
    "/v1/skills/\{skill_id}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn SkillsApi::create(
  self : SkillsApi,
  params : SkillCreateParams,
  options? : RequestOptions,
) -> SkillInfo raise AnthropicError {
  decode_json_or_error(self.create_raw(params, options?).json(), decode_skill_info)
}

///|
pub async fn SkillsApi::retrieve(
  self : SkillsApi,
  skill_id : String,
  options? : RequestOptions,
) -> SkillInfo raise AnthropicError {
  decode_json_or_error(
    self.retrieve_raw(skill_id, options?).json(),
    decode_skill_info,
  )
}

///|
pub async fn SkillsApi::list(
  self : SkillsApi,
  params? : CursorListParams,
  options? : RequestOptions,
) -> Page[SkillInfo] raise AnthropicError {
  decode_json_or_error(
    self.list_raw(params?, options?).json(),
    json => decode_page(json, decode_skill_info),
  )
}

///|
pub async fn SkillsApi::delete(
  self : SkillsApi,
  skill_id : String,
  options? : RequestOptions,
) -> DeletedResult raise AnthropicError {
  decode_json_or_error(
    self.delete_raw(skill_id, options?).json(),
    decode_deleted_result,
  )
}

///|
pub async fn SkillVersionsApi::create_raw(
  self : SkillVersionsApi,
  params : SkillVersionCreateParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let fields = match params.display_title {
    Some(title) => [("display_title", title)]
    None => []
  }
  let (body, content_type) = multipart_body(fields, params.files)
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Post,
    "/v1/skills/\{params.skill_id}/versions",
    Some(request_options),
    Some(content_type),
    Some("application/json"),
    Some(body),
  )
}

///|
pub async fn SkillVersionsApi::retrieve_raw(
  self : SkillVersionsApi,
  skill_id : String,
  version : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/skills/\{skill_id}/versions/\{version}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn SkillVersionsApi::list_raw(
  self : SkillVersionsApi,
  skill_id : String,
  params? : CursorListParams,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let query = cursor_list_query(params)
  query["beta"] = "true"
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    query,
    None,
  )
  request_raw(
    self.client,
    Get,
    "/v1/skills/\{skill_id}/versions",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn SkillVersionsApi::delete_raw(
  self : SkillVersionsApi,
  skill_id : String,
  version : String,
  options? : RequestOptions,
) -> RawResponse raise AnthropicError {
  let request_options = merge_request_options(
    options,
    {"anthropic-beta": SKILLS_BETA_VERSION},
    {"beta": "true"},
    None,
  )
  request_raw(
    self.client,
    Delete,
    "/v1/skills/\{skill_id}/versions/\{version}",
    Some(request_options),
    None,
    Some("application/json"),
    None,
  )
}

///|
pub async fn SkillVersionsApi::create(
  self : SkillVersionsApi,
  params : SkillVersionCreateParams,
  options? : RequestOptions,
) -> SkillVersionInfo raise AnthropicError {
  decode_json_or_error(
    self.create_raw(params, options?).json(),
    decode_skill_version_info,
  )
}

///|
pub async fn SkillVersionsApi::retrieve(
  self : SkillVersionsApi,
  skill_id : String,
  version : String,
  options? : RequestOptions,
) -> SkillVersionInfo raise AnthropicError {
  decode_json_or_error(
    self.retrieve_raw(skill_id, version, options?).json(),
    decode_skill_version_info,
  )
}

///|
pub async fn SkillVersionsApi::list(
  self : SkillVersionsApi,
  skill_id : String,
  params? : CursorListParams,
  options? : RequestOptions,
) -> Page[SkillVersionInfo] raise AnthropicError {
  decode_json_or_error(
    self.list_raw(skill_id, params?, options?).json(),
    json => decode_page(json, decode_skill_version_info),
  )
}

///|
pub async fn SkillVersionsApi::delete(
  self : SkillVersionsApi,
  skill_id : String,
  version : String,
  options? : RequestOptions,
) -> DeletedResult raise AnthropicError {
  decode_json_or_error(
    self.delete_raw(skill_id, version, options?).json(),
    decode_deleted_result,
  )
}
