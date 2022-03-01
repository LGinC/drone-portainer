use base64::encode;
use serde::Serialize;
use std::collections::HashMap;
use std::env;
use std::string::String;
#[derive(Debug, Serialize)]
pub struct Pair {
    name: String,
    value: String,
}

#[tokio::main]
async fn main() -> Result<(), reqwest::Error> {
    //portainer server url
    let server = env::var("PLUGIN_SERVERURL").unwrap();
    //portainer endpoint, default 1
    let endpoint = match env::var("PLUGIN_ENDPOINTID") {
        Ok(e) => e,
        Err(_) => String::from("1"),
    };
    //stack content, content of docker-compose.yml
    let mut compose = match env::var("PLUGIN_DOCKER_COMPOSE") {
        Ok(c) => c,
        Err(_) => String::default(),
    };
    let stack_name = env::var("PLUGIN_STACKNAME").unwrap();
    let username = env::var("PLUGIN_USERNAME").unwrap();
    let password = env::var("PLUGIN_PASSWORD").unwrap();
    let images_str = match env::var("PLUGIN_IMAGENAMES") {
        Ok(s) => s,
        Err(_) => String::default(),
    };
    let env_str = match env::var("PLUGIN_ENV") {
        Ok(e) => e,
        Err(_) => String::default(),
    };
    let envs: Vec<&str> = match env_str.as_str() {
        "" => Vec::new(),
        v => v.split(',').collect(),
    };
    let mut env = Vec::<Pair>::new();
    if envs.len() > 0 {
        for e in envs {
            let ep: Vec<&str> = e.split('=').into_iter().collect();
            env.push(Pair {
                name: ep[0].trim().to_string(),
                value: ep[1].trim().to_string(),
            })
        }
    }

    let client = reqwest::Client::new();
    //1. login to portainer
    let login_result: serde_json::Value = client
        .post(format!("{}/api/auth", &server))
        .json(&serde_json::json!({
            "Username": &username,
            "Password": &password,
        }))
        .send()
        .await?
        .json()
        .await?;
    let jwt = format!("Bearer {}", &login_result["jwt"].as_str().unwrap());

    //2. pull image
    if images_str != "" {
        println!("pull images: {}", &images_str);
        //get all registry
        let registries: serde_json::Value = client
            .get(format!("{}/api/registries", &server))
            .header("Authorization", &jwt)
            .send()
            .await?
            .json()
            .await?;
        let mut registy_map: HashMap<&str, i32> = HashMap::new();
        for r in registries.as_array().unwrap() {
            registy_map.insert(r["URL"].as_str().unwrap(), r["Id"].as_i64().unwrap() as i32);
        }

        let images: Vec<&str> = images_str.split(',').collect();
        for image in images {
            let mut pull_image_header = reqwest::header::HeaderMap::new();
            pull_image_header.insert("Authorization", jwt.parse().unwrap());
            let registry_name = image.split('/').nth(0).unwrap();
            //if image is in registry_map, pull it with X-Registry-Auth
            if registy_map.contains_key(registry_name) {
                let registry_id = registy_map[registry_name];
                let repo_auth = encode(format!("{{\"registryId\":{}}}", registry_id));
                pull_image_header.insert("X-Registry-Auth", repo_auth.parse().unwrap());
            }
            let pull_image_result = client
                .post(format!(
                    "{}/api/endpoints/{}/docker/images/create?fromImage={}",
                    &server,
                    &endpoint,
                    image.trim()
                ))
                .headers(pull_image_header)
                .send()
                .await?;
            if pull_image_result.status() == 200 {
                println!("pull image success : {}", image);
            } else {
                let msg_detail: serde_json::Value = pull_image_result.json().await?;
                println!("message:{}", &msg_detail["message"].as_str().unwrap());
            }
        }
    }

    //3. get stack id
    let stacks: serde_json::Value = client
        .get(format!(
            "{}/api/stacks?filters={{\"EndpointID\":{},\"IncludeOrphanedStacks\":true}}",
            &server, &endpoint
        ))
        .header("Authorization", &jwt)
        .send()
        .await?
        .json()
        .await?;
    let mut stack_map: HashMap<&str, i32> = HashMap::new();
    for s in stacks.as_array().unwrap() {
        stack_map.insert(
            s["Name"].as_str().unwrap(),
            s["Id"].as_i64().unwrap() as i32,
        );
    }

    if stack_map.contains_key(stack_name.as_str()) {
        let stack_id = stack_map[stack_name.as_str()];
        println!("update stack id: {}", stack_id);
        // compose is empty, get original stack content
        if compose == String::default() {
            let compose_result: serde_json::Value = client
                .get(format!("{}/api/stacks/{}/file", &server, stack_id))
                .header("Authorization", &jwt)
                .send()
                .await?
                .json()
                .await?;
            compose = compose_result["StackFileContent"]
                .as_str()
                .unwrap()
                .to_string();
        }
        //4. update stack
        let update_result: serde_json::Value = client
            .put(format!(
                "{}/api/stacks/{}?endpointId={}",
                &server, stack_id, endpoint
            ))
            .header("Authorization", &jwt)
            .json(&serde_json::json!({
                "id": stack_id,
                "StackFileContent": &compose,
                "Env": env,
                "Prune": false}))
            .send()
            .await?
            .json()
            .await?;
        match update_result["message"].as_str() {
            Some(msg) => {
                println!("update stack failed: {}", msg);
                panic!("update stack failed");
            }
            None => println!("update stack success"),
        }
        return Ok(());
    }

    //5. create stack
    if compose == String::default() {
        panic!("compose is empty, cannot create stack");
    }

    //type: 0: docker compose, 1: docker stack
    //method: file string or repository
    let create_result: serde_json::Value = client
        .post(format!(
            "{}/api/stacks?endpointId={}&method=string&type=2",
            &server, endpoint
        ))
        .header("Authorization", &jwt)
        .json(&serde_json::json!({
            "StackFileContent": &compose,
            "Env": env,
            "Name": &stack_name,
        }))
        .send()
        .await?
        .json()
        .await?;
    match create_result["message"].as_str() {
        Some(msg) => {
            println!("create stack failed: {}", msg);
            panic!("create stack failed");
        }
        None => println!("create stack success"),
    }

    Ok(())
}
