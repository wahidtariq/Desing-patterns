//
//  main.swift
//  Design patterns
//
//  Created by wahid tariq on 02/06/24.
//

import Foundation

struct User: Codable {
    let id = UUID()
    let name: String
}

/**
 The repository design pattern starts by defining the interface using a protocol in Swift.
 For example, imagine having a database with users. We would define a protocol to create, retrieve, or delete a user:
 */
protocol UserRepository {
    func create(_ user: User) async throws
    func find(id: UUID) async throws -> User?
    func remove(id: UUID) async throws
}

final class UsersViewModel {
    
    let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func createUser(name: String) async throws {
        let user = User(name: name)
        try await repository.create(user)
    }
    
    func delete(user: User) async throws {
        try await repository.remove(id: user.id)
    }
    
    func findUser(for id: UUID) async throws -> User? {
        try await repository.find(id: id)
    }
}

/**
 After defining the repository protocol, you can create the implementation layers.
 I always prefer to start with the in-memory layer as it allows me to quickly test my application while also setting me up for writing any unit tests.
 */
actor InMemoryUserRepository: UserRepository {
    
    private var users: [User] = []
    
    func create(_ user: User) async throws {
        users.append(user)
    }
    
    func remove(id: UUID) async throws {
        users.removeAll { $0.id == id }
    }
    
    func find(id: UUID) async throws -> User? {
        users.first { $0.id == id }
    }
}

/**
 A secondary implementation could be used in production using another type of data layer. For example, you could decide to store all users in the User Defaults:
 */
struct UserDefaultsUserRepository: UserRepository {
    
    var userDefaults: UserDefaults = .standard
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func create(_ user: User) async throws {
        var users = try fetchUsers()
        users.append(user)
        try store(users: users)
    }
    
    func remove(id: UUID) async throws {
        var users = try fetchUsers()
        users.removeAll(where: { $0.id == id })
        try store(users: users)
    }
    
    func find(id: UUID) async throws -> User? {
        try fetchUsers().first(where: { $0.id == id })
    }
    
    private func fetchUsers() throws -> [User] {
        guard let usersData = userDefaults.object(forKey: "users") as? Data else {
            return []
        }
        return try decoder.decode([User].self, from: usersData)
    }
    
    private func store(users: [User]) throws {
        let usersData = try encoder.encode(users)
        userDefaults.set(usersData, forKey: "users")
    }
}


/// Using an in-memory store:
let viewModel = UsersViewModel(repository: InMemoryUserRepository())

/// Or use `UserDefaults`
let viewModel1 = UsersViewModel(repository: UserDefaultsUserRepository())
