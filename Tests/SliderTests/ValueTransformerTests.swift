import XCTest
@testable import Slider

final class ValueTransformerTests: XCTestCase {

    private let minimumAccuracy: Float = 0.0001

    func testMinimumAndMaximumPercent() {
        var valueTransformer = ValueTransformer(externalValue: 50, scaling: .linear(0...100))
        XCTAssertEqual(valueTransformer.value(for: .internal), 50, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 40
        XCTAssertEqual(valueTransformer.value(for: .internal), 40, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 40, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 100
        XCTAssertEqual(valueTransformer.value(for: .internal), 40, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 40, accuracy: minimumAccuracy)

        valueTransformer.minimumPercent = 60
        XCTAssertEqual(valueTransformer.value(for: .internal), 60, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 60, accuracy: minimumAccuracy)
    }

    func testStep() {
        var valueTransformer = ValueTransformer(externalValue: 50, step: 0.1, scaling: .linear(0...100))
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: minimumAccuracy)

        valueTransformer.set(value: 60.1, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 60.1, accuracy: minimumAccuracy)

        valueTransformer.set(value: 60.09, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 60.1, accuracy: minimumAccuracy)

        valueTransformer.set(value: 60.05, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 60.1, accuracy: minimumAccuracy)

        valueTransformer.set(value: 60.04, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 60, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 40.14
        XCTAssertEqual(valueTransformer.value(for: .external), 40.1, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 40.19
        XCTAssertEqual(valueTransformer.value(for: .external), 40.1, accuracy: minimumAccuracy)

        valueTransformer.step = 1
        XCTAssertEqual(valueTransformer.value(for: .external), 40, accuracy: minimumAccuracy)

        valueTransformer.step = 0.5
        valueTransformer.maximumPercent = 50.3
        valueTransformer.set(value: 50.31, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: minimumAccuracy)

        valueTransformer.step = 0.5
        valueTransformer.minimumPercent = 40.3
        valueTransformer.set(value: 40.1, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 40.5, accuracy: minimumAccuracy)

        valueTransformer.step = 1
        valueTransformer.minimumPercent = 12.062257
        XCTAssertEqual(valueTransformer.lowerBound(for: .external), 13, accuracy: minimumAccuracy)
        valueTransformer.set(value: 12.44358, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 13, accuracy: minimumAccuracy)
    }

    func testSettingMaximumPercentageOnUpperBoarderOfStep() {
        var valueTransformer = ValueTransformer(externalValue: 50, step: 0.1, scaling: .linear(0...100))
        valueTransformer.maximumPercent = 92.99
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 92.9, accuracy: minimumAccuracy)
        valueTransformer.set(value: 92.74358, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 92.7, accuracy: minimumAccuracy)
    }

    func testSettingMaximumPercentageOnLowerBoarderOfStep() {
        var valueTransformer = ValueTransformer(externalValue: 50, step: 0.1, scaling: .linear(0...100))
        valueTransformer.maximumPercent = 92.81
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 92.8, accuracy: minimumAccuracy)
        valueTransformer.set(value: 92.81, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 92.8, accuracy: minimumAccuracy)
    }

    func testSettingExternalValueLessThanOneStepGreaterThanMaximum() {
        var valueTransformer = ValueTransformer(externalValue: 50, step: 0.1, scaling: .linear(0...100))
        valueTransformer.maximumPercent = 92.8
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 92.8, accuracy: minimumAccuracy)
        valueTransformer.set(value: 92.86, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 92.8, accuracy: minimumAccuracy)
    }

    func testSteppedScaling() {
        let scaling = Scaling.stepped([
            0...50: 0...100,
            50...75: 100...200,
            75...90: 200...500,
            90...100: 500...1000,
        ])
        var valueTransformer = ValueTransformer(externalValue: 50, step: 5, scaling: scaling)
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: minimumAccuracy)

        valueTransformer.set(value: 555, from: .external)
        XCTAssertEqual(valueTransformer.value(for: .external), 555, accuracy: minimumAccuracy)

    }

    func testBounds() {
        let scaling = Scaling.stepped([
            0...50: 0...100,
            50...75: 100...200,
            75...90: 200...500,
            90...100: 500...1000,
        ])
        var valueTransformer = ValueTransformer(externalValue: 1000, step: 5, scaling: scaling)

        XCTAssertEqual(valueTransformer.lowerBound(for: .external), 0, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 1000, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 90
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 500, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 500, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 75
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 200, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 200, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 50
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 100, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 100, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 25
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 50, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: minimumAccuracy)

        valueTransformer.maximumPercent = 100
        XCTAssertEqual(valueTransformer.upperBound(for: .external), 1000, accuracy: minimumAccuracy)
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: minimumAccuracy)
    }

}
