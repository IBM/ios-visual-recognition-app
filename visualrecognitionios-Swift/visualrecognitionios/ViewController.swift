//
//  ViewController.swift
//  visualrecognitionios
//

import UIKit
import SwiftSpinner
import KTCenterFlowLayout
import VisualRecognitionV3
import BMSCore




class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UIToolbar item for camera selector
    @IBOutlet weak var cameraSelector: UIToolbar!
    // UIToolbar item for accessing photo library
    @IBOutlet weak var photoLibrarySelector: UIToolbar!
    // UIView that holds image tags
    @IBOutlet weak var tagView: UIView!
    // UICollectionView that will hold tag cells
    @IBOutlet weak var tagCollectionView: UICollectionView!
    // UIImageView that will show analyzed photo
    @IBOutlet weak var visualRecognitionImage: UIImageView!
    // VisualRecognition Object
    var visualRecognition: VisualRecognition!
    // Array of TagItems
    var tagItems: [TagItem] = []

    override func viewDidLoad() {
        
        super.viewDidLoad()

        // Create a TagItem for default image
        tagItems.append(TagItem(watsonResultName: "Blue Sky",
                                watsonResultScore: 0.85,
                                watsonResultScorePercentage: "85%"))
        // Create a TagItem for default image
         tagItems.append(TagItem(watsonResultName: "Landscape",
                                 watsonResultScore: 0.60,
                                 watsonResultScorePercentage: "60%"))

        // Initialize KTCenterFlowLayout and minimum spacing elements
        let layout = KTCenterFlowLayout()
        layout.minimumInteritemSpacing = 5.0
        layout.minimumLineSpacing = 5.0
        // Create and initialize nib and tagCollectionView
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "TagCollectionViewCell", bundle: bundle)
        // Register the nib for tagCollectionView
        tagCollectionView.register(nib, forCellWithReuseIdentifier: "TagCollectionViewCell")
        // Set background color for collection view
        self.tagCollectionView.backgroundColor = UIColor.clear
        tagCollectionView.collectionViewLayout = layout

        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        // Create a configuration path for the BMSCredentials.plist file to read in Watson credentials
        let configurationPath = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist")
        let configuration = NSDictionary(contentsOfFile: configurationPath!)
        // Set the Watson credentials for Visual Recognition service from the BMSCredentials.plist
        let visualRecognitionApiKey = configuration?["visualrecognitionApikey"] as! String
        // Set date string for version of Watson service to use
        let versionDate = "2018-03-19"
        // Initialize Visual Recognition object
        
        visualRecognition = VisualRecognition(version: versionDate, apiKey: visualRecognitionApiKey)
        super.viewDidAppear(animated)
    }
    @objc
    func didBecomeActive(_ notification: Notification) {
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Button action that opens the camera to take a photo
    @IBAction func openCamera(_ sender: AnyObject) {
        // Check if the Camera source is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            // Create image picker using image picker controller
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            // Assign image picker source to the camera
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
            // Assign the image picker allowsEditing field to true
            imagePicker.allowsEditing = true
            // Present the view controller
            self.present(imagePicker, animated: true, completion: nil)
        }
        // Show alert when the camera is unavailable
        else {
            showAlert("Camera Unavailable", alertMessage: "The camera feature is currently unavaialbe on this device. If you are running the application on a simulator, please use a physical device in order to utilize camera functionality.")
        }
    }

    // Button action that opens the photo library to choose a photo
    @IBAction func openPhotoLibrary(_ sender: AnyObject) {
        // Check if photo library source is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            // Create image picker using image picker controller
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            // Assign image picker source to the photo library
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            // Assign the image picker allowsEditing field false
            imagePicker.allowsEditing = true
            // Present the view controller
            self.present(imagePicker, animated: true, completion: nil)
        }
        // Show alert when photo library is unavailable
        else{
            showAlert("Photo Library Unavailable", alertMessage: "The Photo Library feature is currently unavaialbe on this device. Please try again.")
        }
    }

    // Function that handles the actions once an image is chosen from the image picker controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        // Set the visual recognition image to the chosen image
        visualRecognitionImage.image = image
        // Dismiss the view controller
        self.dismiss(animated: true, completion: nil);
        // Create a document URL to save the file into
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Save the image as a JPEG
        let imageToSave:Data = UIImageJPEGRepresentation(image, 1.0)!
        // Append file name to document location
        let fileURL = documentsURL.appendingPathComponent("tempImage.png")
        // Save the image in the provided location
        try? imageToSave.write(to: fileURL, options: [])
        // Clear the tagItems array
        tagItems = []
        // Call the classifyImage function with the saved image
        classifyImage(fileURL)
        // Call the detectFaces function with the saved image
        detectFaces(fileURL)
    }

    // Function to classify image using Visual Recognition based on image location
    func classifyImage(_ imageLocation: URL){
        // String that will hold the result name from Watson
        var resultName: String!
        // Double that will hold the result scored from Watson
        var resultScore: Double!
        // String that will hold the result score percentage from Watson
        var resultScorePercentage: String!
        // Classify image using Visual Recognition
        visualRecognition.classify(imagesFile: imageLocation, failure: failVisualRecognitionWithError) {
            classifiedImages in
            // Loop through classified images
            for classifiedImage in classifiedImages.images {
                // Loop through classifiers
                for classifier in classifiedImage.classifiers{
                    // Loop through classsification results
                    for classificationResult in classifier.classes{
                        // Set the result name, score and score percentage
                        resultName = classificationResult.className.uppercased()
                        resultScore = classificationResult.score
                        resultScorePercentage = String(Int(round(classificationResult.score! * 100))) + "%"
                        // Create new tag item based on result name, score and score percentage
                        let newTagItem = TagItem(watsonResultName: resultName,
                                                 watsonResultScore: resultScore,
                                                 watsonResultScorePercentage: resultScorePercentage)
                        // Append the new tag item to the tag items array
                        self.tagItems.append(newTagItem)
                    }
                }
            }
            
            DispatchQueue.main.sync {
                // Reload the tag collection view with the new tag items
                self.tagCollectionView.reloadData()
                // Hide the spinner
                SwiftSpinner.hide()
            }
        }
    }

    // Function to detect faces in image using Visual Recognition based on image location
    func detectFaces(_ imageLocation: URL){
        // String that will hold the result name from Watson
        var resultName: String!
        // Double that will hold the result scored from Watson
        var resultScore: Double!
        // String that will hold the result score percentage from Watson
        var resultScorePercentage: String!
        // Show the spinner while Watson is analyzing photo
        SwiftSpinner.show("Watson is Analyzing Photo")
        // Detect faces using Visual Recognition
        visualRecognition.detectFaces(imagesFile: imageLocation, failure: failVisualRecognitionWithError) {
            detectedFaces in
            // Loop through detected faces
            for detectedFace in detectedFaces.images {
                // Loop through the faces found in detectedFaces
                for face in detectedFace.faces {
                    
                    let gender = face.gender?.gender
                    
                    // Set the result name, score and score percentage
                    // Handle optional min and max ages
                    if let minAge = face.age?.min, let maxAge = face.age?.max, let genderScore = face.gender?.score, let faceScore = face.age?.score {
                        
                        resultName = gender! + "(\(minAge)-\(maxAge))"
                        resultScorePercentage = String(Int(round(genderScore * 100))) + "% (" + String(Int(round(faceScore * 100))) + "%)"
                        
                    } else if let minAge = face.age?.min, let genderScore = face.gender?.score, let faceScore = face.age?.score {
                        
                        resultName = gender! + " (\(minAge)-?)"
                        resultScorePercentage = String(Int(round(genderScore * 100))) + "% (" + String(Int(round(faceScore * 100))) + "%)"
                    }
                    else if let maxAge = face.age?.max, let genderScore = face.gender?.score, let faceScore = face.age?.score {
                        
                        resultName = gender! + " (?-\(maxAge)"
                        resultScorePercentage = String(Int(round(genderScore * 100))) + "% (" + String(Int(round(faceScore * 100))) + "%)"
                    }
                    else {
                        resultName = face.gender?.gender
                        resultScorePercentage = String(Int(round((face.gender?.score)! * 100)))
                    }
                    resultScore = face.gender?.score
                    // Create new tag item based on result name, score and score percentage
                    let newTagItem = TagItem(watsonResultName: resultName, watsonResultScore: resultScore, watsonResultScorePercentage: resultScorePercentage)
                    // Append the new tag item to the tag items array
                    self.tagItems.append(newTagItem)
                    // If celebrity match is found add set the result name, score, and score percentage
                    if(face.identity != nil){
                        resultName = face.identity?.name
                        resultScore = face.identity?.score
                        resultScorePercentage = String(Int(round(resultScore * 100))) + "% "
                        let newTagItem = TagItem(watsonResultName: resultName,
                                                 watsonResultScore: resultScore,
                                                 watsonResultScorePercentage: resultScorePercentage)
                        // Append the new tag item to the tag items array
                        self.tagItems.append(newTagItem)
                    }
                }
            }
            
            DispatchQueue.main.sync {
                // Reload the tag collection view with the new tag items
                self.tagCollectionView.reloadData()
                SwiftSpinner.hide()
            }
        }
    }

    func failVisualRecognitionWithError(_ error: Error) {
        // Print the error to the console
        print(error)
        // Clear the tagItems array
        tagItems = []
        // Reload the tag collection view with the new tag items
        self.tagCollectionView.reloadData()
        // Hide the spinner
        SwiftSpinner.hide()
        // Present an alert to the user describing what the problem may be
        showAlert("Visual Recognition Failed", alertMessage: "The Visual Recognition service failed to analyze the given photo. This could be due to invalid credentials, Internet connection or other errors. Please verify your credentials in the WatsonCredentials.plist and rebuild the application. See the README for further assistance.")

    }

    // Function to handle the number of items in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Return the number of items in the tagItems array
        return self.tagItems.count
    }

    // Funtion to get the cell for item at index path in the collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Create the cell that will reference the TagCollectionViewCell that is created
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionViewCell", for: indexPath) as? TagCollectionViewCell else {
            return UICollectionViewCell()
        }
        // Set the cell's tagLabel text to the Watson result name in the TagItem object
        cell.tagLabel.text = self.tagItems[(indexPath as NSIndexPath).item].watsonResultName
        // Set the cell's alpha value to a scaled value of the Watson result score
        cell.alpha = CGFloat((self.tagItems[(indexPath as NSIndexPath).item].watsonResultScore * 0.7) + 0.3)

        // Return the cell
        return cell
    }

    // Reload collection view on device rotation
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.tagCollectionView.reloadData()
    }

    // Function that creates the collection view layout based on the size of each text string
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        // Get the size based on the text string
        #if swift(>=4.0)
            let size = NSString(string: self.tagItems[(indexPath as NSIndexPath).item].watsonResultName).size(withAttributes: nil)
            // Return the given width and height
        #else
            let size = NSString(string: self.tagItems[(indexPath as NSIndexPath).item].watsonResultName).size(attributes: nil)
        #endif

        // Return the given width and height
        return CGSize(width: size.width + 60, height: 30.0)
    }


    // Function that handles actions when the user selects an item in the collection view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the selected cell
        let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell
        // If the cell text is currently the watson result name, change the text to the corresponding percentage
        if(cell?.tagLabel.text == self.tagItems[(indexPath as NSIndexPath).item].watsonResultName) {
            cell?.tagLabel.text = self.tagItems[(indexPath as NSIndexPath).item].watsonResultScorePercentage
        }
        // Otherwise change the text to the Watson result name
        else {
            cell?.tagLabel.text = self.tagItems[(indexPath as NSIndexPath).item].watsonResultName
        }
    }

    // Function to show an alert with an alertTitle String and alertMessage String
    func showAlert(_ alertTitle: String, alertMessage: String) {
        // If an alert is not currently being displayed
        if(self.presentedViewController == nil) {
            // Set alert properties
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            // Add an action to the alert
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
            // Show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }

}
