import Foundation
import Alamofire

class PinataManager {
    static let shared = PinataManager()

    private let pinataAPIKey = "0a44ee1498346ea2f115" // Replace with your actual API key
    private let pinataSecretAPIKey = "ee7ac2b33bacf3cfa6fe8de91f34891cf592aef883970260f1ee24cba364f68a" // Replace with your actual secret
    private let pinataBaseURL = "https://api.pinata.cloud"
    private let pinataGatewayURL = "https://gateway.pinata.cloud/ipfs"

    private init() {}

    // MARK: - Upload File to Pinata
    func uploadFileToPinata(fileURL: URL, pinName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "pinata_api_key": pinataAPIKey,
            "pinata_secret_api_key": pinataSecretAPIKey
        ]
        
        AF.upload(multipartFormData: { formData in
            formData.append(fileURL, withName: "file", fileName: fileURL.lastPathComponent, mimeType: "application/octet-stream")
            
            // Add metadata with the pin name
            let metadata = ["name": pinName]
            if let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: []) {
                formData.append(jsonData, withName: "pinataMetadata")
            }
        }, to: "\(pinataBaseURL)/pinning/pinFileToIPFS", headers: headers)
        .validate()
        .responseJSON { response in
            switch response.result {
            case .success(let data):
                if let result = data as? [String: Any],
                   let cid = result["IpfsHash"] as? String {
                    print("File uploaded successfully. CID: \(cid)")
                    completion(.success(cid))
                } else {
                    completion(.failure(NSError(domain: "PinataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Download File from Pinata
    func downloadFile(cid: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let url = "\(pinataGatewayURL)/\(cid)"

        let destination: DownloadRequest.Destination = { _, _ in
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationURL = documentsDirectory.appendingPathComponent("augmented-rx.sqlite")
            return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download(url, to: destination)
            .validate()
            .response { response in
                switch response.result {
                case .success(let fileURL):
                    if let fileURL = fileURL {
                        print("Database downloaded successfully to: \(fileURL)")
                        completion(.success(fileURL))
                    } else {
                        completion(.failure(NSError(domain: "PinataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No file URL"])))
                    }
                case .failure(let error):
                    print("Failed to download database: \(error)")
                    completion(.failure(error))
                }
            }
    }

    // MARK: - Delete File from Pinata
    func deleteFile(cid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = "\(pinataBaseURL)/pinning/unpin/\(cid)"

        let headers: HTTPHeaders = [
            "pinata_api_key": pinataAPIKey,
            "pinata_secret_api_key": pinataSecretAPIKey
        ]

        AF.request(url, method: .delete, headers: headers)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    print("File deleted successfully. CID: \(cid)")
                    completion(.success(()))
                case .failure(let error):
                    print("Failed to delete file: \(error)")
                    completion(.failure(error))
                }
            }
    }

    // MARK: - List All Pinned Files
    func listPinnedFiles(completion: @escaping (Result<[PinnedFile], Error>) -> Void) {
        let url = "\(pinataBaseURL)/data/pinList"

        let headers: HTTPHeaders = [
            "pinata_api_key": pinataAPIKey,
            "pinata_secret_api_key": pinataSecretAPIKey
        ]

        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: PinListResponse.self) { response in
                switch response.result {
                case .success(let result):
                    print("Fetched pinned files successfully.")
                    completion(.success(result.rows))
                case .failure(let error):
                    print("Failed to fetch pinned files: \(error)")
                    completion(.failure(error))
                }
            }
    }

    // MARK: - Fetch Database by CID
    func fetchDatabase(cid: String, completion: @escaping (Result<URL, Error>) -> Void) {
        downloadFile(cid: cid, completion: completion)
    }
}

// MARK: - Pinata Response Models
struct PinListResponse: Decodable {
    let rows: [PinnedFile]
}

struct PinnedFile: Decodable {
    let ipfs_pin_hash: String
}
