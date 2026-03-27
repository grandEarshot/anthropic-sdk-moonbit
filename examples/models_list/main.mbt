///|
async fn main {
  let client = @sdk_moonbit.Client::from_env()
  let page = client.models().list()
  for model in page.data {
    let display_name = model.display_name.unwrap_or(model.id)
    println("\{model.id}\t\{display_name}")
  }
}
