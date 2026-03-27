# anthropic-sdk-moonbit

Async-first Anthropic SDK for MoonBit `native` target.

MoonBit package name:

- `anthropic/sdk_moonbit`

Current scope:

- Core API: `messages`, `messages.batches`, `models`, legacy `completions`
- Beta API: `messages`, `messages.batches`, `models`, `files`, `skills`, `skills.versions`
- Streaming helpers: SSE message/completion streams and JSONL batch results
- Raw response helpers: `*_raw(...)` variants for HTTP-level access

Environment variables:

- `ANTHROPIC_API_KEY`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_BASE_URL`

Basic usage:

```moonbit
import {
  "anthropic/sdk_moonbit",
  "moonbitlang/async",
  "moonbitlang/core/json",
}

async fn main {
  let client = @sdk_moonbit.Client::from_env()
  let params = @sdk_moonbit.MessageCreateParams::new(
    256,
    [@sdk_moonbit.MessageInput::new(
      "user",
      Json::string("Write a haiku about MoonBit."),
    )],
    "claude-sonnet-4-5",
  )
  let message = client.messages().create(params)
  println(message.text())
}
```

Examples live under [`examples/`](./examples/README.md).
