import Foundation

class CurrencyConverter {
    static let shared = CurrencyConverter()
    
    private var cachedRates: [String: Double] = [:]
    private var lastFetchDate: Date?
    private let cacheValidityHours: TimeInterval = 24
    
    private init() {}
    
    func convertToINR(priceString: String) async -> String? {
        guard let (amount, currencyCode) = parsePrice(priceString) else {
            return nil
        }
        
        if currencyCode.uppercased() == "INR" {
            return formatINRPrice(amount)
        }
        
        guard let rate = await getExchangeRate(from: currencyCode, to: "INR") else {
            return priceString
        }
        
        let inrAmount = amount * rate
        return formatINRPrice(inrAmount)
    }
    
    func convertToINR(amount: Double, from currencyCode: String) async -> Double? {
        if currencyCode.uppercased() == "INR" {
            return amount
        }
        
        guard let rate = await getExchangeRate(from: currencyCode, to: "INR") else {
            return nil
        }
        
        return amount * rate
    }
    
    private func parsePrice(_ priceString: String) -> (amount: Double, currencyCode: String)? {
        let trimmed = priceString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let currencyMap: [String: String] = [
            "$": "USD",
            "€": "EUR",
            "£": "GBP",
            "¥": "JPY",
            "₹": "INR",
            "A$": "AUD",
            "C$": "CAD",
            "CHF": "CHF",
            "CN¥": "CNY",
            "HK$": "HKD",
            "NZ$": "NZD",
            "SEK": "SEK",
            "NOK": "NOK",
            "DKK": "DKK",
            "PLN": "PLN",
            "R$": "BRL",
            "ZAR": "ZAR",
            "MXN": "MXN"
        ]
        
        var currencyCode = "USD"
        var cleaned = trimmed
        
        for (symbol, code) in currencyMap.sorted(by: { $0.key.count > $1.key.count }) {
            if trimmed.uppercased().contains(symbol.uppercased()) {
                currencyCode = code
                cleaned = cleaned.replacingOccurrences(of: symbol, with: "", options: .caseInsensitive)
                break
            }
        }
        
        cleaned = cleaned
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
        
        guard let amount = Double(cleaned) else {
            return nil
        }
        
        return (amount, currencyCode)
    }
    
    private func getExchangeRate(from: String, to: String) async -> Double? {
        let fromUpper = from.uppercased()
        let toUpper = to.uppercased()
        
        if fromUpper == toUpper {
            return 1.0
        }
        
        let cacheKey = "\(fromUpper)_\(toUpper)"
        
        if let cachedRate = cachedRates[cacheKey],
           let lastFetch = lastFetchDate,
           Date().timeIntervalSince(lastFetch) < cacheValidityHours * 3600 {
            return cachedRate
        }
        
        guard let rate = await fetchExchangeRate(from: fromUpper, to: toUpper) else {
            return cachedRates[cacheKey]
        }
        
        cachedRates[cacheKey] = rate
        lastFetchDate = Date()
        
        return rate
    }
    
    private func fetchExchangeRate(from: String, to: String) async -> Double? {
        let urlString = "https://api.exchangerate-api.com/v4/latest/\(from)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(ExchangeRateResponse.self, from: data)
            
            return response.rates[to]
        } catch {
            print("Currency conversion error: \(error)")
            return nil
        }
    }
    
    private func formatINRPrice(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }
}

struct ExchangeRateResponse: Codable {
    let base: String
    let date: String
    let rates: [String: Double]
}
