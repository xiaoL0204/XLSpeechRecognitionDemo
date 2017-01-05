//
//  XLSpeechRecognitionController.swift
//
//
//  Created by xiaoL on 16/12/28.
//  Copyright © 2016年 xiaolin. All rights reserved.
//

import UIKit
import Speech


@available(iOS 10.0, *)
class XLSpeechRecognitionController: UIViewController,SFSpeechRecognizerDelegate,CALayerDelegate {

    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest!
    private var recognitionTask: SFSpeechRecognitionTask!
    private var audioEngine = AVAudioEngine()
    private var defaultLocale = Locale(identifier: "zh-CN")
    private var shrinking = false
    private var speechBtnAnimated = false
    private var btnLoadingShapeLayer: CAShapeLayer?
    
    private var rippleLayers = NSMutableArray()
    private var msgLabel: UILabel!
    private var promptLabel: UILabel!
    private var speechBtn: UIButton!
    private var closeBtn: UIButton!
    
    
    open var voiceTranscriptionCompletion: ((String) -> ())?
    
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        audioEngine.stop()
        recognitionRequest = nil
        recognitionTask = nil
        print("XLSpeechRecognitionController dealloc")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        createDefaultUI()
        
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            
            print("requestAuthorization authStatus:\(authStatus.rawValue)");
            
            
            /*
             OperationQueue.main.addOperation {
             switch authStatus {
             case .authorized:
             
             
             case .denied:
             
             case .restricted:
             
             case .notDetermined:
             
             
             
             
             }
             
             
             }
             */
            
            
        }
        
        
        speechRecognizer = SFSpeechRecognizer(locale: defaultLocale);
//        speechRecognizer.delegate = self

        
    }
    
    
    
    private func createDefaultUI() {
        msgLabel = UILabel.init(frame: CGRect(x: 0,y: 120,width: S_SCREEN_WIDTH,height: 50))
        msgLabel.backgroundColor = .clear
        msgLabel.textColor = .black
        msgLabel.font = UIFont.systemFont(ofSize: 25)
        msgLabel.textAlignment = .center
        msgLabel.text = "正在听您的讲话..."
        
        
        promptLabel = UILabel.init(frame: CGRect(x: 0,y: 200,width: S_SCREEN_WIDTH,height: 100))
        promptLabel.backgroundColor = .clear
        promptLabel.textColor = UIColor.init(colorLiteralRed: 90/255.0, green: 90/255.0, blue: 90/255.0, alpha: 1)
        promptLabel.font = .systemFont(ofSize: 18)
        promptLabel.textAlignment = .center
        promptLabel.numberOfLines = 0
        promptLabel.text = "您可以试着说：\n\"北京\"\n\"酒店\""
        
        
        let speechBtnWidth: CGFloat = 100.0
        speechBtn = UIButton.init(frame: CGRect(x: (S_SCREEN_WIDTH-speechBtnWidth)/2.0,y: S_SCREEN_HEIGHT-100-speechBtnWidth,width: speechBtnWidth,height: speechBtnWidth))
        speechBtn.backgroundColor = UIColor.init(red: 255/255.0, green: 143/255.0, blue: 21/255.0, alpha: 1)
        speechBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        speechBtn.addTarget(self, action: #selector(speechBtnClicked), for: .touchUpInside)
        speechBtn.layer.cornerRadius = speechBtnWidth/2.0
        speechBtn.layer.masksToBounds = true
        
        
        let voiceImageV = UIImageView(image: UIImage(named: "home_navi_bar_voice"))
        voiceImageV.frame = CGRect(x: 0,y: 0,width: 20,height: 34)
        voiceImageV.center = CGPoint(x: speechBtn.s_centerX,y: speechBtn.s_centerY)
        
        
        
        view.addSubview(msgLabel)
        view.addSubview(promptLabel)
        view.addSubview(speechBtn)
        view.addSubview(voiceImageV)
        
        
    }
    
    
    
    
    private func startRecording() throws {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true,with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("audio engine has no input node")
        }
        guard let recognitionRequest = recognitionRequest else {
            fatalError("unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        
        recognitionRequest.shouldReportPartialResults = true
        weak var weakSelf = self
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if weakSelf == nil {
                return
            }
            
            var isFinal = false
            weakSelf?.stopSpeechBtnLoadingAnimation()
            if let result = result {
                let resultString = result.bestTranscription.formattedString;
                print("result string:\(resultString)")
                weakSelf?.msgLabel.text = "您可能在说：\(resultString)"
                weakSelf?.speechBtn.isSelected = false
                isFinal = result.isFinal
                
                if weakSelf?.voiceTranscriptionCompletion != nil {
                    weakSelf?.voiceTranscriptionCompletion!(resultString)
                }
            } else {
                weakSelf?.msgLabel.text = "您好像没有说话..."
            }
            
            if error != nil || isFinal {
                weakSelf?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                weakSelf?.recognitionRequest = nil
                weakSelf?.recognitionTask = nil
            }
        }
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            print("inputNode.installTap   buffer:\(buffer)")
            weakSelf?.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    
    
    private func startRipplesSpeechBtnAnimationAction() {
        startRippleAnimation()
        weak var weakSelf = self
        
        startSpeechBtnShrinkingAnimation { (finish) in
            if weakSelf?.speechBtnAnimated == true {
                weakSelf?.startRipplesSpeechBtnAnimationAction()
            }
        }
    }
    
    
    private func startRippleAnimation() {
        let beginPath = UIBezierPath(arcCenter: CGPoint(x: speechBtn.s_centerX,y: speechBtn.s_centerY),radius: speechBtn.s_width/2.0+10,startAngle:CGFloat(0),endAngle: CGFloat(M_PI*2),clockwise: true)
        
        let rippleLayer = CAShapeLayer()
        rippleLayer.path = beginPath.cgPath
        rippleLayer.fillColor = UIColor.clear.cgColor
        rippleLayer.strokeColor = UIColor.init(red: 255/255.0, green: 217/255.0, blue: 168/255.0, alpha: 1).cgColor
        rippleLayer.lineWidth = 3.0
        rippleLayers.add(rippleLayer)
        view.layer.insertSublayer(rippleLayer, below: speechBtn.layer)
        
        let endPath = UIBezierPath(arcCenter: CGPoint(x: speechBtn.s_centerX,y: speechBtn.s_centerY),radius: speechBtn.s_width/2.0+80,startAngle:CGFloat(0),endAngle: CGFloat(M_PI*2),clockwise: true)
        rippleLayer.path = endPath.cgPath
        rippleLayer.opacity = 0
        
        let rippleAnimation = CABasicAnimation(keyPath: "path")
        rippleAnimation.fromValue = beginPath.cgPath
        rippleAnimation.toValue = endPath.cgPath
        rippleAnimation.duration = 3
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(value: 1.0)
        opacityAnimation.toValue = NSNumber(value: 0)
        opacityAnimation.duration = 3
        opacityAnimation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseOut)
        
        rippleLayer.add(rippleAnimation, forKey: "rippleAnimation")
        rippleLayer.add(opacityAnimation, forKey: "opacityAnimation")
    }
    private func stopRippleAnimations() {
        rippleLayers.forEach { (item) in
            (item as! CALayer).removeFromSuperlayer()
        }
    }
    
    
    
    private func startSpeechBtnShrinkingAnimation(completionBlock: @escaping ((Bool) -> Void)) {
        speechBtn.pop_removeAllAnimations()
        let animation = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        animation?.toValue = shrinking ? NSValue(cgPoint: CGPoint(x: 1.0,y: 1.0)) : NSValue(cgPoint: CGPoint(x: 2.0,y: 2.0))
        animation?.springBounciness = 5
        animation?.springSpeed = 10.0
        shrinking = !shrinking
        animation?.completionBlock = {(anim: POPAnimation?,finish: Bool) -> Void in
            completionBlock(finish)
        }
        speechBtn.pop_add(animation, forKey: "Animation")
    }
    
    private func stopSpeechBtnShrinkingAnimation(){
        speechBtn.pop_removeAllAnimations()
        
    }
    
    
    
    private func startSpeechBtnLoadingAnimation() {
        let radius = speechBtn.layer.frame.size.width/2.0
        let arcCenter = CGPoint(x: radius,y: radius)
        let pacmanPath = UIBezierPath(arcCenter: arcCenter,radius: radius,startAngle: CGFloat(M_PI*3/2),endAngle: CGFloat(0),clockwise: true)
        btnLoadingShapeLayer?.removeFromSuperlayer()
        btnLoadingShapeLayer = CAShapeLayer()
        btnLoadingShapeLayer?.fillColor = UIColor.clear.cgColor
        btnLoadingShapeLayer?.strokeColor = UIColor.orange.cgColor
        btnLoadingShapeLayer?.path = pacmanPath.cgPath
        btnLoadingShapeLayer?.lineWidth = 15
        btnLoadingShapeLayer?.frame = CGRect(x: speechBtn.layer.frame.origin.x,y: speechBtn.layer.frame.origin.y,width: speechBtn.layer.frame.size.width,height: speechBtn.layer.frame.size.height)
        view.layer.insertSublayer(btnLoadingShapeLayer!, below: speechBtn.layer)
        
        let spinAnimation = CABasicAnimation(keyPath: "transform.rotation")
        spinAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        spinAnimation.fromValue = NSNumber(value: 0)
        spinAnimation.toValue = NSNumber(value: M_PI*2)
        spinAnimation.duration = 2
        spinAnimation.repeatCount = 99999
        spinAnimation.isRemovedOnCompletion = true
        btnLoadingShapeLayer?.add(spinAnimation, forKey: "btnLoadingAni")
    }
    private func stopSpeechBtnLoadingAnimation() {
        let pausedTime = btnLoadingShapeLayer?.convertTime(CACurrentMediaTime(), from: nil)
        btnLoadingShapeLayer?.speed = 0.0
        btnLoadingShapeLayer?.timeOffset = pausedTime!
        btnLoadingShapeLayer?.removeFromSuperlayer()
        btnLoadingShapeLayer = nil
    }
    
    
    
    
    
    
    
    
    final func speechBtnClicked() {
        speechBtn.isSelected = !speechBtn.isSelected
        if speechBtnAnimated == true {
            speechBtnAnimated = false
            stopRippleAnimations()
            stopSpeechBtnShrinkingAnimation()
            startSpeechBtnLoadingAnimation()
            msgLabel.text = "正在识别..."
        } else {
            speechBtnAnimated = true
            startRipplesSpeechBtnAnimationAction()
        }
        
        
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest.endAudio()
        }else{
            try! startRecording()
            weak var weakSelf = self
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+3.4, execute: {
                if weakSelf?.speechBtnAnimated == true {
                    weakSelf?.speechBtnClicked()
                }
            })
        }
 
    }
}
