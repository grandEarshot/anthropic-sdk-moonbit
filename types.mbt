///|
pub struct Page[T] {
  data : Array[T]
  first_id : String?
  last_id : String?
  has_more : Bool
} derive(Show)

///|
pub struct Usage {
  input_tokens : Int?
  output_tokens : Int?
  cache_creation_input_tokens : Int?
  cache_read_input_tokens : Int?
  raw : Json
} derive(Show)

///|
pub struct Message {
  id : String?
  type_ : String?
  role : String?
  model : String?
  content : Array[Json]
  stop_reason : String?
  stop_sequence : String?
  usage : Usage?
  raw : Json
} derive(Show)

///|
pub struct Completion {
  id : String?
  type_ : String?
  completion : String?
  stop_reason : String?
  model : String?
  raw : Json
} derive(Show)

///|
pub struct MessageTokensCount {
  input_tokens : Int
  raw : Json
} derive(Show)

///|
pub struct ModelInfo {
  id : String
  display_name : String?
  type_ : String?
  created_at : String?
  raw : Json
} derive(Show)

///|
pub struct MessageBatch {
  id : String
  type_ : String?
  processing_status : String?
  request_counts : Json?
  raw : Json
} derive(Show)

///|
pub struct DeletedResult {
  id : String?
  type_ : String?
  deleted : Bool?
  raw : Json
} derive(Show)

///|
pub struct FileMetadata {
  id : String
  filename : String?
  mime_type : String?
  size_bytes : Int?
  created_at : String?
  downloadable : Bool?
  raw : Json
} derive(Show)

///|
pub struct SkillInfo {
  id : String
  display_title : String?
  created_at : String?
  raw : Json
} derive(Show)

///|
pub struct SkillVersionInfo {
  id : String
  skill_id : String?
  created_at : String?
  raw : Json
} derive(Show)

///|
pub struct MessageInput {
  role : String
  content : Json
} derive(Show)

///|
pub struct ListParams {
  after_id : String?
  before_id : String?
  limit : Int?
} derive(Show)

///|
pub struct CursorListParams {
  limit : Int?
  page : String?
  source : String?
} derive(Show)

///|
pub struct MessageCreateParams {
  max_tokens : Int
  messages : Array[MessageInput]
  model : String
  system : Json?
  metadata : Json?
  stop_sequences : Array[String]?
  temperature : Double?
  top_k : Int?
  top_p : Double?
  tools : Array[Json]?
  tool_choice : Json?
  thinking : Json?
  output_config : Json?
  cache_control : Json?
  container : Json?
  inference_geo : String?
  service_tier : String?
  mcp_servers : Array[Json]?
  context_management : Json?
  speed : String?
  output_format : Json?
} derive(Show)

///|
pub struct CompletionCreateParams {
  max_tokens_to_sample : Int
  model : String
  prompt : String
  metadata : Json?
  stop_sequences : Array[String]?
  temperature : Double?
  top_k : Int?
  top_p : Double?
} derive(Show)

///|
pub struct BatchRequest {
  custom_id : String
  params : Json
} derive(Show)

///|
pub struct MultipartFile {
  field_name : String
  filename : String
  content_type : String
  data : Bytes
} derive(Show)

///|
pub struct SkillCreateParams {
  display_title : String?
  files : Array[MultipartFile]
} derive(Show)

///|
pub struct SkillVersionCreateParams {
  skill_id : String
  files : Array[MultipartFile]
  display_title : String?
} derive(Show)

///|
pub fn MessageInput::new(role : String, content : Json) -> MessageInput {
  { role, content }
}

///|
pub fn ListParams::new(
  after_id? : String,
  before_id? : String,
  limit? : Int,
) -> ListParams {
  { after_id, before_id, limit }
}

///|
pub fn CursorListParams::new(
  limit? : Int,
  page? : String,
  source? : String,
) -> CursorListParams {
  { limit, page, source }
}

///|
pub fn MessageCreateParams::new(
  max_tokens : Int,
  messages : Array[MessageInput],
  model : String,
  system? : Json,
  metadata? : Json,
  stop_sequences? : Array[String],
  temperature? : Double,
  top_k? : Int,
  top_p? : Double,
  tools? : Array[Json],
  tool_choice? : Json,
  thinking? : Json,
  output_config? : Json,
  cache_control? : Json,
  container? : Json,
  inference_geo? : String,
  service_tier? : String,
  mcp_servers? : Array[Json],
  context_management? : Json,
  speed? : String,
  output_format? : Json,
) -> MessageCreateParams {
  {
    max_tokens,
    messages,
    model,
    system,
    metadata,
    stop_sequences,
    temperature,
    top_k,
    top_p,
    tools,
    tool_choice,
    thinking,
    output_config,
    cache_control,
    container,
    inference_geo,
    service_tier,
    mcp_servers,
    context_management,
    speed,
    output_format,
  }
}

///|
pub fn CompletionCreateParams::new(
  max_tokens_to_sample : Int,
  model : String,
  prompt : String,
  metadata? : Json,
  stop_sequences? : Array[String],
  temperature? : Double,
  top_k? : Int,
  top_p? : Double,
) -> CompletionCreateParams {
  {
    max_tokens_to_sample,
    model,
    prompt,
    metadata,
    stop_sequences,
    temperature,
    top_k,
    top_p,
  }
}

///|
pub fn BatchRequest::new(custom_id : String, params : Json) -> BatchRequest {
  { custom_id, params }
}

///|
pub fn MultipartFile::new(
  filename : String,
  data : Bytes,
  field_name? : String = "file",
  content_type? : String = "application/octet-stream",
) -> MultipartFile {
  { field_name, filename, content_type, data }
}

///|
pub async fn MultipartFile::from_path(
  path : String,
  field_name? : String = "file",
  filename? : String,
  content_type? : String = "application/octet-stream",
) -> MultipartFile {
  let data = @fs.read_file(path).binary()
  let resolved_filename = match filename {
    Some(filename) => filename
    None => filename_from_path(path)
  }
  { field_name, filename: resolved_filename, content_type, data }
}

///|
pub fn SkillCreateParams::new(
  files : Array[MultipartFile],
  display_title? : String,
) -> SkillCreateParams {
  { display_title, files }
}

///|
pub fn SkillVersionCreateParams::new(
  skill_id : String,
  files : Array[MultipartFile],
  display_title? : String,
) -> SkillVersionCreateParams {
  { skill_id, files, display_title }
}

///|
fn filename_from_path(path : String) -> String {
  let mut last = path
  for part in path.split("/") {
    last = part.to_string()
  }
  if last == "" {
    "upload.bin"
  } else {
    last
  }
}

///|
fn decode_usage(json : Json) -> Usage raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    input_tokens: decode_optional_json_field(object, "input_tokens"),
    output_tokens: decode_optional_json_field(object, "output_tokens"),
    cache_creation_input_tokens: decode_optional_json_field(object, "cache_creation_input_tokens"),
    cache_read_input_tokens: decode_optional_json_field(object, "cache_read_input_tokens"),
    raw: json,
  }
}

///|
fn decode_message(json : Json) -> Message raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  let usage = if object.contains("usage") {
    Some(decode_usage(object["usage"]))
  } else {
    None
  }
  {
    id: decode_optional_json_field(object, "id"),
    type_: decode_optional_json_field(object, "type"),
    role: decode_optional_json_field(object, "role"),
    model: decode_optional_json_field(object, "model"),
    content: decode_optional_json_field(object, "content").unwrap_or([]),
    stop_reason: decode_optional_json_field(object, "stop_reason"),
    stop_sequence: decode_optional_json_field(object, "stop_sequence"),
    usage,
    raw: json,
  }
}

///|
fn decode_completion(json : Json) -> Completion raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_optional_json_field(object, "id"),
    type_: decode_optional_json_field(object, "type"),
    completion: decode_optional_json_field(object, "completion"),
    stop_reason: decode_optional_json_field(object, "stop_reason"),
    model: decode_optional_json_field(object, "model"),
    raw: json,
  }
}

///|
fn decode_message_tokens_count(
  json : Json,
) -> MessageTokensCount raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    input_tokens: decode_json_field(object, "input_tokens"),
    raw: json,
  }
}

///|
fn decode_model_info(json : Json) -> ModelInfo raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_json_field(object, "id"),
    display_name: decode_optional_json_field(object, "display_name"),
    type_: decode_optional_json_field(object, "type"),
    created_at: decode_optional_json_field(object, "created_at"),
    raw: json,
  }
}

///|
fn decode_message_batch(json : Json) -> MessageBatch raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_json_field(object, "id"),
    type_: decode_optional_json_field(object, "type"),
    processing_status: decode_optional_json_field(object, "processing_status"),
    request_counts: decode_optional_json_field(object, "request_counts"),
    raw: json,
  }
}

///|
fn decode_deleted_result(json : Json) -> DeletedResult raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_optional_json_field(object, "id"),
    type_: decode_optional_json_field(object, "type"),
    deleted: decode_optional_json_field(object, "deleted"),
    raw: json,
  }
}

///|
fn decode_file_metadata(json : Json) -> FileMetadata raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_json_field(object, "id"),
    filename: decode_optional_json_field(object, "filename"),
    mime_type: decode_optional_json_field(object, "mime_type"),
    size_bytes: decode_optional_json_field(object, "size_bytes"),
    created_at: decode_optional_json_field(object, "created_at"),
    downloadable: decode_optional_json_field(object, "downloadable"),
    raw: json,
  }
}

///|
fn decode_skill_info(json : Json) -> SkillInfo raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_json_field(object, "id"),
    display_title: decode_optional_json_field(object, "display_title"),
    created_at: decode_optional_json_field(object, "created_at"),
    raw: json,
  }
}

///|
fn decode_skill_version_info(
  json : Json,
) -> SkillVersionInfo raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  {
    id: decode_json_field(object, "id"),
    skill_id: decode_optional_json_field(object, "skill_id"),
    created_at: decode_optional_json_field(object, "created_at"),
    raw: json,
  }
}

///|
fn[T] decode_page(
  json : Json,
  decode : (Json) -> T raise @json.JsonDecodeError,
) -> Page[T] raise @json.JsonDecodeError {
  let object = expect_json_object(json)
  let raw_data : Array[Json] = decode_json_field(object, "data")
  {
    data: raw_data.map(decode),
    first_id: decode_optional_json_field(object, "first_id"),
    last_id: decode_optional_json_field(object, "last_id"),
    has_more: decode_optional_json_field(object, "has_more").unwrap_or(false),
  }
}

///|
pub fn Message::text(self : Message) -> String {
  let builder = StringBuilder::new()
  for block in self.content {
    if block is Object(object) {
      let block_type : String? = decode_optional_json_field(object, "type") catch {
        _ => None
      }
      if block_type is Some("text") {
        let text : String? = decode_optional_json_field(object, "text") catch {
          _ => None
        }
        if text is Some(text) {
          builder.write_stringview(text)
        }
      }
    }
  }
  builder.to_string()
}
