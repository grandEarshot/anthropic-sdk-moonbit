///|
fn default_message_params() -> @sdk_moonbit.MessageCreateParams {
  @sdk_moonbit.MessageCreateParams::new(
    512,
    [@sdk_moonbit.MessageInput::new(
      "user",
      Json::string("Stream a short poem about MoonBit."),
    )],
    "anthropic/claude-sonnet-4.6-thinking",
  )
}

///|
async fn main {
  let client = @sdk_moonbit.Client::from_env()
  let stream = client.messages().create_stream(default_message_params())
  let builder = StringBuilder::new()
  while stream.next_text() is Some(chunk) {
    builder.write_stringview(chunk)
  }
  println(builder.to_string())
}
