import Foundation

// MARK: - Models

struct BalanceResponse: Decodable {
    let balanceInfos: [BalanceInfo]
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case balanceInfos = "balance_infos"
        case isAvailable = "is_available"
    }
}

struct BalanceInfo: Decodable {
    let totalBalance: String
    let toppedUpBalance: String
    let grantedBalance: String
    let currency: String

    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case toppedUpBalance = "topped_up_balance"
        case grantedBalance = "granted_balance"
        case currency
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidKey
    case networkError(Error)
    case httpError(statusCode: Int)
    case decodingError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "API Key 未设置，请在设置中输入 Key"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP \(code) — 请检查 API Key 是否正确"
        case .decodingError:
            return "数据解析失败"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - API Service

final class DeepSeekAPIService {
    static let shared = DeepSeekAPIService()
    private let baseURL = "https://api.deepseek.com"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func fetchBalance(apiKey: String) async throws -> BalanceResponse {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw APIError.invalidKey
        }

        guard let url = URL(string: "\(baseURL)/user/balance") else {
            throw APIError.unknown
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "", code: -1))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(BalanceResponse.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}
