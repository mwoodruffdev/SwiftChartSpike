//
//  ContentView.swift
//  SwiftChartEvaluation
//
//  Created by Michael Woodruff on 19/6/2022.
//

import Charts
import SwiftUI

struct ContentView: View {
    @State var response: [StockResponse]?
    
    var body: some View {
        VStack {
            Text("Stock Graph Demo")
            HStack {
                Spacer().frame(width: 10)
                switch response {
                case .none:
                    ProgressView().onAppear {
                        self.loadData(ticker: "AAPL")
                        self.loadData(ticker: "TSLA")
                    }
                case .some(let response):
                    Chart(response) { series in
                        ForEach(series.results) { point in
                            LineMark(
                                x: .value("Day", Date(timeIntervalSince1970: point.t / 1000), unit: .weekday),
                                y: .value("Price", point.c)
                            )
                            .foregroundStyle(by: .value("Ticker", series.ticker))
                        }
                    }
                }
                Spacer().frame(width: 10)
            }
            Spacer().frame(height: 100)
        }
    }
    
    func loadData(ticker: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let todayStr = dateFormatter.string(from: today)
        var dateComponent = DateComponents()
        dateComponent.month = -3
        guard let threeMonthsAgo = Calendar.current.date(byAdding: dateComponent, to: today) else {
            print("Error - Cannot construct date")
            return
        }
        let threeMonthsAgoStr = dateFormatter.string(from: threeMonthsAgo)
        
        //TODO - Add your Polygon API Key here
        let apiKey = ""
        guard let url = URL(string: "https://api.polygon.io/v2/aggs/ticker/\(ticker)/range/1/day/\(threeMonthsAgoStr)/\(todayStr)?adjusted=true&sort=asc&limit=120&apiKey=\(apiKey)") else {
            print("Invalid URL")
            return
        }
        print("calling url: \(url)")
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(StockResponse.self, from: data)
                    DispatchQueue.main.async {
                        if self.response == nil {
                            let initial = [response]
                            self.response = initial
                        } else {
                            self.response?.append(response)
                        }
                    }
                    return
                } catch {
                    print("cannot decode: \(ticker). error : \(error)")
                }
            } else if let error = error {
                print("error: \(error)")
            }
        }.resume()
    }
}

struct StockResponse: Decodable, Identifiable {
    var id: String { ticker }
    let ticker: String
    let results: [StockResponseResults]
}

struct StockResponseResults: Decodable, Identifiable {
    var id: TimeInterval { t }
    
    let o: Double
    let c: Double
    let t: TimeInterval
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
