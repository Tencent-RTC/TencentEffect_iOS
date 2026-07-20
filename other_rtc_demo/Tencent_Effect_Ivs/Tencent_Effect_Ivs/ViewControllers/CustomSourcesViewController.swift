//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast
import AVFoundation
 

class CustomSourcesViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    @IBOutlet private var endpointField: UITextField!
    @IBOutlet private var streamKeyField: UITextField!
    @IBOutlet private var startButton: UIButton!
    
    
    @IBOutlet private var previewView: UIView!
    @IBOutlet private var beautyPanelLayout: UIView!
    @IBOutlet private var connectionView: UIView!
    @IBOutlet private var labelSoundDb: UILabel!
    
    @IBOutlet private var applyFilterButton: UIButton!
    
    // State management
    private var isRunning = false {
        didSet {
            startButton.setTitle(isRunning ? "Stop" : "Start", for: .normal)
        }
    }
    
    // private var filterHelper: FilterHelper?
    private var teFilter: TEFilter?
    
    // This broadcast session is the main interaction point with the SDK
    private var broadcastSession: IVSBroadcastSession?

    private var customAudioSource: IVSCustomAudioSource?
    private var customImageSource: IVSCustomImageSource?

    private var audioOutput: AVCaptureOutput?
    private var videoOutput: AVCaptureOutput?

    private var captureSession: AVCaptureSession?

    private var orientation: AVCaptureVideoOrientation = .portrait

    private let queue = DispatchQueue(label: "media-queue")
    
    private(set) lazy var teBeautyKit: TEBeautyKit? = nil;
    private(set) lazy var tePanelView: TEPanelView = {
        let view = TEPanelView()
        view.delegate = self
        return view
    }()
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // The SDK will not handle disabling the idle timer for you because that might
        // interfere with your application's use of this API elsewhere.
        UIApplication.shared.isIdleTimerDisabled = true

        checkAVPermissions { [weak self] granted in
            if granted {
                if self?.broadcastSession == nil {
                    self?.setupSession()
                }
            } else {
                self?.displayPermissionError()
            }
        }
        
        
        beautyPanelLayout.addSubview(tePanelView)
        tePanelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tePanelView.heightAnchor.constraint(equalToConstant: 230), // 固定高度为 230
            tePanelView.leadingAnchor.constraint(equalTo: beautyPanelLayout.leadingAnchor), // 左边缘与父视图对齐
            tePanelView.trailingAnchor.constraint(equalTo: beautyPanelLayout.trailingAnchor) // 右边缘与父视图对齐
        ])
    }
    
    
    //初始化美颜面板数据
    func initBeautyJson() {
        // 套餐文件清单
        // S1_07 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, motion_gesture, segmentation, beauty_body
        // S1_04 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, motion_gesture, segmentation
        // S1_03 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, segmentation
        // S1_02 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup, motion_gesture
        // S1_01 : beauty, beauty_image, beauty_shape, beauty_makeup, lut,  motion_2d, motion_3d, makeup, light_makeup
        // S1_00 : beauty, beauty_image, beauty_shape, beauty_makeup, lut
        // A1_06 : beauty, beauty_image, beauty_base_shape, lut, motion_2d, makeup
        // A1_05 : beauty, beauty_image, beauty_base_shape, lut, motion_2d, segmentation
        // A1_04 : beauty, beauty_image, beauty_general_shape, lut
        // A1_03 : beauty, beauty_image, beauty_general_shape, lut, motion_2d
        // A1_02 : beauty, beauty_image, beauty_base_shape, lut, motion_2d
        // A1_01 : beauty, beauty_image, beauty_base_shape, lut
        // A1_00 : beauty, lut
        
        /* 适配多语言示例底代码，每种语言对应一个json文件
         * 如：beauty_zh_hant （繁体中文）
         * 以下面板配置是按照S1-07套餐配置，您可以根据自己的套餐自行删减
         */
        let beautyJsonPath = jsonPathWithName("beauty")                  // 美颜
        let beautyTemplateJsonPath = jsonPathWithName("beauty_template") // 模板
        let beautyShapeJsonPath = jsonPathWithName("beauty_shape")       // 高级美型
        let beautyImageJsonPath = jsonPathWithName("beauty_image")       // 画质调整
        let beautyMakeupJsonPath = jsonPathWithName("beauty_makeup")     // 单点美妆
        let lightMakeupJsonPath = jsonPathWithName("light_makeup")       // 轻美妆
        let lutJsonPath = jsonPathWithName("lut")                        // 滤镜
        let beautyBodyJsonPath = jsonPathWithName("beauty_body")          // 美体
        let motion2dJsonPath = jsonPathWithName("motion_2d")              // 2D贴纸
        let motion3dJsonPath = jsonPathWithName("motion_3d")              // 3D贴纸
        let motionHandJsonPath = jsonPathWithName("motion_gesture")       // 手势贴纸
        let makeupJsonPath = jsonPathWithName("makeup")                   // 风格整妆
        let segmentationJsonPath = jsonPathWithName("segmentation")       // 虚拟背景


        var resArray = [[String: String]]()
    
        resArray.append([TEUI_BEAUTY_TEMPLATE: beautyTemplateJsonPath])
        resArray.append([TEUI_BEAUTY: beautyJsonPath])
        resArray.append([TEUI_BEAUTY_SHAPE: beautyShapeJsonPath])
        resArray.append([TEUI_BEAUTY_IMAGE: beautyImageJsonPath])
        resArray.append([TEUI_BEAUTY_MAKEUP: beautyMakeupJsonPath])
        resArray.append([TEUI_LIGHT_MAKEUP: lightMakeupJsonPath])
        resArray.append([TEUI_LUT: lutJsonPath])
        resArray.append([TEUI_BEAUTY_BODY: beautyBodyJsonPath])
        resArray.append([TEUI_MOTION_2D: motion2dJsonPath])
        resArray.append([TEUI_MOTION_3D: motion3dJsonPath])
        resArray.append([TEUI_MOTION_GESTURE: motionHandJsonPath])
        resArray.append([TEUI_MAKEUP: makeupJsonPath])
        resArray.append([TEUI_SEGMENTATION: segmentationJsonPath])

        TEUIConfig.shareInstance().setTEPanelViewResources(resArray)
    }
    
    func jsonPathWithName(_ name : String) -> String {
        let curLanguage = configLanguage()
        let jsonName = "\(name)\(curLanguage)"
        return Bundle.main.path(forResource: jsonName, ofType: "json") ?? ""
    }
    
    func configLanguage() -> String {
        //适配多语言示例底代码
        let language = Locale.preferredLanguages.first ?? ""
        if language.lowercased().hasPrefix("zh-hant") {
            // 繁体中文
            TEUIConfig.shareInstance().useDisplayName = true
            return "_zh_hant"
        }
        
        return ""
    }

    ///初始化SDK
    func initXMagic() {
        let effectMode = EffectMode.EFFECT_MODE_PRO
        TEBeautyKit.createXMagic(effectMode, onInitListener: { beautyKit in
            self.teBeautyKit = beautyKit;
            self.teFilter?.beautyKit = beautyKit
            self.tePanelView.teBeautyKit = beautyKit
            self.tePanelView.setDefaultBeauty()
         })

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tapping on the preview image will dismiss the keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(previewTapped))
        previewView.addGestureRecognizer(tap)
        
        // Auto complete the last used endpoint/key pair.
        let lastAuth = UserDefaultsAuthDao.shared.lastUsedAuth()
        endpointField.text = lastAuth?.endpoint
        streamKeyField.text = lastAuth?.streamKey
        
        teFilter = TEFilter()
        initBeautyJson()
        initXMagic()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.broadcastSession?.stop()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.teFilter?.beautyKit?.onDestroy()
        self.teFilter = nil;
   }
    
    
    @objc
    private func previewTapped() {
        // This allows the user to tap on the preview view to dismiss the keyboard when
        // entering the endpoint and stream key.
        view.endEditing(false)
    }

    private func setupSession() {
        do {
            // Create a custom configuration at 720p60
            let config = IVSBroadcastConfiguration()
            try config.video.setSize(CGSize(width: 720, height: 1280))
            try config.video.setTargetFramerate(60)

            // This slot will eventually bind to a custom image and audio source. This will be done manually after the creation
            // of the IVSBroadcastSession. In order to bind custom sources, make sure the `preferredAudioInput` and `preferredVideoInput`
            // properties of the slot are set to `userAudio` and `userImage` respectively. This will allow both of our custom
            // sources to bind to the same slot.
            let customSlot = IVSMixerSlotConfiguration()
            customSlot.size = config.video.size
            customSlot.position = CGPoint(x: 0, y: 0)
            customSlot.preferredAudioInput = .userAudio
            customSlot.preferredVideoInput = .userImage
            try customSlot.setName("custom-slot")

            config.mixer.slots = [customSlot]

            // Our AVCaptureSession will be managing the AVAudioSession independently
            IVSBroadcastSession.applicationAudioSessionStrategy = .noAction
            let broadcastSession = try IVSBroadcastSession(configuration: config,
                                                           descriptors: nil,
                                                           delegate: self)

            // Create custom audio and image sources by requesting them from the IVSBroadcastSession.
            // These can be given any name, but will both be attached to the slot that was configured above.
            // Custom sources are useful because they allow the host application to provide any type of image
            // and audio data directly to the SDK. In this example, we provide camera and microphone input
            // managed by a local AVCaptureSession, instead of letting the SDK control those devices.
            // However you can also provide MP4 video data or static image data as seen in `MixerViewController`.
            let customAudioSource = broadcastSession.createAudioSource(withName: "custom-audio")
            broadcastSession.attach(customAudioSource, toSlotWithName: "custom-slot")
            self.customAudioSource = customAudioSource

            let customImageSource = broadcastSession.createImageSource(withName: "custom-image")
            broadcastSession.attach(customImageSource, toSlotWithName: "custom-slot")
            self.customImageSource = customImageSource

            // We can still preview custom sources. This will act similar to a direct camera preview, just using the SDK as the GPU layer.
            attachCameraPreview(container: previewView, preview: try customImageSource.previewView(with: .fit))
            
            self.broadcastSession = broadcastSession

            setupCaptureSession()
        } catch {
            displayErrorAlert(error, "setting up session")
        }
    }

    private func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()

        if
            // let videoDevice = AVCaptureDevice.default(for: .video),
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoInput)
        {
            captureSession.addInput(videoInput)

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
                if let connection = videoOutput.connection(with: .video) {
                    // 如果是前置摄像头，设置镜像
                    if videoDevice.position == .front {
                        connection.isVideoMirrored = true
                    } else {
                        connection.isVideoMirrored = false
                    }
                }
            }
        }
        if
            let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            captureSession.canAddInput(audioInput)
        {
            captureSession.addInput(audioInput)

            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: queue)
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
                self.audioOutput = audioOutput
            }
        }
        captureSession.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        self.captureSession = captureSession
        
        
        
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoOutput {
            
            connection.videoOrientation = orientation
            
            // This keeps the images coming in with the correct orientation.
            // connection.videoOrientation = orientation
            // A host application can do further processing of this sample by applying a CIFilter, custom Metal shader, or
            // by using a more complex pipeline that provides services like a beauty filter.
            
            // As an example using CIFilter
            // let finalBuffer = filterHelper?.process(inputBuffer: sampleBuffer) ?? sampleBuffer
            let finalBuffer = teFilter?.processTe(inputBuffer: sampleBuffer) ?? sampleBuffer
            
            // It is important that the processing finishes before the next frame arrives, otherwise frames will start to backup.
            // If a new video sample does not arrive to the SDK in time, the previous sample will be repeated in the broadcast
            // until a new frame arrives.

            customImageSource?.onSampleBuffer(finalBuffer)
        } else if output == audioOutput {
            // A host application can do further processing of this sample here. It is required for processing to happen before
            // the next sample arrives, otherwise audio may be dropped (it will be replaced with silence).
            customAudioSource?.onSampleBuffer(sampleBuffer)
        }
    }

    
    @IBAction private func startTapped(_ sender: UIButton) {
        if isRunning {
            // Stop the session if we're running
            broadcastSession?.stop()
            isRunning = false
        } else {
            // Start the session if we're not running.
            guard let endpointPath = endpointField.text, let url = URL(string: endpointPath), let key = streamKeyField.text else {
                let alert = UIAlertController(title: "Invalid Endpoint",
                                              message: "The endpoint or streamkey you provided is invalid",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            do {
                // store this endpoint/key pair to share with the screen capture extension
                // and to auto-complete the next time this app is launched
                let authItem = AuthItem(endpoint: endpointPath, streamKey: key)
                UserDefaultsAuthDao.shared.insert(authItem)
                try broadcastSession?.start(with: url, streamKey: key)
                isRunning = true
            } catch {
                displayErrorAlert(error, "starting session")
            }
        }
    }
    
 
    
    override func viewDidLayoutSubviews() {
        orientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
    }
}


extension CustomSourcesViewController: IVSBroadcastSession.Delegate {
    func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
        print("IVSBroadcastSession state did change to \(state.rawValue)")
        DispatchQueue.main.async {
            switch state {
            case .invalid: self.connectionView.backgroundColor = .darkGray
            case .connecting: self.connectionView.backgroundColor = .yellow
            case .connected: self.connectionView.backgroundColor = .green
            case .disconnected:
                self.connectionView.backgroundColor = .darkGray
                self.isRunning = false
            case .error:
                self.connectionView.backgroundColor = .red
                self.isRunning = false
            @unknown default: self.connectionView.backgroundColor = .darkGray
            }
        }
    }
    func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {}
    func broadcastSession(_ session: IVSBroadcastSession, audioStatsUpdatedWithPeak peak: Double, rms: Double) {
        labelSoundDb.text = "db: \(rms)"
    }
}


extension CustomSourcesViewController:YTSDKEventListener,YTSDKLogListener,TEPanelViewDelegate{
    func onAIEvent(_ event: Any) {
        
    }
    
    func onTipsEvent(_ event: Any) {
        
    }
    
    func onAssetEvent(_ event: Any) {
        
    }
    
    func onLog(_ loggerLevel: YtSDKLoggerLevel, withInfo logInfo: String) {
        
    }
    
    
    func showBeautyChanged(_ open: Bool) {
        teBeautyKit?.enableBeauty(open)
    }

}
