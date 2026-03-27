///|
pub struct SseEvent {
  event : String
  type_ : String?
  data_text : String
  data : Json?
} derive(Show)

///|
pub struct JsonlReader {
  mut connection : StreamConnection?
}

///|
pub struct CompletionStream {
  mut connection : StreamConnection?
  chunks : Array[Completion]
}

///|
pub struct MessageStream {
  mut connection : StreamConnection?
  mut snapshot : Json?
  mut final_text : String
}

///|
fn trim_cr(line : String) -> String {
  line.trim_end(chars="\r").to_string()
}

///|
async fn read_sse_event(connection : StreamConnection) -> SseEvent? raise AnthropicError {
  let event_name = "message"
  let data_lines = []
  let mut current_event = event_name
  while true {
    let line = connection.client.read_until("\n") catch {
      err => raise ConnectionError(repr(err))
    }
    match line {
      None => {
        if data_lines.is_empty() {
          return None
        }
        break
      }
      Some(raw_line) => {
        let text = trim_cr(raw_line)
        if text == "" {
          if data_lines.is_empty() {
            continue
          }
          break
        }
        if text.has_prefix("event:") {
          current_event = text[6:].to_string().trim().to_string()
        } else if text.has_prefix("data:") {
          data_lines.push(text[5:].to_string().trim().to_string())
        }
      }
    }
  }
  let data_text = data_lines.join("\n")
  let data = if data_text == "" {
    None
  } else {
    Some(parse_json_text(data_text))
  }
  let type_ = match data {
    Some(Object(object)) => json_object_string(object, "type")
    _ => None
  }
  Some({ event: current_event, type_, data_text, data })
}

///|
fn ensure_content_slot(content : Array[Json], index : Int) -> Unit {
  while content.length() <= index {
    content.push(null)
  }
}

///|
fn message_snapshot_from_start(event : SseEvent) -> Json? {
  match event.data {
    Some(Object(object)) => object.get("message")
    _ => None
  }
}

///|
fn apply_message_event(snapshot : Json?, event : SseEvent) -> Json? {
  match event.event {
    "message_start" => message_snapshot_from_start(event)
    "content_block_start" => {
      match (snapshot, event.data) {
        (Some(Object(message)), Some(Object(event_object))) => {
          let index = match event_object.get("index") {
            Some(Number(value, ..)) => value.to_int()
            _ => 0
          }
          let content = match message.get("content") {
            Some(Array(content)) => content
            _ => []
          }
          ensure_content_slot(content, index)
          content[index] = event_object.get("content_block").unwrap_or(null)
          message["content"] = Json::array(content)
          Some(Json::object(message))
        }
        _ => snapshot
      }
    }
    "content_block_delta" => {
      match (snapshot, event.data) {
        (Some(Object(message)), Some(Object(event_object))) => {
          let index = match event_object.get("index") {
            Some(Number(value, ..)) => value.to_int()
            _ => 0
          }
          let content = match message.get("content") {
            Some(Array(content)) => content
            _ => []
          }
          ensure_content_slot(content, index)
          let delta = match event_object.get("delta") {
            Some(Object(delta)) => delta
            _ => {}
          }
          let delta_type = json_object_string(delta, "type")
          if delta_type is Some("text_delta") {
            let addition = json_object_string(delta, "text").unwrap_or("")
            if content[index] is Object(block) {
              let existing = json_object_string(block, "text").unwrap_or("")
              block["text"] = Json::string(existing + addition)
              content[index] = Json::object(block)
            }
          }
          message["content"] = Json::array(content)
          Some(Json::object(message))
        }
        _ => snapshot
      }
    }
    "message_delta" => {
      match (snapshot, event.data) {
        (Some(Object(message)), Some(Object(event_object))) => {
          if event_object.get("delta") is Some(Object(delta)) {
            if delta.get("stop_reason") is Some(stop_reason) {
              message["stop_reason"] = stop_reason
            }
            if delta.get("stop_sequence") is Some(stop_sequence) {
              message["stop_sequence"] = stop_sequence
            }
          }
          if event_object.get("usage") is Some(usage) {
            message["usage"] = usage
          }
          Some(Json::object(message))
        }
        _ => snapshot
      }
    }
    _ => snapshot
  }
}

///|
pub fn JsonlReader::close(self : JsonlReader) -> Unit {
  if self.connection is Some(connection) {
    connection.client.close()
    self.connection = None
  }
}

///|
pub async fn JsonlReader::next(self : JsonlReader) -> Json? raise AnthropicError {
  guard self.connection is Some(connection) else { return None }
  let line = connection.client.read_until("\n") catch {
    err => raise ConnectionError(repr(err))
  }
  match line {
    None => {
      self.close()
      None
    }
    Some(line) => {
      let text = trim_cr(line)
      if text == "" {
        self.next()
      } else {
        Some(parse_json_text(text))
      }
    }
  }
}

///|
pub fn CompletionStream::close(self : CompletionStream) -> Unit {
  if self.connection is Some(connection) {
    connection.client.close()
    self.connection = None
  }
}

///|
pub async fn CompletionStream::next(
  self : CompletionStream,
) -> Completion? raise AnthropicError {
  guard self.connection is Some(connection) else { return None }
  let event = read_sse_event(connection)
  match event {
    None => {
      self.close()
      None
    }
    Some(event) if event.event == "ping" => self.next()
    Some(event) if event.event == "error" => raise ProtocolError(event.data_text)
    Some(event) if event.event == "completion" && event.data is Some(json) => {
      let completion = decode_completion(json) catch {
        err => raise JsonError(repr(err))
      }
      self.chunks.push(completion)
      Some(completion)
    }
    Some(_) => self.next()
  }
}

///|
pub async fn CompletionStream::until_done(self : CompletionStream) -> Unit raise AnthropicError {
  while self.next() is Some(_) {}
}

///|
pub fn CompletionStream::get_final_text(self : CompletionStream) -> String {
  let builder = StringBuilder::new()
  for chunk in self.chunks {
    if chunk.completion is Some(text) {
      builder.write_stringview(text)
    }
  }
  builder.to_string()
}

///|
pub fn MessageStream::close(self : MessageStream) -> Unit {
  if self.connection is Some(connection) {
    connection.client.close()
    self.connection = None
  }
}

///|
pub async fn MessageStream::next(
  self : MessageStream,
) -> SseEvent? raise AnthropicError {
  guard self.connection is Some(connection) else { return None }
  let event = read_sse_event(connection)
  match event {
    None => {
      self.close()
      None
    }
    Some(event) if event.event == "ping" => self.next()
    Some(event) if event.event == "error" => raise ProtocolError(event.data_text)
    Some(event) => {
      self.snapshot = apply_message_event(self.snapshot, event)
      if event.event == "content_block_delta" &&
         event.data is Some(Object(object)) &&
         object.get("delta") is Some(Object(delta)) &&
         json_object_string(delta, "type") is Some("text_delta") {
        self.final_text = self.final_text + json_object_string(delta, "text").unwrap_or("")
      }
      Some(event)
    }
  }
}

///|
pub async fn MessageStream::next_text(
  self : MessageStream,
) -> String? raise AnthropicError {
  while self.next() is Some(event) {
    if event.event == "content_block_delta" &&
       event.data is Some(Object(object)) &&
       object.get("delta") is Some(Object(delta)) &&
       json_object_string(delta, "type") is Some("text_delta") {
      return Some(json_object_string(delta, "text").unwrap_or(""))
    }
  }
  None
}

///|
pub async fn MessageStream::until_done(self : MessageStream) -> Unit raise AnthropicError {
  while self.next() is Some(_) {}
}

///|
pub fn MessageStream::get_final_text(self : MessageStream) -> String {
  self.final_text
}

///|
pub fn MessageStream::get_final_message(self : MessageStream) -> Message? raise AnthropicError {
  match self.snapshot {
    Some(snapshot) => Some(decode_message(snapshot) catch {
      err => raise JsonError(repr(err))
    })
    None => None
  }
}
