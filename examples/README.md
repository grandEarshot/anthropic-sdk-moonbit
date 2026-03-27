# Examples

- `messages_create`: create a message and print the final text
- `messages_stream`: stream text deltas from `/v1/messages`
- `models_list`: list available models
- `beta_files`: upload a file through the beta Files API and download it back

From `anthropic-sdk-moonbit/examples/`:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
# optional
export ANTHROPIC_AUTH_TOKEN=...
export ANTHROPIC_BASE_URL=...

moon check
cd messages_create && moon run
cd ../messages_stream && moon run
cd ../models_list && moon run
cd ../beta_files && moon run . ./sample.txt
```
