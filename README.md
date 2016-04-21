## Stomp Client [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
This project is a simple STOMP client in _Swift_,
and we use [_Starscream_](https://github.com/daltoniam/starscream) as a websocket dependency.

### Usage
First thing is to import the _Starscream_ and _StompClient_ frameworks.
Once imported, you're able to connect to the server. Note that `client` is probably best as a property, so it doesn't get deallocated right after being setup.

    let url = server_url
    client = StompClient(url: url)
    client = self
    client.connect()

After you are connected, there are some delegate methods that you need to implement.

#### Delegate Methods
`stompClientDidConnected(client: StompClient)` is called when the client connects to the server.

`stompClient(client: StompClient, didErrorOccurred error: NSError)` is called when error occurs.

`stompClient(client: StompClient, didReceivedData data: NSData, fromDestination destination: String)` is called when the client receive a message from a subscription destination.

#### Subscription
You can use `subscribe(destination: String, parameters: [String : String]?)` method to subscribe a topic.

### Carthage Install
Add the following line into your _Cartfile_,

      github "ShengHuaWu/StompClient"

, and then run `carthage update --platform ios` in your terminal.

### CocoaPods Install
Create a _Podfile_ as following,

    source 'https://github.com/CocoaPods/Specs.git'
    platform :ios, '9.0'
    use_frameworks!

    pod 'StompClient'

, and then run `pod install` in your terminal.
