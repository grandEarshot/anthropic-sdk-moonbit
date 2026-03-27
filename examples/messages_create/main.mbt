///|
fn default_message_params() -> @sdk_moonbit.MessageCreateParams {
  @sdk_moonbit.MessageCreateParams::new(
    512,
    [@sdk_moonbit.MessageInput::new(
      "user",
      Json::string("Write a haiku about MoonBit."),
    )],
    "anthropic/claude-sonnet-4.6-thinking",
  )
}

///|
async fn main {
  let client = @sdk_moonbit.Client::from_env()
  let message = client.messages().create(default_message_params())
  println(message.text())
}
