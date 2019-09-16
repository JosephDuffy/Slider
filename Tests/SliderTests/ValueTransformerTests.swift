import XCTest
@testable import Slider

final class ValueTransformerTests: XCTestCase {

    private let minimumAccuracy: Float = 0.00001

    func testMinimumAndMaximumPercent() {
        var valueTransformer = ValueTransformer(internalValue: 50, scaling: .linear(0...100))
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
        var valueTransformer = ValueTransformer(internalValue: 50, step: 0.1, scaling: .linear(0...100))
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
    }

}
