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

    /// The current value of the lower thumb.
    open var lowerValue: Float = 0.25

    /// The current value of the upper thumb.
    open var upperValue: Float = 0.75

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
        size.height = 31
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
        backgroundTrackView.tintColor = .lightGray
        backgroundTrackView.clipsToBounds = true
        lowerThumbView.isUserInteractionEnabled = true
        upperThumbView.isUserInteractionEnabled = true

        let lowerGesture = UIPanGestureRecognizer(target: self, action: #selector(lowerThumbViewGesture))
        lowerThumbView.addGestureRecognizer(lowerGesture)

        let upperGesture = UIPanGestureRecognizer(target: self, action: #selector(upperThumbViewGesture))
        upperThumbView.addGestureRecognizer(upperGesture)
    }

    @objc private func lowerThumbViewGesture(_ recognizer: UIPanGestureRecognizer) {
        handleGesture(recognizer: recognizer, value: &lowerValue, allowedRange: minimumValue...(upperValue - minimumValueDifference))
    }

    @objc private func upperThumbViewGesture(_ recognizer: UIPanGestureRecognizer) {
        handleGesture(recognizer: recognizer, value: &upperValue, allowedRange: (lowerValue + minimumValueDifference)...maximumValue)
    }

    private func handleGesture(recognizer: UIPanGestureRecognizer, value: inout Float, allowedRange: ClosedRange<Float>) {
        switch recognizer.state {
        case .changed, .ended:
            let point = recognizer.translation(in: self)
            value += Float(point.x) * valueChangePerPoint
            if value > allowedRange.upperBound {
                value = allowedRange.upperBound
            } else if value < allowedRange.lowerBound {
                value = allowedRange.lowerBound
            }
            recognizer.setTranslation(.zero, in: self)
            setNeedsLayout()
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
        return UIImage(named: "foregroundSliderImage")!
    }

    internal static func defaultBackgroundValueImage() -> UIImage {
        return UIImage(named: "backgroundSliderImage")!
    }

    internal static func defaultThumbImage() -> UIImage {
        return UIImage(named: "thumb")!
    }

}
