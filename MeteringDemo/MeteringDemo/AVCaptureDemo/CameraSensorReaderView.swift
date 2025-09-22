//
//  CameraSensorReaderView.swift
//  AVCaptureDeviceDemo
//
//  Created by 이현주 on 9/17/25.
//

import UIKit
import AVFoundation

class CameraSensorReaderView: UIView {
    private let session = AVCaptureSession()
    private var device: AVCaptureDevice?

//    var onExposureUpdate: ((Float, Double, Float) -> Void)?
    var onExposureUpdate: ((ExposureInfo) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration() // 설정 시작
        session.sessionPreset = .photo

        // MARK: - Input Device 설정
        // AVCaptureDevice의 파라미터값을 이용
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video,
                                                position: .back) {
            device = camera
            
            // AVCaptureDeviceInput을 이용해 1번에서 등록했던 AVCaptureDevice를 불러옴.
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    // captureSession input에 추가
                    session.addInput(input)
                }
            } catch {
                print("카메라 입력 에러: \(error)")
            }
        }
        
        // MARK: - Output Media 설정 (프리뷰가 없는 경우에도 출력을 세션에 연결해야 함)
        // 따로 파일 저장 없이 센서값 추출을 위한 프레임 단위 비디오 데이터 사용 위해 AVCaptureVideoDataOutput() 사용
        let videoOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // 설정 종료
        session.commitConfiguration()
        
        // 백그라운드 스레드에서 실행
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }

        // 센서값 읽기 통한 ISO/Exposure 업데이트 타이머
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.readExposureValues()
        }
    }

//    private func readExposureValues() {
//        guard let device = device else { return }
//        let iso = device.iso
//        let exposure = device.exposureDuration.seconds
//        let offset = device.exposureTargetOffset
//        onExposureUpdate?(iso, exposure, offset)
//    }
    private func readExposureValues() {
        guard let device = device else { return }

        let iso = device.iso
        let exposure = device.exposureDuration.seconds
        let bias = device.exposureTargetBias
        let offset = device.exposureTargetOffset
        let mode = device.exposureMode
        let aperture = device.lensAperture

        // EV 계산
        let ev: Double
        if aperture > 0 && exposure > 0 {
            ev = log2((Double(aperture * aperture) / exposure) * (100.0 / Double(iso)))
        } else {
            ev = 0
        }

        let info = ExposureInfo(
            iso: iso,
            exposureDuration: exposure,
            aperture: aperture,
            ev: ev,
            bias: bias,
            offset: offset,
            mode: mode
        )

        onExposureUpdate?(info)
    }

}
