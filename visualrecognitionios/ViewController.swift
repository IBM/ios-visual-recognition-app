/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import UIKit
import SwiftSpinner
import KTCenterFlowLayout
import VisualRecognition
import BMSCore








class ViewController: UIViewController, UICollectionViewDataSource, UINavigationControllerDelegate {

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

        // Instantiate Watson Visual Recognition Service
        self.configureVisualRecognition()

        // Configure Tag Collection View
        self.configureTagCollectionView()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        
        
        
        
    }

    override func viewDidAppear(_ animated: Bool) {
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
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            // Create image picker using image picker controller
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            // Assign image picker source to the camera
            imagePicker.sourceType = .camera
            // Assign the image picker allowsEditing field to true
            imagePicker.allowsEditing = true
            // Present the view controller
            self.present(imagePicker, animated: true, completion: nil)
        }
        // Show alert when the camera is unavailable
        else {
            showAlert(.cameraUnavailable)
        }
    }

    // Button action that opens the photo library to choose a photo
    @IBAction func openPhotoLibrary(_ sender: AnyObject) {
        // Check if photo library source is available
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
            // Create image picker using image picker controller
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            // Assign image picker source to the photo library
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            // Assign the image picker allowsEditing field false
            imagePicker.allowsEditing = true
            // Present the view controller
            self.present(imagePicker, animated: true, completion: nil)
        }
        // Show alert when photo library is unavailable
        else {
            showAlert(.photoLibraryUnavailable)
        }
    }

    // Configure VR Tag Collection View
    func configureTagCollectionView() {
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
        tagCollectionView.backgroundColor = UIColor.clear
        tagCollectionView.collectionViewLayout = layout

        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
    }

    // Configure Visual Recognition Service
    func configureVisualRecognition() {
        // Create a configuration path for the BMSCredentials.plist file then read in the Watson credentials
        // from the plist configuration dictionary
        guard let configurationPath = Bundle.main.path(forResource: "BMSCredentials", ofType: "plist"),
              let configuration = NSDictionary(contentsOfFile: configurationPath) else {
                showAlert(.missingCredentials)
                return
        }

        // Get the Service URL
        guard let url = configuration["visualrecognitionUrl"] as? String else {
            showAlert(.invalidCredentials)
            return
        }

        // Set date string for version of Watson service to use
        let versionDate = "2018-02-01"

        // Set the Watson credentials for Visual Recognition service from the BMSCredentials.plist
        // If using IAM authentication
        if let apiKey = configuration["visualrecognitionApikey"] as? String {

            // Create service sdks
            let authenticator = WatsonIAMAuthenticator(apiKey: apiKey)
            self.visualRecognition = VisualRecognition(version: versionDate, authenticator: authenticator)

        // If using user/pwd authentication
        } else if let apiKey = configuration["visualrecognitionApi_key"] as? String {

            // Create service sdks
            let authenticator = WatsonIAMAuthenticator(apiKey: apiKey)
            self.visualRecognition = VisualRecognition(version: versionDate, authenticator: authenticator)

        } else {
            showAlert(.missingCredentials)
        }

        visualRecognition.serviceURL = url
    }

    // Function to classify image using Visual Recognition based on image location
    func classifyImage(_ imageLocation: URL) {
        // String that will hold the result name from Watson
        var resultName: String!
        // Double that will hold the result scored from Watson
        var resultScore: Double!
        // String that will hold the result score percentage from Watson
        var resultScorePercentage: String!
        // Classify image using Visual Recognition
        visualRecognition.classify(url: imageLocation.absoluteString, acceptLanguage: "en") { response, error in
            if let error = error {
               self.failVisualRecognitionWithError(error)
               return
            }
            guard let classifiedImages = response?.result else {

                DispatchQueue.main.async {
                    SwiftSpinner.hide()
                    self.showAlert(.noData)
                }
                return
            }
            // Loop through classified images
            for classifiedImage in classifiedImages.images {
                // Loop through classifiers
                for classifier in classifiedImage.classifiers {
                    // Loop through classsification results
                    for classificationResult in classifier.classes {
                        // Set the result name, score and score percentage
                        resultName = classificationResult.class.uppercased()
                        resultScore = classificationResult.score
                        resultScorePercentage = String(Int(round(classificationResult.score * 100))) + "%"
                        // Create new tag item based on result name, score and score percentage
                        let newTagItem = TagItem(watsonResultName: resultName,
                                                 watsonResultScore: resultScore,
                                                 watsonResultScorePercentage: resultScorePercentage)
                        // Append the new tag item to the tag items array
                        self.tagItems.append(newTagItem)
                    }
                }
            }

            self.reloadCollectionViewTags()
        }
    }

    // Method to reload Collection View
    func reloadCollectionViewTags() {
        DispatchQueue.main.async {
            // Reload the tag collection view with the new tag items
            self.tagCollectionView.reloadData()
            // Hide Spinner
            SwiftSpinner.hide()
        }
    }

    // Method to handle face recognition error
    func failFaceDetectionWithError(_ error: Error) {
        // Print the error to the console
        print("Face Detection Error:", error)
    }

    // Method to handle Visual Recognition Error
    func failVisualRecognitionWithError(_ error: Error) {
        // Print the error to the console
        print(error)
        // Clear the tagItems array
        tagItems = []
        // Update UI on main thread
        DispatchQueue.main.async {
            // Reload the tag collection view with the new tag items
            self.tagCollectionView.reloadData()
            // Hide the spinner
            SwiftSpinner.hide()
            // Present an alert to the user describing what the problem may be
            self.showAlert(.error(error.localizedDescription))
        }
    }

    // Method to show an alert with an alertTitle String and alertMessage String
    func showAlert(_ error: ApplicationError) {
        // Log error
        print(error.description)
        // If an alert is not currently being displayed
        if self.presentedViewController == nil {
            // Set alert properties
            let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
            // Add an action to the alert
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            // Show the alert
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // Method to handle the number of items in the collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Return the number of items in the tagItems array
        return self.tagItems.count
    }

    // Method to get the cell for item at index path in the collection view
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

    // Method that creates the collection view layout based on the size of each text string
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Get the size based on the text string
        let size = NSString(string: self.tagItems[(indexPath as NSIndexPath).item].watsonResultName).size(withAttributes: nil)

        // Return the given width and height
        return CGSize(width: size.width + 60, height: 30.0)
    }

    // Method that handles actions when the user selects an item in the collection view
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the selected cell
        let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell
        // If the cell text is currently the watson result name, change the text to the corresponding percentage
        if cell?.tagLabel.text == self.tagItems[(indexPath as NSIndexPath).item].watsonResultName {
            cell?.tagLabel.text = self.tagItems[(indexPath as NSIndexPath).item].watsonResultScorePercentage
        }
            // Otherwise change the text to the Watson result name
        else {
            cell?.tagLabel.text = self.tagItems[(indexPath as NSIndexPath).item].watsonResultName
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {

    // Method that dismisses the image picker controller when the user cancel selecting an image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    // Method that handles the actions once an image is chosen from the image picker controller
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        // Retrieve image from dictionary
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }

        // Set the visual recognition image to the chosen image
        visualRecognitionImage.image = image
        // Dismiss the view controller
        self.dismiss(animated: true, completion: nil)
        // Create a document URL to save the file into
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Save the image as a JPEG
        let imageToSave: Data = image.jpegData(compressionQuality: 1.0)!
        // Append file name to document location
        let fileURL = documentsURL.appendingPathComponent("tempImage.png")
        // Save the image in the provided location
        try? imageToSave.write(to: fileURL, options: [])
        // Clear the tagItems array
        tagItems = []
        // Show the spinner while Watson is analyzing photo
        SwiftSpinner.show("Watson is Analyzing Photo")
        // Call the classifyImage function with the saved image
        classifyImage(fileURL)
    }
}




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
