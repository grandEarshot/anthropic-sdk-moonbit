///|
test "base url prefix and query encoding" {
  let parsed = split_base_url("https://api.anthropic.com/custom/root/")
  inspect(parsed.origin, content="https://api.anthropic.com")
  inspect(parsed.prefix_path, content="/custom/root")
  inspect(
    join_request_path(parsed.prefix_path, "/v1/models", query=encode_query({
      "b": "2",
      "a": "1",
    })),
    content="/custom/root/v1/models?a=1&b=2",
  )
}

///|
test "client resolves auth headers" {
  let client = Client::new(api_key="sk-test")
  let headers = client.resolve_headers(None)
  inspect(headers["X-Api-Key"], content="sk-test")
  inspect(headers["anthropic-version"], content="2023-06-01")
  inspect(headers["X-Stainless-Async"], content="async:moonbit")
}

///|
test "request headers include content type and accept" {
  let client = Client::new(api_key="sk-test")
  let headers = resolve_request_headers(
    client,
    Some({"X-Test": "1"}),
    Some("application/json"),
    Some("text/event-stream"),
  )
  inspect(headers["X-Api-Key"], content="sk-test")
  inspect(headers["Content-Type"], content="application/json")
  inspect(headers["Accept"], content="text/event-stream")
  inspect(headers["X-Test"], content="1")
}

///|
test "message text joins text blocks" {
  let message : Message = {
    id: Some("msg_1"),
    type_: Some("message"),
    role: Some("assistant"),
    model: Some("claude-sonnet-4-5"),
    content: [
      Json::object({
        "type": Json::string("text"),
        "text": Json::string("Hello, "),
      }),
      Json::object({
        "type": Json::string("tool_use"),
        "name": Json::string("noop"),
      }),
      Json::object({
        "type": Json::string("text"),
        "text": Json::string("world"),
      }),
    ],
    stop_reason: None,
    stop_sequence: None,
    usage: None,
    raw: Json::object({}),
  }
  inspect(message.text(), content="Hello, world")
}

///|
test "apply message event aggregates deltas" {
  let message_start = {
    event: "message_start",
    type_: Some("message_start"),
    data_text: "",
    data: Some(Json::object({
      "message": Json::object({
        "id": Json::string("msg_1"),
        "type": Json::string("message"),
        "role": Json::string("assistant"),
        "model": Json::string("claude-sonnet-4-5"),
        "content": Json::array([]),
      }),
    })),
  }
  let block_start = {
    event: "content_block_start",
    type_: Some("content_block_start"),
    data_text: "",
    data: Some(Json::object({
      "index": Json::number(0),
      "content_block": Json::object({
        "type": Json::string("text"),
        "text": Json::string(""),
      }),
    })),
  }
  let block_delta = {
    event: "content_block_delta",
    type_: Some("content_block_delta"),
    data_text: "",
    data: Some(Json::object({
      "index": Json::number(0),
      "delta": Json::object({
        "type": Json::string("text_delta"),
        "text": Json::string("Hello"),
      }),
    })),
  }
  let message_delta = {
    event: "message_delta",
    type_: Some("message_delta"),
    data_text: "",
    data: Some(Json::object({
      "delta": Json::object({
        "stop_reason": Json::string("end_turn"),
      }),
      "usage": Json::object({
        "input_tokens": Json::number(12),
        "output_tokens": Json::number(5),
      }),
    })),
  }

  let snapshot0 = apply_message_event(None, message_start)
  let snapshot1 = apply_message_event(snapshot0, block_start)
  let snapshot2 = apply_message_event(snapshot1, block_delta)
  let snapshot3 = apply_message_event(snapshot2, message_delta)
  let message = decode_message(snapshot3.unwrap())

  inspect(message.text(), content="Hello")
  inspect(message.stop_reason, content="Some(\"end_turn\")")
  inspect(message.usage.unwrap().output_tokens, content="Some(5)")
}

///|
test "multipart body contains fields and files" {
  let (body, content_type) = multipart_body(
    [("purpose", "test")],
    [{
      field_name: "file",
      filename: "sample.txt",
      content_type: "text/plain",
      data: @utf8.encode("hello world"),
    }],
  )
  let text = @utf8.decode_lossy(body)
  inspect(content_type.has_prefix("multipart/form-data; boundary="), content="true")
  inspect(text.contains("name=\"purpose\""), content="true")
  inspect(text.contains("filename=\"sample.txt\""), content="true")
  inspect(text.contains("hello world"), content="true")
}

///|
async test "multipart file loads bytes from disk" {
  let path = "/tmp/anthropic-sdk-moonbit-upload.txt"
  @fs.write_file(path, "payload", create=0o600, truncate=true)
  let file = MultipartFile::from_path(
    path,
    field_name="attachment",
    content_type="text/plain",
  )
  inspect(file.field_name, content="attachment")
  inspect(file.filename, content="anthropic-sdk-moonbit-upload.txt")
  inspect(@utf8.decode_lossy(file.data), content="payload")
  @fs.remove(path)
}
