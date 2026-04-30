//
//  Thread.swift
//  SBTUITestTunnel
//
//  Created by Rinat Enikeev on 10.02.2026.
//

import Foundation

open class SBUITestThread: NSObject {
    public var thread: Thread!
    private var block: (() -> Void)?

    override public init() {}

    @objc func runBlock() {
        autoreleasepool {
            block?()
        }
    }

    open func start(_ block: @escaping () -> Void) {
        self.block = block

        let threadName = String(describing: self)
            .components(separatedBy: .punctuationCharacters)[1]

        thread = Thread { [weak self] in
            defer { self?.block = nil }
            while !(self?.thread.isCancelled ?? true) {
                RunLoop.current.run(
                    mode: RunLoop.Mode.default,
                    before: Date.distantFuture
                )
            }
        }
        thread.name = "\(threadName)-\(UUID().uuidString)"
        thread.start()

        perform(
            #selector(runBlock),
            on: thread,
            with: nil,
            waitUntilDone: false,
            modes: [RunLoop.Mode.default.rawValue]
        )
    }

    public func stopWork() {
        block = nil
        perform(
            #selector(stopThread),
            on: thread,
            with: nil,
            waitUntilDone: false,
            modes: [RunLoop.Mode.default.rawValue]
        )
    }

    @objc func stopThread() {
        thread.cancel()
    }
}
