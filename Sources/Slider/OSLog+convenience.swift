import os.log

extension OSLog {

    internal func log(_ message: StaticString, type: OSLogType, _ args: CVarArg...) {
        switch args.count {
        case 0:
            os_log(message, log: self, type: type)
        case 1:
            os_log(message, log: self, type: type, args[0])
        case 2:
            os_log(message, log: self, type: type, args[0], args[1])
        case 3:
            os_log(message, log: self, type: type, args[0], args[1], args[2])
        case 4:
            os_log(message, log: self, type: type, args[0], args[1], args[2], args[3])
        default:
            assertionFailure("Too many arguments passed to log. Update this to support this many arguments.")
            os_log(message, log: self, type: type, args[0], args[1], args[2], args[3])
        }
    }

}
