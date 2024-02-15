//
//  WeatherListViewController.swift
//  Weather777
//
//  Created by Jason Yang on 2/5/24.
//

import UIKit
import MapKit
import CoreLocation
import SwiftUI

//// MARK: - PreView
//struct PreView: PreviewProvider
//{
//    static var previews: some View
//    {
//        WeatherListViewController().toPreview()
//    }
//}
//
//
//#if DEBUG
//extension UIViewController {
//    private struct Preview: UIViewControllerRepresentable
//    {
//        let viewController: UIViewController
//
//        func makeUIViewController(context: Context) -> UIViewController
//        {
//            return viewController
//        }
//
//        func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
//    }
//
//    func toPreview() -> some View
//    {
//        Preview(viewController: self)
//    }
//}
//#endif

struct WeatherInfo
{
    var cityName: String
    var time: String
    var weatherDescription: String
    var temperature: Double
    var tempMax: Double
    var tempMin: Double
}

class WeatherListViewController: UIViewController
{
    let cityListManager = CityListManager.shared
    
    lazy var printButton: UIButton =
    {
        let button = UIButton()
        button.setTitle("출력", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(printcity), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    @objc func printcity()
    {
        let Datas = cityListManager.readAll()
        for coord in Datas
        {print("UserDefaults \(coord.lat), \(coord.lon)") }   // 저장된 위도 경도 값
        print(weatherDataList[index].cityName)
        print(weatherDataList[index + 1].time)
        print(weatherDataList[index + 2].weatherDescription)
        print(weatherDataList[index + 3].temperature)
        print(weatherDataList[index + 4].tempMax)
        print(weatherDataList[index + 5].tempMin)
    }
    
    func showList()
    {
        // CityListManager의 readAll() 메서드를 사용하여 저장된 데이터를 불러옵니다.
        let manager = CityListManager.shared
        let storedData = manager.readAll()

        // 특정 인덱스의 값을 확인하려면 해당 인덱스에 해당하는 데이터를 가져옵니다.
        let index = 0 // 확인하려는 인덱스
        if index < storedData.count 
        {
            let coord = storedData[index]
            // 해당 인덱스의 값 출력
            updateWetherInfo(latitude: coord.lat, longitude: coord.lon)
        }
        else {
            print("해당 인덱스에 데이터가 없습니다.")
        }
        weatherListTableView.reloadData()
    }
    
    var temperatureUnits: String = "C"
    var checkdCelsiusAction: UIMenuElement.State = .on
    var checkedFahrenheitAction: UIMenuElement.State = .off
    
    lazy var locationData: [CLLocationCoordinate2D] = []
    var weatherDataList: [WeatherInfo] = [WeatherInfo(cityName: "", time: "", weatherDescription: "", temperature: 0, tempMax: 0, tempMin: 0)]
    var index: Int = 0
    
    func updateWetherInfo(latitude: Double, longitude: Double)
    {
        let latitude = latitude
        let longitude = longitude
        
        print("날씨 정보 함수")

        WeatherManager.shared.getForecastWeather(latitude: latitude, longitude: longitude)
        { [weak self] result in
            switch result
            {
            case .success(let data):
                // 현재 시각
                let now = Date()
                var selectedData = [(cityname: String, time: String, weatherIcon: String, weatherdescription: String, temperature: Double, wind: String, humidity: Int, tempMin: Double, tempMax: Double, feelsLike: Double, rainfall: Double)]()

                // DateFormatter 설정
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                // 가장 가까운 과거 시간 찾기
                var closestPastIndex = -1
                for (index, forecast) in data.enumerated() {
                    if let date = dateFormatter.date(from: forecast.time), date <= now {
                        closestPastIndex = index
                    } else {
                        break // 이미 과거 시간 중 가장 가까운 시간을 찾았으므로 반복 중단
                    }
                }

                // 가장 가까운 과거 시간부터 8개 데이터 선택
                if closestPastIndex != -1 {
                    let startIndex = closestPastIndex
                    let endIndex = min(startIndex + 8, data.count)
                    selectedData = Array(data[startIndex..<endIndex])
                }

                    if let firstSelectData = selectedData.first
                    {
                        let cityName = NSLocalizedString(firstSelectData.cityname, comment: "")
                        let time = firstSelectData.time
                        let weatherDescription = firstSelectData.weatherdescription
                        let temperature = firstSelectData.temperature
                        let tempMax = firstSelectData.tempMax
                        let tempMin = firstSelectData.tempMin
                        
                        self?.weatherDataList.append(WeatherInfo(cityName: cityName, time: time, weatherDescription: weatherDescription, temperature: temperature, tempMax: tempMax, tempMin: tempMin))
                    }
                
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
// MARK: - UI 구성
    let weatherLabel: UILabel =
    {
        let label = UILabel()
        label.text = "날씨"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 32)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    lazy var settingButton: UIButton =
    {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold, scale: .medium)
        button.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.setTitleColor(.clear, for: .normal)
        
        let edit = UIAction(title: "목록 편집", image: UIImage(systemName: "pencil"), state: .off, handler: { _ in print("목록 편집") })
        let C = UIAction(title: "섭씨", image: UIImage(named: "°C"), state: checkdCelsiusAction, handler: { _ in
            self.temperatureUnits = "C"
            self.checkdCelsiusAction = .on
            self.checkedFahrenheitAction = .off
            self.updateMenu()
        })
        let F = UIAction(title: "화씨", image: UIImage(named: "°F"), state: checkedFahrenheitAction, handler: { _ in
            self.temperatureUnits = "F"
            self.checkdCelsiusAction = .off
            self.checkedFahrenheitAction = .on
            self.updateMenu()
        })
        
        let line = UIMenu(title: "", options: .displayInline, children: [C, F])
        let menu = UIMenu(title: "", children: [edit, line])
        
        button.menu = menu
        
        button.showsMenuAsPrimaryAction = true
        button.changesSelectionAsPrimaryAction = false
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()

    lazy var locationSearchBar: UISearchBar =
    {
        let searchBar = UISearchBar()
        
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: "도시 또는 공항 검색", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightText])
        searchBar.barTintColor = UIColor.clear
        searchBar.searchTextField.textColor = .white
        
        searchBar.autocorrectionType = .no
        searchBar.spellCheckingType = .no
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).title = "취소"
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        return searchBar
    }()
    
    let weatherListTableView: UITableView =
    {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
// MARK: - Life Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        
        showList()
        
        locationSearchBar.delegate = self
        
        weatherListTableView.dataSource = self
        weatherListTableView.delegate = self
        
        let weatherListnib = UINib(nibName: "WeatherListTableViewCell", bundle: nil)
        weatherListTableView.register(weatherListnib, forCellReuseIdentifier: "WeatherListTableViewCell")
        weatherListTableView.separatorStyle = .singleLine
        
        registerObserver()
        addSubView()
        setLayout()
        
    }
    override func viewWillAppear(_ animated: Bool) 
    {
        showList()
    }
    
// MARK: - 레이아웃 지정
        func addSubView()
        {
            view.addSubview(weatherLabel)
            view.addSubview(settingButton)
            view.addSubview(locationSearchBar)
            view.addSubview(weatherListTableView)
            view.addSubview(printButton)
        }
        
        func setLayout()
        {
            NSLayoutConstraint.activate([
                printButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                printButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
                printButton.widthAnchor.constraint(equalToConstant: 40),
                printButton.heightAnchor.constraint(equalToConstant: 30),
                weatherLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                weatherLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            
                settingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                settingButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
                settingButton.widthAnchor.constraint(equalToConstant: 30),
                settingButton.heightAnchor.constraint(equalToConstant: 30),
            
                locationSearchBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                locationSearchBar.topAnchor.constraint(equalTo: weatherLabel.bottomAnchor, constant: 20),
                locationSearchBar.widthAnchor.constraint(equalToConstant: 384),
                locationSearchBar.heightAnchor.constraint(equalToConstant: 30),
            
                weatherListTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                weatherListTableView.topAnchor.constraint(equalTo: locationSearchBar.bottomAnchor, constant: 15),
                weatherListTableView.widthAnchor.constraint(equalToConstant: 370),
                weatherListTableView.heightAnchor.constraint(equalToConstant: 600)
            ])
        }
    
// MARK: - Notification
    func registerObserver()
    {
       NotificationCenter.default.addObserver(
         self,
         selector: #selector(appendLocationData),
         name: NSNotification.Name("sendLocationData"),
         object: nil
       )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(appendWeatherData),
          name: NSNotification.Name("sendWeatherData"),
          object: nil
        )
        
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(dismissView),
          name: NSNotification.Name("dismissView"),
          object: nil
        )
     }
    
    @objc func appendLocationData(notification: NSNotification)
    {
        locationData.append(notification.object as! CLLocationCoordinate2D)
        UIView.animate(withDuration: 0)
        {
            self.view.frame.origin.y = 0
        }
        self.locationSearchBar.isHidden = false
      }
    
    @objc func appendWeatherData(notification: NSNotification)
    {
//        weatherDataList.append((notification.object as? [SendData]))
            if let receivedData = notification.object as? [SendData] 
            {
                for data in receivedData
                {
                    let weatherInfo = WeatherInfo(cityName: data.cityName, time: data.time, weatherDescription: data.weatherDescription, temperature: data.temperature, tempMax: data.tempMax, tempMin: data.tempMin)
                    weatherDataList.append(weatherInfo)
                }
            }
//        updateWetherInfo(latitude: locationData[index].latitude, longitude: locationData[index].longitude)
        weatherListTableView.reloadData()
        index += 1
    }
    
    @objc func dismissView(notification: NSNotification)
    {
        UIView.animate(withDuration: 0)
        {
            self.view.frame.origin.y = 0
            self.locationSearchBar.isHidden = false
        }
      }
    
// MARK: - settingButton의 UIMenu와 변경된 온도 단위를 tableView에 적용
    func updateMenu()
    {
        if temperatureUnits == "C"
        {
            checkdCelsiusAction = .on
            checkedFahrenheitAction = .off
        }
        
        else
        {
            checkdCelsiusAction = .off
            checkedFahrenheitAction = .on
        }
        
        let edit = UIAction(title: "목록 편집", image: UIImage(systemName: "pencil"), state: .off, handler: { _ in print("목록 편집") })
        let C = UIAction(title: "섭씨", image: UIImage(named: "°C"), state: checkdCelsiusAction, handler: { _ in
            self.temperatureUnits = "C"
            self.updateMenu()
        })
        let F = UIAction(title: "화씨", image: UIImage(named: "°F"), state: checkedFahrenheitAction, handler: { _ in
            self.temperatureUnits = "F"
            self.updateMenu()
        })
        
        let line = UIMenu(title: "", options: .displayInline, children: [C, F])
        let menu = UIMenu(title: "", children: [edit, line])
        settingButton.menu = menu
    
        weatherListTableView.reloadData()
    }
}

// MARK: - SearchBar extension
extension WeatherListViewController: UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        UIView.animate(withDuration: 0.2)
        {
            self.locationSearchBar.isHidden = true
            self.view.frame.origin.y = -130
        }
        
        let VC = SearchViewController()
        
        VC.modalPresentationStyle = .automatic
        VC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        present(VC, animated: true, completion: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        self.view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
}

// MARK: - TableView extension
extension WeatherListViewController: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return locationData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherListTableViewCell", for: indexPath) as! WeatherListTableViewCell
    
        cell.backgroundColor = .clear
        cell.backgroundImage.image = UIImage(named: "weatherListCellBackground")
        cell.locationLabel.text = indexPath.row == 0 ?  "나의 위치" : weatherDataList[indexPath.row].cityName
        cell.timeOrCityLabel.text = indexPath.row == 0 ? weatherDataList[indexPath.row].cityName : weatherDataList[indexPath.row].time
        cell.weatherLabel.text = weatherDataList[indexPath.row].weatherDescription
        
        let temperature = temperatureUnits == "C" ? weatherDataList[indexPath.row].temperature : (weatherDataList[indexPath.row].temperature * 1.8) + 32
        cell.temperatureLabel.text = "\(temperature)°\(temperatureUnits)"
                
        let highTemperature = temperatureUnits == "C" ? weatherDataList[indexPath.row].tempMax : (weatherDataList[indexPath.row].tempMax * 1.8) + 32
        cell.highTemperatureLabel.text = "최고\(highTemperature)°\(temperatureUnits)"
                
        let lowTemperature = temperatureUnits == "C" ? weatherDataList[indexPath.row].tempMin : (weatherDataList[indexPath.row].tempMin * 1.8) + 32
        cell.lowTemperatureLabel.text = "최저 \(lowTemperature)°\(temperatureUnits)"

        // weatherDataList 어떤 값이 있고 몇개가 있는지
        // 현재indexPath.row 불리고 있는 값이 몇인지
        
        print("\(indexPath.row) cell \(weatherDataList[indexPath.row])")
        print(locationData.count)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let VC = MainViewController()
//        VC.**** = locationData[indexPath.row] // 위도 경도 변수 지정
        VC.modalPresentationStyle = .fullScreen
        present(VC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 120
    }
}
