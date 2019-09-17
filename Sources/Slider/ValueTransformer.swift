import Foundation
import os.log

internal struct ValueTransformer {

    internal enum Representation {
        case `internal`
        case external
    }

    internal var scaling: Scaling {
        didSet {
            log?.log("Scaling updated from %{public}@ to %{public}@", type: .debug, "\(oldValue)", "\(scaling)")

            let previousValueAsPercent = internalValue / (oldValue.inputUpperBound - oldValue.inputLowerBound)

            log?.log("Previous value was internalValue (%{public}@%%) in range %{public}@", type: .debug, "\(previousValueAsPercent * 100)", "\(oldValue.inputUpperBound - oldValue.inputLowerBound)")

            let newInternalValue = (scaling.inputUpperBound - scaling.inputLowerBound) * previousValueAsPercent
            internalValue = newInternalValue

            log?.log("New value is %{public}@", type: .debug, "\(value(for: .external))")
        }
    }

    internal var step: Float?

    /// The minimum percent of the available range the value is capped to. In the range 0...100.
    internal var minimumPercent: Float = 0 {
        didSet {
            assert(minimumPercent >= 0, "Cannot set a negative minimum percent")
            assert(minimumPercent <= maximumPercent, "Cannot set a minimum percent greater than maximum percent")
            log?.log("Minimum percent set to %{public}@%%", type: .debug, "\(minimumPercent)")

            if internalValue < lowerBound(for: .internal) {
                internalValue = lowerBound(for: .internal)
            }
        }
    }

    /// The maximum percent of the available range the value is capped to. In the range 0...100.
    internal var maximumPercent: Float = 100 {
        didSet {
            assert(maximumPercent <= 100, "Cannot set a maximum percent greater than 100")
            assert(maximumPercent >= minimumPercent, "Cannot set a maximum percent less than minimum percent")
            log?.log("Maximum percent set to %{public}@%%", type: .debug, "\(maximumPercent)")

            if internalValue > upperBound(for: .internal) {
                internalValue = upperBound(for: .internal)
            }
        }
    }

    private var internalValue: Float

    internal var log: OSLog?

    internal init(externalValue: Float, step: Float? = nil, scaling: Scaling) {
        step.map { assert($0 > 0, "Step must be greater than 0") }

        self.internalValue = 0
        self.step = step
        self.scaling = scaling

        self.internalValue = transformExternalValue(externalValue)
    }

    internal func value(for representation: Representation) -> Float {
        switch representation {
        case .internal:
            return internalValue
        case .external:
            let transformedValue = transformInternalValue(internalValue)
            return sanitise(externalValue: transformedValue)
        }
    }

    /**
     Update the stored value. The set value will be pinned to within the upper and lower bounds.

     - parameter value: The new value.
     - parameter representation: The scope that this vlaue represents.
     */
    internal mutating func set(value: Float, from representation: Representation) {
        switch representation {
        case .internal:
            internalValue = value
        case .external:
            internalValue = transformExternalValue(value)
        }

        if internalValue > upperBound(for: .internal) {
            internalValue = upperBound(for: .internal)
        } else if internalValue < lowerBound(for: .internal) {
            internalValue = lowerBound(for: .internal)
        }
    }

    internal func valueRange(for representation: Representation) -> ClosedRange<Float> {
        switch representation {
        case .internal:
            return lowerBound(for: representation)...upperBound(for: .internal)
        case .external:
            return lowerBound(for: representation)...upperBound(for: .internal)
        }
    }

    internal func lowerBound(for representation: Representation) -> Float {
        let internalLowerBound = max(scaling.inputLowerBound, scaling.inputUpperBound * (minimumPercent / 100))
        switch representation {
        case .internal:
            return internalLowerBound
        case .external:
            let unboundOutputValue = transformInternalValue(internalLowerBound)

            if let step = step {
                let rounded = (Float(unboundOutputValue)/step).rounded(.up) * step
                if transformExternalValue(rounded) < internalLowerBound {
                    return rounded + step
                } else {
                    return rounded
                }
            } else {
                return unboundOutputValue
            }
        }
    }

    internal func upperBound(for representation: Representation) -> Float {
        let internalUpperBound = min(scaling.inputUpperBound, scaling.inputUpperBound * (maximumPercent / 100))
        switch representation {
        case .internal:
            return internalUpperBound
        case .external:
            let unboundOutputValue = transformInternalValue(internalUpperBound)

            if let step = step {
                let rounded = (Float(unboundOutputValue)/step).rounded() * step
                if transformExternalValue(rounded) > internalUpperBound {
                    return rounded - step
                } else {
                    return rounded
                }
            } else {
                return unboundOutputValue
            }
        }
    }

    private func sanitise(externalValue: Float) -> Float {
        log?.log("Sanitising %{public}@", type: .debug, "\(internalValue)")

        var value = externalValue

        if let step = step {
            log?.log("Rounding to nearest %{public}@", type: .debug, "\(step)")
            value = (Float(value)/step).rounded() * step
        }

        if value > upperBound(for: .external) {
            log?.log("Value was great than upper bound %{public}@", type: .debug, "\(upperBound(for: .external))")
            value = upperBound(for: .external)
        } else if value < lowerBound(for: .external) {
            log?.log("Value was less than lower bound %{public}@", type: .debug, "\(lowerBound(for: .external))")
            value = lowerBound(for: .external)
        }

        log?.log("Sanitised value has changed from %{public}@ to %{public}@", type: .debug, "\(self.value(for: .external))", "\(value)")

        return value
    }

    private func transformInternalValue(_ internalValue: Float) -> Float {
        let transformedValue: Float

        switch scaling {
        case .linear:
            transformedValue = internalValue
        case let .stepped(boundries):
            guard let (internalRange, externalRange) = boundries.first(where: { $0.key.contains(internalValue) }) else {
                assertionFailure("Internal value should be within one of the boundries")
                return internalValue
            }

            transformedValue = transformValue(internalValue, in: internalRange, to: externalRange)
        }

        return transformedValue
    }

    private func transformExternalValue(_ externalValue: Float) -> Float {
        switch scaling {
        case .linear:
            return externalValue
        case let .stepped(boundries):
            guard let (internalRange, externalRange) = boundries.first(where: { $0.value.contains(externalValue) }) else {
                assertionFailure("External value should be within one of the boundries")
                return externalValue
            }

            return transformValue(externalValue, in: externalRange, to: internalRange)
        }
    }

    private func transformValue(
        _ value: Float,
        in inputRange: ClosedRange<Float>,
        to outputRange: ClosedRange<Float>
    ) -> Float {
        let inputLength = inputRange.upperBound - inputRange.lowerBound
        let percentInRange = (value - inputRange.lowerBound) / inputLength
        let outputLength = outputRange.upperBound - outputRange.lowerBound

        return percentInRange * outputLength + outputRange.lowerBound
    }

}
