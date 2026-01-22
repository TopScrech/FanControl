import Foundation
import OSLog

let logger = Logger(subsystem: "FanControl", category: "SMCHelper")
logger.info("Starting FanControlHelper")

let delegate = FanControlHelperDelegate()
let listener = NSXPCListener(machServiceName: FanControlXPCConstants.machServiceName)
listener.delegate = delegate
listener.resume()

RunLoop.current.run()
