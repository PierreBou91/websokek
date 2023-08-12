use std::{
    env,
    net::{Ipv4Addr, SocketAddr},
};

use wtransport::{endpoint::IncomingSession, tls::Certificate, Endpoint, ServerConfig};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cert_path = env::var("CERT_PATH").expect("CERT_PATH not set");
    let key_path = env::var("KEY_PATH").expect("KEY_PATH not set");
    let socket_addr = SocketAddr::new(Ipv4Addr::UNSPECIFIED.into(), 4433); //ipv4 for docker

    dbg!(cert_path.clone());
    dbg!(key_path.clone());

    let config = ServerConfig::builder()
        .with_bind_address(socket_addr)
        .with_certificate(Certificate::load(cert_path, key_path).unwrap())
        .keep_alive_interval(Some(std::time::Duration::from_secs(5)))
        .max_idle_timeout(Some(std::time::Duration::from_secs(10)))
        .unwrap()
        .build();

    let server = Endpoint::server(config)?;

    println!("Listening on: {}", socket_addr);

    for i in 0.. {
        let incomming_session = server.accept().await;
        println!("Accepted session: {}", i);
        tokio::spawn(handle_incoming_session(incomming_session));
    }

    Ok(())
}

async fn handle_incoming_session(incomming_session: IncomingSession) {
    let result = handle_incoming_session_impl(incomming_session).await;
    eprintln!("Session ended: {:?}", result);
}

async fn handle_incoming_session_impl(
    incoming_session: IncomingSession,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut buffer = vec![0; 65536].into_boxed_slice();

    println!("Waiting for session request...");

    let session_request = incoming_session.await?;

    println!(
        "New session: Authority: '{}', Path: '{}'",
        session_request.authority(),
        session_request.path()
    );

    let connection = session_request.accept().await?;

    println!("Waiting for data from client...");

    loop {
        tokio::select! {
            stream = connection.accept_bi() => {
                let mut stream = stream?;
                println!("Accepted BI stream");

                let bytes_read = match stream.1.read(&mut buffer).await? {
                    Some(bytes_read) => bytes_read,
                    None => continue,
                };

                let str_data = std::str::from_utf8(&buffer[..bytes_read])?;

                println!("Received (bi) '{str_data}' from client");

                stream.0.write_all(b"ACK").await?;
            }
            stream = connection.accept_uni() => {
                let mut stream = stream?;
                println!("Accepted UNI stream");

                let bytes_read = match stream.read(&mut buffer).await? {
                    Some(bytes_read) => bytes_read,
                    None => continue,
                };

                let str_data = std::str::from_utf8(&buffer[..bytes_read])?;

                println!("Received (uni) '{str_data}' from client");

                let mut stream = connection.open_uni().await?.await?;
                stream.write_all(b"ACK").await?;
            }
            dgram = connection.receive_datagram() => {
                let dgram = dgram?;
                let str_data = std::str::from_utf8(&dgram)?;

                println!("Received (dgram) '{str_data}' from client");

                connection.send_datagram(b"ACK")?;
            }
        }
    }
}
