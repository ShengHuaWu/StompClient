## Stomp Client [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
This project is a simple STOMP client,
and we use [_Starscream_](https://github.com/daltoniam/starscream) as a websocket dependency.

### Usage
First thing is to import the _Starscream_ and _StompClient_ frameworks.
Once imported, you're able to connect to the server. Note that `client` is probably best as a property, so it doesn't get deallocated right after being setup.

    let url = server_url
    let socket = WebSocket(url: url)
    client = StompClient(socket: socket)
    client = self
    client.connect()

After you are connected, there are some delegate methods that we need to implement.

#### Delegate Methods
`stompClientDidConnected(client: StompClient)` is called when the client connects to the server.

`stompClient(client: StompClient, didErrorOccurred error: NSError)` is called when error occurs.

`stompClient(client: StompClient, didReceivedData data: NSData)` is called when the client receive a message from the server.

#### Subscription
You can use `subscribe(destination: String, parameters: [String : String]?)` method to subscribe a topic.

### Carthage Install
Add the following line into your _Cartfile_,

      github "ShengHuaWu/StompClient"

and run `carthage update --platform ios` in your terminal.
