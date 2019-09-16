import XCTest
@testable import Slider

final class ValueTransformerTests: XCTestCase {

    func testMinimumAndMaximumPercent() {
        var valueTransformer = ValueTransformer(internalValue: 50, scaling: .linear(0...100))
        XCTAssertEqual(valueTransformer.value(for: .internal), 50, accuracy: 0.1)
        XCTAssertEqual(valueTransformer.value(for: .external), 50, accuracy: 0.1)

        valueTransformer.maximumPercent = 40
        XCTAssertEqual(valueTransformer.value(for: .internal), 40, accuracy: 0.1)
        XCTAssertEqual(valueTransformer.value(for: .external), 40, accuracy: 0.1)

        valueTransformer.maximumPercent = 100
        XCTAssertEqual(valueTransformer.value(for: .internal), 40, accuracy: 0.1)
        XCTAssertEqual(valueTransformer.value(for: .external), 40, accuracy: 0.1)

        valueTransformer.minimumPercent = 60
        XCTAssertEqual(valueTransformer.value(for: .internal), 60, accuracy: 0.1)
        XCTAssertEqual(valueTransformer.value(for: .external), 60, accuracy: 0.1)
    }

}
