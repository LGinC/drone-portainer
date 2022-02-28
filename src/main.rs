use std::env;

fn main() {
    println!("Hello, world!");

    match env::var("PLUGIN_SERVERURL") {
        Ok(v) => println!("PLUGIN_SERVERURL:{}", v),
        Err(e) => println!("get env err: {}", e),
    }
}
