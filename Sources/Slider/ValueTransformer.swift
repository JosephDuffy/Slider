import Foundation
import os.log

internal struct ValueTransformer {

    internal enum Representation {
        case `internal`
        case external
    }

    internal var scaling: Scaling {
        didSet {
            sanitise()
        }
    }

    internal var step: Float? {
        didSet {
            sanitise()
        }
    }

    /// The minimum percent of the available range the value is capped to. In the range 0...100.
    internal var minimumPercent: Float = 0 {
        didSet {
            assert(minimumPercent >= 0, "Cannot set a negative minimum percent")
            assert(minimumPercent <= maximumPercent, "Cannot set a minimum percent greater than maximum percent")
            log?.log("Minimum percent set to %{public}@%%", type: .debug, "\(minimumPercent)")
            sanitise()
        }
    }

    /// The maximum percent of the available range the value is capped to. In the range 0...100.
    internal var maximumPercent: Float = 100 {
        didSet {
            assert(maximumPercent <= 100, "Cannot set a maximum percent greater than 100")
            assert(maximumPercent >= minimumPercent, "Cannot set a maximum percent less than minimum percent")
            log?.log("Maximum percent set to %{public}@%%", type: .debug, "\(maximumPercent)")
            sanitise()
        }
    }

    private var internalValue: Float

    internal var log: OSLog?

    internal init(internalValue: Float, step: Float? = nil, scaling: Scaling) {
        step.map { assert($0 > 0, "Step must be greater than 0") }

        self.internalValue = internalValue
        self.step = step
        self.scaling = scaling
    }

    internal func value(for representation: Representation) -> Float {
        switch representation {
        case .internal:
            return internalValue
        case .external:
            return transformInternalValue(internalValue)
        }
    }

    internal mutating func set(value: Float, from representation: Representation) {
        switch representation {
        case .internal:
            internalValue = value
            sanitise()
        case .external:
            internalValue = transformExternalValue(value)
            sanitise()
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
            return transformInternalValue(internalLowerBound)
        }
    }

    internal func upperBound(for representation: Representation) -> Float {
        let internalUpperBound = min(scaling.inputUpperBound, scaling.inputUpperBound * (maximumPercent / 100))
        switch representation {
        case .internal:
            return internalUpperBound
        case .external:
            return transformInternalValue(internalUpperBound)
        }
    }

    private mutating func sanitise() {
        log?.log("Sanitising %{public}@", type: .debug, "\(internalValue)")

        var value = internalValue

        var roundingRule: FloatingPointRoundingRule = .toNearestOrAwayFromZero

        // Ensure that the value has not been moved out of the allowable range. The check above
        // ensures it will not be changes once at the extreme, but them ensures a single change doesn't
        // move it past an extreme, e.g. current = 0.99, max = 1.0, change = 0.02 would set value to 1.01
        // then this would clamp it to 1.0
        if value > upperBound(for: .internal) {
            log?.log("Value was great than upper bound %{public}@", type: .debug, "\(upperBound(for: .internal))")
            value = upperBound(for: .internal)
            roundingRule = .down
        } else if value < lowerBound(for: .internal) {
            log?.log("Value was less than lower bound %{public}@", type: .debug, "\(lowerBound(for: .internal))")
            value = lowerBound(for: .internal)
            roundingRule = .up
        }

        if let step = step {
            log?.log("Rounding to nearest %{public}@ using %{public}@", type: .debug, "\(step)", "\(roundingRule)")
            value = (Float(value)/step).rounded(roundingRule) * step

            if value > upperBound(for: .internal) {
                log?.log("Value was great than upper bound after rounding %{public}@", type: .debug, "\(upperBound(for: .internal))")
                value -= step
            } else if value < lowerBound(for: .internal) {
                log?.log("Value was less than lower bound after rounding %{public}@", type: .debug, "\(lowerBound(for: .internal))")
                value += step
            }
        }

        guard internalValue != value else { return }

        log?.log("Sanitised value has changed from %{public}@ to %{public}@", type: .debug, "\(internalValue)", "\(value)")

        internalValue = value
    }

    private func transformInternalValue(_ internalValue: Float) -> Float {
        switch scaling {
        case .linear:
            return internalValue
        case let .stepped(boundries):
            guard let (inputRange, outputRange) = boundries.first(where: { $0.key.contains(internalValue) }) else {
                return internalValue
            }

            return transformValue(internalValue, in: inputRange, to: outputRange)
        }
    }

    private func transformExternalValue(_ externalValue: Float) -> Float {
        switch scaling {
        case .linear:
            return externalValue
        case let .stepped(boundries):
            guard let (outputRange, inputRange) = boundries.first(where: { $0.value.contains(externalValue) }) else {
                return externalValue
            }

            return transformValue(externalValue, in: inputRange, to: outputRange)
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
