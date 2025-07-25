//
//  APIService.swift
//  SmartLabsNative
//
//  Created by SmartLabs Team
//  Copyright © 2024 SmartLabs. All rights reserved.
//

import Foundation

class APIService {
    static let shared = APIService()
    
    // URL base exacta del Flutter
    private let baseURL = "http://192.168.0.100:3001/api"
    private let defaultTimeout: TimeInterval = 10.0
    private let loanTimeout: TimeInterval = 15.0
    
    private init() {}
    
    // MARK: - Login por matrícula (igual que Flutter)
    func getUserByRegistration(_ registration: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/registration/\(registration)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        
        if loginResponse.success {
            return loginResponse.data
        } else {
            throw APIError.loginFailed(loginResponse.message ?? "Error al iniciar sesión")
        }
    }
    
    // MARK: - Device Status (igual que Flutter)
    func getDeviceStatus(_ deviceSerie: String) async throws -> DeviceStatusResponse {
        let url = URL(string: "\(baseURL)/devices/\(deviceSerie)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.timeoutInterval = defaultTimeout
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Respuesta HTTP getDeviceStatus: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(DeviceStatusResponse.self, from: data)
                print("Estado del dispositivo obtenido: \(result)")
                return result
            } else {
                print("Error HTTP al obtener estado del dispositivo: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Respuesta del servidor: \(errorString)")
                }
                throw APIError.invalidResponse
            }
        } catch {
            print("Excepción en getDeviceStatus: \(error)")
            if error is DecodingError {
                throw APIError.decodingError
            } else {
                throw APIError.networkError
            }
        }
    }
    
    // MARK: - Control Device (igual que Flutter)
    func controlDevice(_ registration: String, deviceSerie: String, action: Int) async throws -> ControlResponse {
        let url = URL(string: "\(baseURL)/devices/control")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = defaultTimeout
        
        let requestBody = [
            "registration": registration,
            "device_serie": deviceSerie,
            "action": action
        ] as [String : Any]
        
        print("Enviando control de dispositivo: \(requestBody)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("Respuesta del control de dispositivo: \(httpResponse.statusCode) - \(String(data: data, encoding: .utf8) ?? "Sin contenido")")
            
            if httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(ControlResponse.self, from: data)
                print("Control de dispositivo exitoso: \(result)")
                return result
            } else {
                print("Error HTTP en control de dispositivo: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Respuesta del servidor: \(errorString)")
                }
                throw APIError.invalidResponse
            }
        } catch {
            print("Excepción en controlDevice: \(error)")
            if error.localizedDescription.contains("timeout") || error.localizedDescription.contains("timed out") {
                throw APIError.networkError
            } else if error is DecodingError {
                throw APIError.decodingError
            } else {
                throw APIError.networkError
            }
        }
    }
    
    // MARK: - Loan Status (igual que Flutter)
    func getLoanStatus() async throws -> LoanStatusResponse {
        let url = URL(string: "\(baseURL)/prestamo/estado")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.timeoutInterval = defaultTimeout
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("Error HTTP al obtener estado: \(statusCode)")
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(LoanStatusResponse.self, from: data)
        print("Estado de préstamo obtenido: \(result)")
        return result
    }
    
    // MARK: - Control Loan (igual que Flutter)
    func controlLoan(_ registration: String, deviceSerie: String, action: Int) async throws -> ControlResponse {
        let url = URL(string: "\(baseURL)/prestamo/control")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = loanTimeout
        
        let requestBody = [
            "registration": registration,
            "device_serie": deviceSerie,
            "action": action
        ] as [String : Any]
        
        print("Enviando control de préstamo: \(requestBody)")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("Respuesta del servidor: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("Error HTTP en control de préstamo: \(statusCode)")
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(ControlResponse.self, from: data)
        print("Control de préstamo exitoso: \(result)")
        return result
    }
    
    // MARK: - Simulate Loan (igual que Flutter)
    func simulateLoan(_ registration: String, deviceSerie: String) async throws -> ControlResponse {
        let url = URL(string: "\(baseURL)/prestamo/simular")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = defaultTimeout
        
        let requestBody = [
            "registration": registration,
            "device_serie": deviceSerie
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(ControlResponse.self, from: data)
    }
}

// MARK: - API Models (actualizadas para coincidir con Flutter)
struct LoginResponse: Codable {
    let success: Bool
    let message: String?
    let data: User
}

struct DeviceStatusResponse: Codable {
    let success: Bool
    let message: String?
    let data: DeviceData?
    
    struct DeviceData: Codable {
        let device_serie: String
        let device_alias: String
        let state: Bool
        let status: String
        let lastUpdate: String?
        let isFirstUse: Bool?
        let timestamp: String
        
        enum CodingKeys: String, CodingKey {
            case device_serie
            case device_alias
            case state
            case status
            case lastUpdate
            case isFirstUse
            case timestamp
        }
    }
}

struct LoanStatusResponse: Codable {
    let success: Bool
    let data: LoanData
    
    struct LoanData: Codable {
        let sessionActive: Bool
        let user: String?
        
        enum CodingKeys: String, CodingKey {
            case sessionActive = "session_active"
            case user
        }
    }
}

struct ControlResponse: Codable {
    let success: Bool
    let message: String?
    let data: ControlData?
    let error: String?
    
    struct ControlData: Codable {
        let action: String?
        let state: Bool?
        let device: String?
        let user: UserData?
        let timestamp: String?
        let device_serie: String?
        let device_name: String?
        
        struct UserData: Codable {
            let name: String?
        }
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidResponse
    case loginFailed(String)
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .loginFailed(let message):
            return message
        case .networkError:
            return "Error de conexión"
        case .decodingError:
            return "Error al procesar datos"
        }
    }
}