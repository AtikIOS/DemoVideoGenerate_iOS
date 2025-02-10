//
//  ViewController.swift
//  VideoGenerator
//
//  Created by Atik Hasan on 2/9/25.
//

import UIKit
import PhotosUI
import Foundation
import AVFoundation
import SwiftVideoGenerator

class ViewController: UIViewController {
    
    @IBOutlet weak var vwVideoPlayer: UIView!
    @IBOutlet weak var btnShowInFinder: UIButton! {
        didSet {
            self.btnShowInFinder.addTarget(self, action: #selector(btnShowInFinderAction), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var btnPlayPause: UIButton!{
        didSet{
            self.btnPlayPause.addTarget(self, action: #selector(btnPlayPauseAction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var btnVideoGenerate: UIButton!{
        didSet{
            self.btnVideoGenerate.addTarget(self, action: #selector(btnVideoGenerateAction), for: .touchUpInside)
        }
    }
    @IBOutlet weak var btnPicKImage: UIButton!{
        didSet{
            self.btnPicKImage.addTarget(self, action: #selector(btnPicKImageAction), for: .touchUpInside)
        }
    }
    
    var videoUrl: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    let audioFileName = "Radhika"
    let audioFileExtension = "mp3"
    var selectedImages: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnVideoGenerate.isHidden = true
        self.indicator.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = vwVideoPlayer.bounds
    }
    
    
    func presentImagePicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func VideoPlay(url : URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = vwVideoPlayer.bounds
        vwVideoPlayer.layer.addSublayer(playerLayer!)
        
        player?.play()
    }
    
    
    
    func generateVideo() {
        if let audioURL = Bundle.main.url(forResource: audioFileName, withExtension: audioFileExtension) {
            
            // Set up the video generator parameters
            VideoGenerator.fileName = generateVideoFileName()
            VideoGenerator.shouldOptimiseImageForVideo = true
            
            guard !selectedImages.isEmpty else {
                self.createAlertView(message: "No images available")
                return
            }
            
            // Generate the video with the images and the single audio file
            VideoGenerator.current.generate(withImages: selectedImages, andAudios: [audioURL], andType: .singleAudioMultipleImage) { Progress in
                print("progress is: ",Progress.self)
            } outcome: { result in
                self.indicator.stopAnimating()
                self.indicator.isHidden = true
                print("resutl is ",result)
                switch result {
                case  .success(let url):
                    self.videoUrl = url
                    self.VideoPlay(url: url)
                case .failure(_):
                    print("Video generation failed:")
                }
            }
        } else {
            self.createAlertView(message: "Audio file is missing.")
        }
    }
    
    // Helper method to create alert view
    func createAlertView(message: String) {
        let alert = UIAlertController(title: "Notification", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func generateVideoFileName() -> String {
        let uuid = UUID().uuidString
        return "Atik\(uuid).mp4"
    }
    
    
    @objc func btnPicKImageAction(){
        self.presentImagePicker()
    }
    
    
    @objc func btnVideoGenerateAction(){
        self.indicator.isHidden = false
        self.indicator.startAnimating()
        self.generateVideo()
    }
    
    @objc func btnPlayPauseAction(){
        if let player = player {
            if player.timeControlStatus == .playing {
                player.pause()
            } else {
                player.play()
            }
        }
    }
    
    @objc func btnShowInFinderAction() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let videoFiles = fileURLs.filter { $0.pathExtension == "mp4" || $0.pathExtension == "m4v" }
            
            if videoFiles.isEmpty {
                createAlertView(message: "No generated videos found.")
            } else {
                showVideoSelectionAlert(videos: videoFiles)
            }
        } catch {
            print("Error while fetching video files: \(error)")
        }
        
        func showVideoSelectionAlert(videos: [URL]) {
            let alert = UIAlertController(title: "Select a Video", message: nil, preferredStyle: .actionSheet)
            
            for videoURL in videos {
                let fileName = videoURL.lastPathComponent
                alert.addAction(UIAlertAction(title: fileName, style: .default, handler: { _ in
                    self.player?.pause()
                    self.VideoPlay(url: videoURL)
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        
    }
}

extension ViewController : PHPickerViewControllerDelegate{
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        self.btnVideoGenerate.isHidden = false
        selectedImages.removeAll()
        
        let group = DispatchGroup()
        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                defer { group.leave() }
                
                if let image = image as? UIImage {
                    self.selectedImages.append(image)
                }
            }
        }
        group.notify(queue: .main) {
            print("Selected images count: \(self.selectedImages.count)")
        }
    }
}

