//
//  Channel.swift
//  Shout
//
//  Created by Jake Heiser on 3/4/18.
//

import CSSH
import Foundation

class Channel {
    
    private static let session = "session"
    private static let exec = "exec"
    
    private static let windowDefault: UInt32 = 2 * 1024 * 1024
    private static let packetDefault: UInt32 = 32768
    private static let bufferSize = 0x4000
    
    private let cSession: OpaquePointer
    private let cChannel: OpaquePointer

    private var closed = false    
    private let syncQueue = DispatchQueue(label: String(describing: Channel.self))
    
    init(cSession: OpaquePointer) throws {
        guard let cChannel = libssh2_channel_open_ex(cSession,
                                                     Channel.session,
                                                     UInt32(Channel.session.count),
                                                     Channel.windowDefault,
                                                     Channel.packetDefault, nil, 0) else {
                                                        throw LibSSH2Error(code: -1, session: cSession)
        }
        self.cSession = cSession
        self.cChannel = cChannel
    }
    
    func requestPty(type: String) throws {
        let code = libssh2_channel_request_pty_ex(cChannel,
                                                  type, UInt32(type.utf8.count),
                                                  nil, 0,
                                                  LIBSSH2_TERM_WIDTH, LIBSSH2_TERM_HEIGHT,
                                                  LIBSSH2_TERM_WIDTH_PX, LIBSSH2_TERM_WIDTH_PX)
        try LibSSH2Error.check(code: code, session: cSession)
    }
    
    func exec(command: String) throws {
        let code = libssh2_channel_process_startup(cChannel,
                                                   Channel.exec,
                                                   UInt32(Channel.exec.count),
                                                   command,
                                                   UInt32(command.count))
        try LibSSH2Error.check(code: code, session: cSession)
    }
    
    func readData() throws -> (data: Data, bytes: Int) {
        return try syncQueue.sync { () -> (data: Data, bytes: Int) in
            var data = Data(repeating: 0, count: Channel.bufferSize)
            
            let rc: Int = data.withUnsafeMutableBytes { (buffer: UnsafeMutablePointer<Int8>) in
                return libssh2_channel_read_ex(cChannel, 0, buffer, Channel.bufferSize)
            }
            
            try LibSSH2Error.checkOnRead(code: Int32(rc), session: cSession)
            
            return closed ? (Data(), 0) : (data, rc)
        }
    }
    
    func close() throws {
        try syncQueue.sync {
            self.closed = true
            let code = libssh2_channel_close(cChannel)
            try LibSSH2Error.check(code: code, session: cSession)
        }
    }
    
    func waitClosed() throws {
        let code2 = libssh2_channel_wait_closed(cChannel)
        try LibSSH2Error.check(code: code2, session: cSession)
    }
    
    func exitStatus() -> Int32 {
        return libssh2_channel_get_exit_status(cChannel)
    }
    
    deinit {
        libssh2_channel_free(cChannel)
    }
}
