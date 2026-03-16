//
//  WeatherManager.swift
//  NotchBar
//
//  날씨 정보 관리 (WeatherKit 또는 Open-Meteo)
//

import Foundation
import CoreLocation
import Combine

class WeatherManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = WeatherManager()
    
    // MARK: - Published Properties
    
    @Published var temperature: Double = 0
    @Published var condition: WeatherCondition = .unknown
    @Published var conditionDescription: String = ""
    @Published var humidity: Int = 0
    @Published var locationName: String = "위치 확인 중..."
    @Published var isLoading: Bool = true
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var lastUpdate: Date?
    private let updateInterval: TimeInterval = 600 // 10분
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func refresh() {
        guard let location = lastLocation else {
            locationManager.startUpdatingLocation()
            return
        }
        fetchWeather(for: location)
    }
    
    // MARK: - Private Methods
    
    private func fetchWeather(for location: CLLocation) {
        // Open-Meteo API 사용 (무료, API 키 불필요)
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto"
        
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            defer {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any]
            else {
                return
            }
            
            DispatchQueue.main.async {
                if let temp = current["temperature_2m"] as? Double {
                    self?.temperature = temp
                }
                if let humidity = current["relative_humidity_2m"] as? Int {
                    self?.humidity = humidity
                }
                if let code = current["weather_code"] as? Int {
                    self?.condition = WeatherCondition.from(code: code)
                    self?.conditionDescription = self?.condition.description ?? ""
                }
                self?.lastUpdate = Date()
            }
        }.resume()
        
        // 위치 이름 업데이트
        updateLocationName(for: location)
    }
    
    private func updateLocationName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let placemark = placemarks?.first else { return }
            
            DispatchQueue.main.async {
                if let locality = placemark.locality {
                    self?.locationName = locality
                } else if let area = placemark.administrativeArea {
                    self?.locationName = area
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 최소 거리 이동 또는 시간 경과 시에만 업데이트
        if let lastLocation = lastLocation,
           let lastUpdate = lastUpdate,
           location.distance(from: lastLocation) < 1000,
           Date().timeIntervalSince(lastUpdate) < updateInterval {
            return
        }
        
        lastLocation = location
        fetchWeather(for: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ 위치 오류: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.locationName = "위치 확인 실패"
            self?.isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            DispatchQueue.main.async { [weak self] in
                self?.locationName = "위치 권한 필요"
                self?.isLoading = false
            }
        default:
            break
        }
    }
}

// MARK: - WeatherCondition

enum WeatherCondition: String {
    case clear = "맑음"
    case partlyCloudy = "구름 조금"
    case cloudy = "흐림"
    case fog = "안개"
    case drizzle = "이슬비"
    case rain = "비"
    case snow = "눈"
    case thunderstorm = "천둥번개"
    case unknown = "알 수 없음"
    
    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .fog: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var description: String { rawValue }
    
    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 0: return .clear
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .fog
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .unknown
        }
    }
}
