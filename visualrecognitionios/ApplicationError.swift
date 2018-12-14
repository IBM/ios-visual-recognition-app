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

import Foundation

enum ApplicationError: Error, CustomStringConvertible {

    case missingCredentials

    case invalidCredentials

    case photoLibraryUnavailable
    
    case cameraUnavailable

    case error(String)

    var title: String {
        switch self {
        case .missingCredentials: return "Missing Visual Recognition Credentials"
        case .invalidCredentials: return "Invalid Visual Recognition Credentials"
        case .photoLibraryUnavailable: return "Photo Library Unavailable"
        case .cameraUnavailable: return "Camera Unavailable"
        case .error: return "Visual Recognition Failed"
        }
    }

    var message: String {
        switch self {
        case .missingCredentials: return "Please check the readme to ensure proper credentials configuration."
        case .invalidCredentials: return "Please check the readme to ensure proper credentials configuration."
        case .photoLibraryUnavailable: return "The Photo Library feature is currently unavailable on this device. Please try again."
        case .cameraUnavailable: return "The camera feature is currently unavailable on this device. If you are running the application on a simulator, please use a physical device in order to utilize camera functionality."
        case .error(let msg): return msg
        }
    }

    var description: String {
        return title + ": " + message
    }
}
