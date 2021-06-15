//
//  ImagePickerHelper.swift
//  ChatViewController
//
//  Created by Hoangtaiki on 6/11/18.
//  Copyright © 2018 toprating. All rights reserved.
//

import UIKit
import MobileCoreServices

/// Protocol use to specify standard for ImagePickerHelper
public protocol ImagePickerHelperable {
    // We new a variable to store parent view controller to present ImagePickerController
    var parentViewController: UIViewController? { get set }
    // Open camera
    func accessCamera()
    // Open photo library
    func accessLibrary()
}

public class ImagePickerHelper: NSObject, ImagePickerHelperable, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIDocumentPickerDelegate {

    public weak var parentViewController: UIViewController?
    public weak var delegate: ImagePickerResultDelegate?
    public weak var chatInstance: ChatViewController?

    public func accessPhoto(from sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
       // imagePicker.mediaTypes = [kUTTypeImage as String]

        parentViewController?.present(imagePicker, animated: true, completion: nil)
    }
    
    public func openVideoGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = false
        parentViewController?.present(picker, animated: true, completion: nil)
    }
    
    public func openDocument(){
        
        var valueType: [String] = []
        
        let value1 = [String(kUTTypePDF),String(kUTTypeImage),String(kUTTypeBMP),String(kUTTypeAudio)]
        valueType.append(contentsOf: value1)
        
        let documentPickerController = UIDocumentPickerViewController(documentTypes:valueType, in: .import)
        documentPickerController.delegate = self
        documentPickerController.navigationController?.navigationBar.topItem?.title = "Files"
        documentPickerController.navigationController?.navigationBar.tintColor = ChatViewConfiguration.default.documentPickerNavBarTintColor
        parentViewController?.present(documentPickerController, animated: true, completion: nil)
    }
    
    /// Show Action Sheet to select
    public func takeOrChoosePhoto() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: ChatViewConfiguration.default.cancelTitle, style: .cancel))
        
        let takePhoto = UIAlertAction(title: ChatViewConfiguration.default.chooseCameraTitle, style: .default) { [weak self] _ in
            self?.accessCamera()
        }
        alert.addAction(takePhoto)
        
        let choosePhoto = UIAlertAction(title: ChatViewConfiguration.default.choosePhotoTitle, style: .default) { [weak self] _ in
            self?.accessLibrary()
        }
        alert.addAction(choosePhoto)
        
        let chooseVideo = UIAlertAction(title: ChatViewConfiguration.default.chooseVideoTitle, style: .default) { [weak self] _ in
            self?.accessVideo()
        }
        alert.addAction(chooseVideo)
        
        if let chatVC = chatInstance{
            if chatVC.configuration.showDocumentAttachment{
                let chooseDocument = UIAlertAction(title: ChatViewConfiguration.default.chooseDocumentTitle, style: .default) { [weak self] _ in
                    self?.openDocument()
                }
                alert.addAction(chooseDocument)
            }
        }
        
        parentViewController?.present(alert, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }

        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        switch mediaType {
        case kUTTypeImage:
            guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
            if #available(iOS 11.0, *) {
                guard let imagePath = info[UIImagePickerController.InfoKey.imageURL] as? NSURL else {
                    if originalImage != nil{
                        
                        delegate?.didSelectImage?(url: URL(string: "cameraImage.png"), imageData: originalImage.pngData())
                    }
                    return
                }
                delegate?.didSelectImage?(url: imagePath as URL, imageData: originalImage.pngData())
            } else {
                DispatchQueue.main.async {
                    originalImage.storeToTemporaryDirectory(completion: { [weak self] (imagePath, error) in
                        guard let imageURL = imagePath else {
                            return
                        }
                        self?.delegate?.didSelectImage?(url: imageURL, imageData: originalImage.pngData())
                    })
                }
            }
            
        case kUTTypeMovie:
            guard let videoPath = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL else {
                return
                    (delegate?.didSelectImage?(url: URL(string: "cameraVideo.mov"), imageData: nil))!
            }
            delegate?.didSelectVideo?(url: videoPath as URL, imageData: nil)
        default: break
        }
    }
    
    public func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            accessPhoto(from: .camera)
        }
    }
    
    public func accessLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            accessPhoto(from: .photoLibrary)
        }
    }
    
    public func accessVideo() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            openVideoGallery()
        }
    }
    
    //MARK:- Document picker delegates
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
    {
        
        if let getData = NSData(contentsOf: url)
        {
            var fileSize = Float(getData.length)
            fileSize = fileSize/(1024*1024)
            delegate?.didSelectDocumet?(url: url, documentData: getData as Data)
        }
        else if url != nil{
            delegate?.didSelectDocumet?(url: url, documentData: nil)
        }
    }
    
}
