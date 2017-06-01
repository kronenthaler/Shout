import Foundation

public protocol SSHAuthMethod {
     func authenticate(username: String, session: SSH.Session) throws
}

extension SSH {

    public struct Password: SSHAuthMethod {

        let password: String

        public init(_ password: String) {
            self.password = password
        }

        public func authenticate(username: String, session: Session) throws {
            try session.rawSession.authenticate(username: username, password: password)
        }

    }

    public struct Agent: SSHAuthMethod {

        public func authenticate(username: String, session: Session) throws {
            let agent = try session.rawSession.agent()
            try agent.connect()
            try agent.listIdentities()
                
            var last: RawAgentPublicKey? = nil
            var success: Bool = false
            while let identity = try agent.getIdentity(last: last) {
                if agent.authenticate(username: username, key: identity) {
                        success = true
                        break
                    }
                    last = identity
                }
                guard success else {
                    throw Error.authError
                }
        }

    }
    
    public struct Key: SSHAuthMethod {
        
        public let privateKey: String
        public let publicKey: String
        public let passphrase: String?

        public init(privateKey: String, publicKey: String? = nil, passphrase: String? = nil) {
            self.privateKey = (privateKey as NSString).expandingTildeInPath
            if let publicKey = publicKey {
                self.publicKey = (publicKey as NSString).expandingTildeInPath
            } else {
                self.publicKey = self.privateKey + ".pub"
            }
            self.passphrase = passphrase
        }

        public func authenticate(username: String, session: Session) throws {
            if let passphrase = passphrase {
                try session.rawSession.authenticate(username: username,
                                            privateKey: privateKey,
                                            publicKey: publicKey,
                                            passphrase: passphrase)
            } else {
                do {
                    try Agent().authenticate(username: username, session: session)
                    return
                 } catch {}
                 do {
                    try session.rawSession.authenticate(username: username,
                                            privateKey: privateKey,
                                            publicKey: publicKey,
                                            passphrase: nil)
                    return
                 } catch {}
                 let passphrase = String(cString: getpass("Enter passphrase for \(privateKey) (empty for no passphrase):"))
                 try session.rawSession.authenticate(username: username,
                                            privateKey: privateKey,
                                            publicKey: publicKey,
                                            passphrase: passphrase)
            }
              
        }
        
    }

}