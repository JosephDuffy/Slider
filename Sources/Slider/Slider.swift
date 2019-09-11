import UIKit

open class Slider: UIControl {

    /// The tint colour of the minimum value track.
    open var minimumTrackTintColor: UIColor? {
        get {
            return foregroundTrackView.tintColor
        }
        set {
            foregroundTrackView.tintColor = newValue
        }
    }

    /// The current value of the lower thumb. This value is pinned `lowerValueRange`.
    open var lowerValue: Float = 0.25 {
        didSet {
            sanitise(value: &lowerValue, allowedRange: lowerValueRange)
            setNeedsLayout()
        }
    }

    /// The current value of the upper thumb. This value is pinned `upperValueRange`.
    open var upperValue: Float = 0.75 {
        didSet {
            sanitise(value: &upperValue, allowedRange: upperValueRange)
            setNeedsLayout()
        }
    }

    /// The minimum value that the lower thumb can be set to.
    open var minimumValue: Float = 0

    /// The maximum value that the upper thumb can be set to.
    open var maximumValue: Float = 1

    /// The current value of the lower thumb, represented as a percentage of the available range. This value will be in
    /// the range 0...100.
    open var lowerValueAsPercentage: Float {
        let range = maximumValue - minimumValue
        return (lowerValue - minimumValue) / range
    }

    /// The current value of the lower thumb, represented as a percentage of the available range. This value will be in
    /// the range 0...100.
    open var upperValueAsPercentage: Float {
        let range = maximumValue - minimumValue
        return (upperValue - minimumValue) / range
    }

    /// The minimum width between the center of each of the thumbs.
    open var minimumThumbsDistance: Float {
        return Float(lowerThumbView.bounds.width)
    }

    /// The minimum difference between the `lowerValue` and `upperValue`. This is restricted by the UI, so a wider
    /// slider will have a smaller minimum value difference.
    open var minimumValueDifference: Float {
        return valueChangePerPoint * minimumThumbsDistance
    }

    /// The allowed range of the lower value. This takes in to account the available visual space of the slider; the
    /// upper bound will be less than the `upperValue`.
    public var lowerValueRange: ClosedRange<Float> {
        return minimumValue...(upperValue - minimumValueDifference)
    }

    /// The allowed range of the upper value. This takes in to account the available visual space of the slider; the
    /// lower bound will be greater than the `lowerValue`.
    public var upperValueRange: ClosedRange<Float> {
        return (lowerValue + minimumValueDifference)...maximumValue
    }

    /// The difference in value that a single point movement of the thumb represents. This will be the minimum change
    /// that can occur.
    public var valueChangePerPoint: Float {
        let range = maximumValue - minimumValue
        return range/Float(thumbTrackBoundingRect.width)
    }

    private let foregroundTrackView = UIImageView(image: nil)
    private let backgroundTrackView = UIImageView(image: nil)
    private let lowerThumbView = UIImageView.thumbImageView(image: nil)
    private let upperThumbView = UIImageView.thumbImageView(image: nil)

    public override init(frame: CGRect) {
        super.init(frame: frame)

        addSubviews()
        copyStyle(of: UISlider())
    }

    public required init(styledAfter slider: UISlider, frame: CGRect) {
        super.init(frame: frame)

        addSubviews()
        copyStyle(of: slider)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        addSubviews()
        copyStyle(of: UISlider())
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layoutForegroundSlider()
        layoutBackgroundTrackView()
        layoutThumbView()
    }

    private func layoutBackgroundTrackView() {
        let backgroundTrackRect = trackRect(forBounds: bounds)
        backgroundTrackView.frame = backgroundTrackRect
    }

    private func layoutForegroundSlider() {
        let backgroundTrackRect = trackRect(forBounds: bounds)
        foregroundTrackView.frame = backgroundTrackRect
        let trackWidth = thumbTrackBoundingRect.width

        let percentageDifference = upperValueAsPercentage - lowerValueAsPercentage
        let minimumTrackWidth = trackWidth * CGFloat(percentageDifference)
        foregroundTrackView.frame.size.width = minimumTrackWidth

        let xOffset = trackWidth * CGFloat(lowerValueAsPercentage)
        let minX = thumbTrackBoundingRect.minX + xOffset
        foregroundTrackView.frame.origin.x = minX

    }

    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 30
        size.width += 4
        return size
    }

    private var thumbTrackBoundingRect: CGRect {
        let visualWidth = bounds.width - (lowerThumbView.bounds.width / 2)
        let trackWidth = trackRect(forBounds: bounds).width
        let availableWidth = min(visualWidth, trackWidth)
        let widthDifference = bounds.width - availableWidth
        assert(widthDifference >= 0, "Thumb track bounding rect should never be greater than the bounds")
        return bounds.insetBy(dx: widthDifference, dy: 0)
    }

    private var thumbImageSize: CGSize {
        return CGSize(width: 31, height: 31)
    }

    private func layoutThumbView() {
        lowerThumbView.frame.size = thumbImageSize
        upperThumbView.frame.size = thumbImageSize

        position(thumb: lowerThumbView, percent: CGFloat(lowerValueAsPercentage))
        position(thumb: upperThumbView, percent: CGFloat(upperValueAsPercentage))
    }

    private func position(thumb: UIImageView, percent: CGFloat) {
        let trackWidth = thumbTrackBoundingRect.width
        let xOffset = trackWidth * percent
        let midX = thumbTrackBoundingRect.minX + xOffset
        thumb.center = CGPoint(x: midX, y: thumbTrackBoundingRect.midY)
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

        let lowerGesture = UIPanGestureRecognizer(target: self, action: #selector(lowerThumbViewGesture))
        lowerThumbView.addGestureRecognizer(lowerGesture)

        let upperGesture = UIPanGestureRecognizer(target: self, action: #selector(upperThumbViewGesture))
        upperThumbView.addGestureRecognizer(upperGesture)
    }

    @objc private func lowerThumbViewGesture(_ recognizer: UIPanGestureRecognizer) {
        handleGesture(recognizer: recognizer, value: &lowerValue, allowedRange: lowerValueRange)
    }

    @objc private func upperThumbViewGesture(_ recognizer: UIPanGestureRecognizer) {
        handleGesture(recognizer: recognizer, value: &upperValue, allowedRange: upperValueRange)
    }

    private func sanitise(value: inout Float, allowedRange: ClosedRange<Float>) {
        // Ensure that the value has not been moved out of the allowable range. The check above
        // ensures it will not be changes once at the extreme, but them ensures a single change doesn't
        // move it past an extreme, e.g. current = 0.99, max = 1.0, change = 0.02 would set value to 1.01
        // then this would clamp it to 1.0
        if value > allowedRange.upperBound {
            value = allowedRange.upperBound
        } else if value < allowedRange.lowerBound {
            value = allowedRange.lowerBound
        }
    }

    private func handleGesture(recognizer: UIPanGestureRecognizer, value: inout Float, allowedRange: ClosedRange<Float>) {
        switch recognizer.state {
        case .changed, .ended:
            let point = recognizer.translation(in: self)

            // Nothing needs to be done if the movement was not big enough to register as a translation
            guard point.x != 0 else { return }

            // Nothing needs to be done if the thumb is already at its min or max position and the change
            // would move it past this point
            if value == allowedRange.upperBound && point.x > 0 {
                return
            } else if value == allowedRange.lowerBound && point.x < 0 {
                return
            }

            value += Float(point.x) * valueChangePerPoint
            recognizer.setTranslation(.zero, in: self)

            // The above checks ensure the min and max values will only be hit once so firing the haptics
            // will only occur once when reaching the end
            if value == minimumValue || value == maximumValue {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        case .cancelled:
            // TODO: Reset to start
            break
        case .began, .possible, .failed:
            break
        @unknown default:
            break
        }
    }

    open func copyStyle(of slider: UISlider) {
        tintColor = slider.tintColor
    }

    func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        thumbImages[state.rawValue] = image

        if self.state == state {
            updateThumbImages()
        }
    }

    private(set) lazy var currentThumbImage: UIImage = Slider.defaultThumbImage()
    private(set) lazy var currentMinimumTrackImage: UIImage = Slider.defaultForegroundValueImage()
    private(set) lazy var currentMaximumTrackImage: UIImage = Slider.defaultBackgroundValueImage()

    open func trackRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect = rect.insetBy(dx: 2, dy: 0)
        rect.origin.y = bounds.midY.rounded(.down)
        rect.size.height = currentMinimumTrackImage.size.height
        return rect
    }

    open override var isHighlighted: Bool {
        didSet {
            updateThumbImages()
        }
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
