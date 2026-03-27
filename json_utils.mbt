///|
fn json_string(value : String?) -> Json? {
  match value {
    Some(value) => Some(Json::string(value))
    None => None
  }
}

///|
fn json_int(value : Int?) -> Json? {
  match value {
    Some(value) => Some(Json::number(value.to_double()))
    None => None
  }
}

///|
fn json_double(value : Double?) -> Json? {
  match value {
    Some(value) => Some(Json::number(value))
    None => None
  }
}

///|
fn json_bool(value : Bool?) -> Json? {
  match value {
    Some(value) => Some(Json::boolean(value))
    None => None
  }
}

///|
fn[T] json_array(values : Array[T]?, encode : (T) -> Json) -> Json? {
  match values {
    Some(values) => Some(Json::array(values.map(encode)))
    None => None
  }
}

///|
fn json_object(pairs : Array[(String, Json?)]) -> Json {
  let object : Map[String, Json] = {}
  for pair in pairs {
    let (key, value) = pair
    if value is Some(value) {
      object[key] = value
    }
  }
  Json::object(object)
}

///|
fn json_string_array(values : Array[String]?) -> Json? {
  json_array(values, value => Json::string(value))
}

///|
fn[T : FromJson] decode_json_field(
  object : Map[String, Json],
  key : String,
) -> T raise @json.JsonDecodeError {
  guard object.contains(key) else {
    return @json.from_json(null)
  }
  @json.from_json(object[key])
}

///|
fn[T : FromJson] decode_optional_json_field(
  object : Map[String, Json],
  key : String,
) -> T? raise @json.JsonDecodeError {
  if object.contains(key) {
    Some(@json.from_json(object[key]))
  } else {
    None
  }
}

///|
fn expect_json_object(json : Json) -> Map[String, Json] raise @json.JsonDecodeError {
  match json {
    Object(object) => object
    _ => @json.from_json(null)
  }
}

///|
fn parse_json_text(text : String) -> Json raise AnthropicError {
  @json.parse(text) catch {
    err => raise JsonError(err.to_string())
  }
}

///|
fn json_object_string(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
