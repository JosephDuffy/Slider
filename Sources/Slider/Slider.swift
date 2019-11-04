import UIKit
import os.log

open class Slider: UIControl {

    private var internalLowerValue: ValueTransformer {
        didSet {
            setNeedsLayout()
        }
    }

    private var internalUpperValue: ValueTransformer {
        didSet {
            setNeedsLayout()
        }
    }

    /// The current value of the lower thumb. This value is pinned `lowerValueRange`.
    open var lowerValue: Float {
        get {
            return externalScope.lowerValue
        }
        set {
            internalLowerValue.set(value: newValue, from: .external)
        }
    }

    /// The current value of the upper thumb. This value is pinned `upperValueRange`.
    open var upperValue: Float {
        get {
            return externalScope.upperValue
        }
        set {
            internalUpperValue.set(value: newValue, from: .external)
        }
    }

    /// The minimum value that the lower thumb can be set to.
    open var minimumValue: Float {
        return externalScope.minimumValue
    }

    /// The maximum value that the upper thumb can be set to.
    open var maximumValue: Float {
        return externalScope.maximumValue
    }

    public var scaling: Scaling {
        didSet {
            internalLowerValue.scaling = scaling
            internalUpperValue.scaling = scaling
        }
    }

    open var step: Float? {
        didSet {
            internalLowerValue.step = step
            internalUpperValue.step = step
        }
    }

    private struct Lense {

        private let scope: ValueTransformer.Representation

        private let lowerTransformer: ValueTransformer

        private let upperTransformer: ValueTransformer

        fileprivate var lowerValue: Float {
            return lowerTransformer.value(for: scope)
        }

        fileprivate var upperValue: Float {
            return upperTransformer.value(for: scope)
        }

        fileprivate var minimumValue: Float {
            return lowerTransformer.lowerBound(for: scope)
        }

        fileprivate var maximumValue: Float {
            return upperTransformer.upperBound(for: scope)
        }

        fileprivate var lowerValueAsPercentage: Float {
            let range = maximumValue - minimumValue
            return ((lowerValue - minimumValue) / range) * 100
        }

        fileprivate var upperValueAsPercentage: Float {
            let range = maximumValue - minimumValue
            return ((upperValue - minimumValue) / range) * 100
        }

        public var lowerValueRange: ClosedRange<Float> {
            return lowerTransformer.valueRange(for: scope)
        }

        public var upperValueRange: ClosedRange<Float> {
            return upperTransformer.valueRange(for: scope)
        }

        public var range: ClosedRange<Float> {
            return lowerValueRange.lowerBound...upperValueRange.upperBound
        }

        public var valueDistance: Float {
            return maximumValue - minimumValue
        }

        fileprivate init(scope: ValueTransformer.Representation, lowerTransformer: ValueTransformer, upperTransformer: ValueTransformer) {
            self.scope = scope
            self.lowerTransformer = lowerTransformer
            self.upperTransformer = upperTransformer
        }

    }

    private var internalScope: Lense {
        return Lense(scope: .internal, lowerTransformer: internalLowerValue, upperTransformer: internalUpperValue)
    }

    private var externalScope: Lense {
        return Lense(scope: .external, lowerTransformer: internalLowerValue, upperTransformer: internalUpperValue)
    }

    /// The current value of the lower thumb, represented as a percentage of the available range. This value will be in
    /// the range 0...100.
    public var lowerValueAsPercentage: Float {
        return internalScope.lowerValueAsPercentage
    }

    /// The current value of the lower thumb, represented as a percentage of the available range. This value will be in
    /// the range 0...100.
    public var upperValueAsPercentage: Float {
        return internalScope.upperValueAsPercentage
    }

    /// The minimum width between the center of each of the thumbs.
    open var minimumThumbsDistance: Float {
        return Float(lowerThumbView.bounds.width)
    }

    /// The allowed range of the lower value. This takes in to account the available visual space of the slider; the
    /// upper bound will be less than the `upperValue`.
    public var lowerValueRange: ClosedRange<Float> {
        return externalScope.lowerValueRange
    }

    /// The allowed range of the upper value. This takes in to account the available visual space of the slider; the
    /// lower bound will be greater than the `lowerValue`.
    public var upperValueRange: ClosedRange<Float> {
        return externalScope.upperValueRange
    }

    /// The difference in value that a single point movement of the lower thumb represents. This will be the minimum
    /// change that can occur.
    private var lowerThumbValueChangePerPoint: Float {
        return internalScope.valueDistance / Float(lowerThumbBoundingRect.width)
    }

    /// The difference in value that a single point movement of the upper thumb represents. This will be the minimum
    /// change that can occur.
    private var upperThumbValueChangePerPoint: Float {
        return internalScope.valueDistance / Float(upperThumbBoundingRect.width)
    }

    /// The tint colour of the foreground track.
    open override var tintColor: UIColor! {
        set {
            foregroundTrackView.tintColor = newValue
            super.tintColor = newValue
        }
        get {
            return super.tintColor
        }
    }

    /// The tint colour of the background track.
    open var minimumTrackTintColor: UIColor? {
        get {
            return backgroundTrackView.tintColor
        }
        set {
            backgroundTrackView.tintColor = newValue
        }
    }

    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 30
        size.width += 4
        return size
    }

    open override var isHighlighted: Bool {
        didSet {
            updateThumbImages()
        }
    }

    open override var bounds: CGRect {
        didSet {
            updateMinimumAndMaximumSliderValues()
        }
    }

    public var log: OSLog? {
        didSet {
            internalLowerValue.log = log
            internalUpperValue.log = log
        }
    }

    private let foregroundTrackView = UIImageView(image: nil)
    private let backgroundTrackView = UIImageView(image: nil)
    private let lowerThumbView = UIImageView.thumbImageView(image: nil)
    private let upperThumbView = UIImageView.thumbImageView(image: nil)

    private(set) lazy var currentThumbImage: UIImage = Slider.defaultThumbImage()
    private(set) lazy var currentMinimumTrackImage: UIImage = Slider.defaultForegroundValueImage()
    private(set) lazy var currentMaximumTrackImage: UIImage = Slider.defaultBackgroundValueImage()

    public override init(frame: CGRect) {
        scaling = .linear(0...100)
        internalLowerValue = .init(externalValue: 25, scaling: scaling)
        internalUpperValue = .init(externalValue: 75, scaling: scaling)

        super.init(frame: frame)

        backgroundColor = nil
        addSubviews()
        copyStyle(of: UISlider())
    }

    public required init(styledAfter slider: UISlider, frame: CGRect, scaling: Scaling = .linear(0...100)) {
        self.scaling = scaling
        internalLowerValue = .init(externalValue: 25, scaling: scaling)
        internalUpperValue = .init(externalValue: 75, scaling: scaling)

        super.init(frame: frame)

        backgroundColor = nil
        addSubviews()
        copyStyle(of: slider)
    }

    public required init?(coder aDecoder: NSCoder) {
        scaling = .linear(0...100)
        internalLowerValue = .init(externalValue: 25, scaling: scaling)
        internalUpperValue = .init(externalValue: 75, scaling: scaling)

        super.init(coder: aDecoder)

        backgroundColor = nil
        addSubviews()
        copyStyle(of: UISlider())
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layoutForegroundSlider()
        layoutBackgroundTrackView()
        layoutThumbView()
    }

    open func copyStyle(of slider: UISlider) {
        tintColor = slider.tintColor
    }

    public func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        thumbImages[state.rawValue] = image

        if self.state == state {
            updateThumbImages()
        }
    }

    open func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect = rect.insetBy(dx: 2, dy: 0)
        rect.origin.y = bounds.midY.rounded(.down)
        rect.size.height = currentMinimumTrackImage.size.height
        return rect
    }

    private func updateMinimumAndMaximumSliderValues() {
        internalLowerValue.maximumPercent = upperValueAsPercentage
        internalUpperValue.minimumPercent = lowerValueAsPercentage
    }

    private func layoutBackgroundTrackView() {
        let backgroundTrackRect = trackRect(forBounds: bounds)
        backgroundTrackView.frame = backgroundTrackRect
    }

    private func layoutForegroundSlider() {
        let backgroundTrackRect = trackRect(forBounds: bounds)
        foregroundTrackView.frame = backgroundTrackRect
        foregroundTrackView.frame.origin.x = lowerThumbView.center.x
        foregroundTrackView.frame.size.width = upperThumbView.center.x - lowerThumbView.center.x
    }

    private var thumbTrackBoundingRect: CGRect {
        let visualWidth = bounds.width - (lowerThumbView.bounds.width / 2)
        let trackWidth = trackRect(forBounds: bounds).width
        let availableWidth = min(visualWidth, trackWidth)
        let widthDifference = bounds.width - availableWidth
        assert(widthDifference >= 0, "Thumb track bounding rect should never be greater than the bounds")
        return bounds.insetBy(dx: widthDifference, dy: 0)
    }

    private var lowerThumbBoundingRect: CGRect {
        return thumbTrackBoundingRect.inset(
            by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: upperThumbView.bounds.width)
        )
    }

    private var upperThumbBoundingRect: CGRect {
        return thumbTrackBoundingRect.inset(
            by: UIEdgeInsets(top: 0, left: lowerThumbView.bounds.width, bottom: 0, right: 0)
        )
    }

    private var thumbImageSize: CGSize {
        return CGSize(width: 31, height: 31)
    }

    private func layoutThumbView() {
        lowerThumbView.frame.size = thumbImageSize
        upperThumbView.frame.size = thumbImageSize

        position(
            thumb: lowerThumbView,
            percent: CGFloat(lowerValueAsPercentage),
            in: lowerThumbBoundingRect
        )
        position(
            thumb: upperThumbView,
            percent: CGFloat(upperValueAsPercentage),
            in: upperThumbBoundingRect
        )
    }

    private func position(thumb: UIImageView, percent: CGFloat, in rect: CGRect) {
        let trackWidth = rect.width
        let xOffset = trackWidth * (percent / 100)
        let midX = rect.minX + xOffset
        thumb.center = CGPoint(x: midX, y: rect.midY)
    }

    private func addSubviews() {
        updateThumbImages()
        updateMinimumTrackImage()
        updateMaximumTrackImage()

        addSubview(backgroundTrackView)
        addSubview(foregroundTrackView)
        addSubview(lowerThumbView)
        addSubview(upperThumbView)
        foregroundTrackView.tintColor = tintColor
        foregroundTrackView.clipsToBounds = true
        backgroundTrackView.clipsToBounds = true
        lowerThumbView.isUserInteractionEnabled = true
        upperThumbView.isUserInteractionEnabled = true

        updateMinimumAndMaximumSliderValues()
    }

    private var trackedTouchesInitialLocations: [UITouch: CGPoint] = [:]

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            // TODO: Store initial value to be used in calculation. This will enable tracking the exact valeu change so
            // the thumb is always under the user's finger. This would require a function along the lines of `update`
            // that instead calculates the difference between the initial position and the current position, taking in
            // to account the step etc. This value can then be checked against the current value and – if different –
            // updated, triggering haptics etc.
            trackedTouchesInitialLocations[touch] = touch.location(in: self)
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            guard let initialLocation = trackedTouchesInitialLocations[touch] else {
                assertionFailure("There should always be an initial location for a touch that has moved")
                break
            }

            let currentLocation = touch.location(in: self)
            let movement = currentLocation.x - initialLocation.x

            let valueDidUpdate: Bool

            switch touch.view {
            case lowerThumbView:
                valueDidUpdate = update(
                    value: \.internalLowerValue,
                    valueChangePerPoint: lowerThumbValueChangePerPoint,
                    pointsMoved: movement
                )
            case upperThumbView:
                valueDidUpdate = update(
                    value: \.internalUpperValue,
                    valueChangePerPoint: upperThumbValueChangePerPoint,
                    pointsMoved: movement
                )
            default:
                continue
            }

            if valueDidUpdate {
                trackedTouchesInitialLocations[touch] = currentLocation
                updateMinimumAndMaximumSliderValues()
                setNeedsLayout()
                layoutIfNeeded()
            }
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { trackedTouchesInitialLocations.removeValue(forKey: $0) }
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: Revert to initial location?
        touches.forEach { trackedTouchesInitialLocations.removeValue(forKey: $0) }
    }

    private func update(
        value valueKeyPath: ReferenceWritableKeyPath<Slider, ValueTransformer>,
        valueChangePerPoint: Float,
        pointsMoved: CGFloat
    ) -> Bool {
        // Nothing needs to be done if the movement was not big enough to register as a translation
        guard pointsMoved != 0 else { return false }

        let allowedRange = self[keyPath: valueKeyPath].valueRange(for: .internal)

        var value: Float {
            get {
                return self[keyPath: valueKeyPath].value(for: .internal)
            }
            set {
                self[keyPath: valueKeyPath].set(value: newValue, from: .internal)
            }
        }

        // Nothing needs to be done if the thumb is already at its min or max position and the change
        // would move it past this point
        if value == allowedRange.upperBound && pointsMoved > 0 {
            return false
        } else if value == allowedRange.lowerBound && pointsMoved < 0 {
            return false
        }

        let internalValueChange = Float(pointsMoved) * valueChangePerPoint
        log?.log("internalValueChange %{public}@", type: .debug, "\(internalValueChange)")
        let proposedInternalValue =
            min(
                max(value + internalValueChange, allowedRange.lowerBound),
                allowedRange.upperBound
            )
        log?.log("Proposed internal value: %{public}@", type: .debug, "\(proposedInternalValue)")

        if let step = self.step {
            var proposedValueTransformer = ValueTransformer(internalValue: proposedInternalValue, step: nil, scaling: self[keyPath: valueKeyPath].scaling)
            let proposedExternalValue = proposedValueTransformer.value(for: .external)
            log?.log("Proposed external value: %{public}@", type: .debug, "\(proposedExternalValue)")

            let proposedExternalChange = value - proposedExternalValue

            guard abs(proposedExternalChange) >= abs(step) else {
                log?.log("Proposed value change of %{public}@ was less than step %{public}@", type: .debug, "\(abs(proposedExternalChange))", "\(abs(step))")
                return false
            }

            proposedValueTransformer.step = self[keyPath: valueKeyPath].step
            self[keyPath: valueKeyPath].set(value: proposedValueTransformer.value(for: .external), from: .external)
        } else {
            value = proposedInternalValue
        }

        log?.log("Value updated to %{public}@", type: .debug, "\(value)")

        sendActions(for: .valueChanged)

        // The above checks ensure the min and max values will only be hit once so firing the haptics
        // will only occur once when reaching the end
        if value == internalLowerValue.lowerBound(for: .internal) || value == internalUpperValue.upperBound(for: .internal) {
            log?.log("Triggering selection changed haptics", type: .debug)
            UISelectionFeedbackGenerator().selectionChanged()
        }

        return true
    }

    private var thumbImages: [UIControl.State.RawValue: UIImage] = [:]

    private func updateThumbImages() {
        currentThumbImage = thumbImages[state.rawValue] ?? Slider.defaultThumbImage()
        lowerThumbView.image = currentThumbImage
        upperThumbView.image = currentThumbImage
    }

    private func updateMinimumTrackImage() {
        foregroundTrackView.image = currentMinimumTrackImage
        setNeedsLayout()
    }

    private func updateMaximumTrackImage() {
        backgroundTrackView.image = currentMaximumTrackImage
        setNeedsLayout()
    }

}

extension Slider {

    internal static func defaultForegroundValueImage() -> UIImage {
        return UIImage(named: "foregroundSliderImage", in: Bundle(for: Slider.self), compatibleWith: nil)!
    }

    internal static func defaultBackgroundValueImage() -> UIImage {
        return UIImage(named: "backgroundSliderImage", in: Bundle(for: Slider.self), compatibleWith: nil)!
    }

    internal static func defaultThumbImage() -> UIImage {
        return UIImage(named: "thumb", in: Bundle(for: Slider.self), compatibleWith: nil)!
    }

}
