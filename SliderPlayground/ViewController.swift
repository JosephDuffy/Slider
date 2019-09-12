import UIKit
import Slider
import os.log

class ViewController: UIViewController {

    @IBOutlet private var uiSlider: UISlider!
    @IBOutlet private var slider: Slider!

    override func viewDidLoad() {
        super.viewDidLoad()

        slider.log = OSLog(subsystem: "com.thread.SliderPlayground", category: "slider")
    }

}
