//
//  ImageRecognitionViewController.swift
//  MachineLearning_IR
//
//  Created by Mertcan Yılmaz on 18.04.2022.
//

import UIKit
import CoreML
import Vision

class ImageRecognitionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var buttonOutlet: UIButton!
    
    var isPicked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.isUserInteractionEnabled = true
        let tapRecog = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(tapRecog)
        hidButton()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.organize, target: self, action: #selector(selectImage))
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        let ciImage = CIImage(image: imageView.image!)
        recognize(image: ciImage!)
    }
    
    @objc func selectImage(){
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        isPicked = true
        hidButton()
        self.dismiss(animated: true)
    }
    
    func hidButton(){
        if isPicked == false{
            buttonOutlet.isEnabled = false
            buttonOutlet.setTitle("Pick an Image", for: .normal)
            
        }else if isPicked == true{
            buttonOutlet.isEnabled = true
            buttonOutlet.setTitle("Scan It", for: .normal)
            self.firstLabel.text = ""
        }
    }
    
    func recognize(image : CIImage){
        if let model = try? VNCoreMLModel(for: MobileNetV2().model) {
            let request = VNCoreMLRequest(model: model) { (vnrequest, error) in
                if let results = vnrequest.results as? [VNClassificationObservation] {
                    if results.count > 0 {
                        let topResult = results.first
                        DispatchQueue.main.async {
                            let confidenceLevel = (topResult?.confidence ?? 0) * 100
                            let rounded = Int (confidenceLevel * 100) / 100
                            self.firstLabel.text = "\(rounded)% it's \(topResult!.identifier)"
                        }
                    }
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: image)
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("error")
                }
            }
        }
    }
}
