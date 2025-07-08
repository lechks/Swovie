//
//  AuthService.swift
//  Swovie-app
//
//  Created by Екатерина Максаева on 05.07.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()
        
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
        
    func fetchUserData(completion: @escaping (Result<User, Error>) -> Void) {
        guard let userId = currentUserId else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
            
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
                
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                return
            }
            
            let profile = User(
                id: userId,
                name: data["name"] as? String ?? "",
                avatarName: data["avatarName"] as? UIColor ?? .systemGray
            )
            
            completion(.success(profile))
        }
    }
    
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }
    
}
    


