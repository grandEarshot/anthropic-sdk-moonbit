///|
fn usage() -> String {
  "Usage: moon run . <file-path>"
}

///|
async fn main {
  let path = match @env.args()[1:] {
    [path, ..] => path
    _ => fail(usage())
  }

  let client = @sdk_moonbit.Client::from_env()
  let file = @sdk_moonbit.MultipartFile::from_path(path)
  let metadata = client.beta().files().upload(file)
  println("uploaded: \{metadata.id}")

  let bytes = client.beta().files().download(metadata.id)
  println("downloaded bytes: \{bytes.length()}")
}
