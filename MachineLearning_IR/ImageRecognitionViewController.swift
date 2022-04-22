//
//  ImageRecognitionViewController.swift
//  MachineLearning_IR
//
//  Created by Mertcan Yılmaz on 18.04.2022.
//

import UIKit
import CoreML
import Vision

class ImageRecognitionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource{
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var buttonOutlet: UIButton!
    
    var isPicked = false
    var recResults = [[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        
        imageView.isUserInteractionEnabled = true
        let tapRecog = UITapGestureRecognizer(target: self, action: #selector(promptPhoto))
        imageView.addGestureRecognizer(tapRecog)
        buttonStatus()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.organize, target: self, action: #selector(promptPhoto))
        promptPhoto()
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        recResults.removeAll()
        resultsTableView.reloadData()
        let ciImage = CIImage(image: imageView.image!)
        recognize(image: ciImage!)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        isPicked = true
        recResults.removeAll()
        resultsTableView.reloadData()
        buttonStatus()
        self.dismiss(animated: true)
    }
    
    func buttonStatus(){
        if isPicked == false{
            buttonOutlet.isEnabled = false
            buttonOutlet.setTitle("Pick an Image", for: .normal)
            
        }else if isPicked == true{
            buttonOutlet.isEnabled = true
            buttonOutlet.setTitle("Scan It", for: .normal)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var cellConfig = cell.defaultContentConfiguration()
        cellConfig.text = "%\(recResults[indexPath.row][1]) \(recResults[indexPath.row][0])"
        cellConfig.secondaryText = (recResults[indexPath.row][2] as! String)
        cellConfig.textProperties.alignment = .center
        cellConfig.secondaryTextProperties.alignment = .center
        if recResults[indexPath.row][1] as! Int >= 70{
            cell.backgroundColor = UIColor(red: 153/255, green: 255/255, blue: 153/255, alpha: 0.5)
        }else if recResults[indexPath.row][1] as! Int >= 35 {
            cell.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 153/255, alpha: 0.5)
        }else{
            cell.backgroundColor = UIColor(red: 255/255, green: 153/255, blue: 153/255, alpha: 0.5)
        }
        cell.contentConfiguration = cellConfig
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var lines = [String]()
        let detailsArray = recResults[indexPath.row][3] as! [VNClassificationObservation]
        for (i,j) in detailsArray.enumerated() {
            if Int(j.confidence*100) >= 10{
                lines.append("%\(Int(j.confidence*100)) \(j.identifier)")
            }
            if i == 2{
                break
            }
        }
        detailBox(modelName: recResults[indexPath.row][2] as! String, lines: lines)
    }
    
    func detailBox(modelName : String, lines: [String]){
        let box = UIAlertController(title: modelName, message: lines.joined(separator: "\n"), preferredStyle: UIAlertController.Style.alert)
        let ok = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        box.addAction(ok)
        self.present(box, animated: true, completion: nil)
    }
    
    func recognize(image : CIImage){
        let handler = VNImageRequestHandler(ciImage: image)
        
        if let model = try? VNCoreMLModel(for: MobileNetV2().model) {
            let request = VNCoreMLRequest(model: model) { [self] (vnrequest, error) in
                let results = vnrequest.results as? [VNClassificationObservation]
                DispatchQueue.main.async { [self] in
                    recResults.append([results![0].identifier,Int(results![0].confidence * 100),"MobileNetV2",results!])
                    resultsTableView.reloadData()
                }
            }
            DispatchQueue.global(qos: .userInteractive).async {
                try? handler.perform([request])}
        }
        
        if let model = try? VNCoreMLModel(for: Resnet50().model) {
            let request = VNCoreMLRequest(model: model) { [self] (vnrequest, error) in
                let results = vnrequest.results as? [VNClassificationObservation]
                DispatchQueue.main.async { [self] in
                    recResults.append([results![0].identifier,Int(results![0].confidence * 100),"Resnet50",results!])
                    resultsTableView.reloadData()
                }
            }
            DispatchQueue.global(qos: .userInteractive).async {
                try? handler.perform([request])}
        }
        
        if let model = try? VNCoreMLModel(for: SqueezeNet().model) {
            let request = VNCoreMLRequest(model: model) { [self] (vnrequest, error) in
                let results = vnrequest.results as? [VNClassificationObservation]
                DispatchQueue.main.async { [self] in
                    recResults.append([results![0].identifier,Int(results![0].confidence * 100),"SqueezeNet",results!])
                    resultsTableView.reloadData()
                }
            }
            DispatchQueue.global(qos: .userInteractive).async {
                try? handler.perform([request])}
        }
        
        let request = VNClassifyImageRequest()
        try? handler.perform([request])
        let results = request.results
        recResults.append([results![0].identifier, Int(results![0].confidence*100), "Vision",results!])
        resultsTableView.reloadData()
    }
    
    @objc func promptPhoto() {
        
        let prompt = UIAlertController(title: "Choose a Photo", message: "Choose a photo for recognation.", preferredStyle: .actionSheet)
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        func presentCamera(_ _: UIAlertAction) {
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true)
        }

        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: presentCamera)
        
        func presentLibrary(_ _: UIAlertAction) {
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true)
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: presentLibrary)
        
        func presentAlbums(_ _: UIAlertAction) {
            imagePicker.sourceType = .savedPhotosAlbum
            self.present(imagePicker, animated: true)
        }
        
        let albumsAction = UIAlertAction(title: "Saved Albums", style: .default, handler: presentAlbums)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        prompt.addAction(cameraAction)
        prompt.addAction(libraryAction)
        prompt.addAction(albumsAction)
        prompt.addAction(cancelAction)
        
        self.present(prompt, animated: true, completion: nil)
    }
}
