# Shout
SSH made easy in Swift
```swift
import Shout

let session = try SSH.Session(host: "example.com")
try session.authenticate(username: "user", privateKey: "~/.ssh/id_rsa")
try session.execute("ls -a")
try session.execute("pwd")
...
```

## Installation
Add Shout as a dependency to your project:
```swift
dependencies: [
    .Package(url: "https://github.com/jakeheis/Shout", majorVersion: 0, minor: 2)
]
```

## Usage

### Creating a session
You create a session by passing a host and optionally a port (default 22):
```swift
let session = try SSH.Session(host: "example.com")
// or
let session = try SSH.Session(host: "example.com", port: 22)
```

### Authenticating

You can authenticate with a private key, a password, or an agent.

#### Private key

To authenticate with a private key, you must pass the username and the path to the private key. You can also pass the path to the public key (defaults to the private key path + ".pub") and the passphrase encrypting the key (defaults to nil for no passphrase)

```swift
session.authenticate(username: "user", privateKey: "~/.ssh/id_rsa")
// or
session.authenticate(username: "user", privateKey: "~/.ssh/id_rsa", publicKey: "~/.ssh/id_rsa.pub", passphrase: "passphrase")
```

#### Password
Simply pass the username and password:
```swift
session.authenticate(username: "user", password: "password")
```

#### Agent
If you've already added the necessary private key to ssh-agent, you can authenticate using the agent:
```swift
session.authenticateByAgent(username: "user")
```

### Executing commands

You can remotely execute a command one of two ways. `server.execute` will print the output of the command to stdout and return the status of the command, while `server.capture` will not print anything to stdout and will return both the status and the output of the command as a string.
```swift
let status = try session.execute("ls -a")
let (status, output) = try session.capture("pwd")
```

### Configuration

You can instruct the session to request a pty (pseudo terminal) before executing commands:
```swift
session.ptyType = .vanilla
```