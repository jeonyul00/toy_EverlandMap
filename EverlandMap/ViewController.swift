//
//  ViewController.swift
//  EverlandMap
//
//  Created by 전율 on 11/19/24.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var menuContainerView: UIView!
    @IBOutlet weak var facilityButton: UIButton!
    var geoJsonObjects = [MKGeoJSONObject]()
    lazy var locationManager: CLLocationManager = { [weak self] in
        let m = CLLocationManager()
        m.delegate = self
        return m
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = locationManager
        mapView.delegate = self
        menuContainerView.layer.cornerRadius = 20
        menuContainerView.clipsToBounds = true
        let center = CLLocationCoordinate2D(latitude: 37.294259, longitude: 127.2039509)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: false)
        
        Task {
            geoJsonObjects = try await fetchMap()
            
        }
        let list = [Category.aed, .restroom, .firstaid, .locker, .atm, .ticketing, .babyfedding, .missingchild, .charge, .publicphone, .smoking]
        
        var actions = [UIAction]()
        
        for category in list {
            let action = UIAction(title: category.rawValue.capitalized,image: UIImage(named: category.rawValue)) { _ in
                self.show(category: category)
            }
            actions.append(action)
        }
        let menu = UIMenu(children: actions)
        facilityButton.menu = menu
        facilityButton.showsMenuAsPrimaryAction = true
        
    }
    
    @IBAction func showRoute(_ sender: Any) {
        let start = mapView.userLocation.coordinate
        let dest = CLLocationCoordinate2D(latitude: 37.294259, longitude: 127.2030509)
        let startPlacemark = MKPlacemark(coordinate: start)
        let destPlacemark = MKPlacemark(coordinate: dest)
        let startMapItem = MKMapItem(placemark: startPlacemark)
        let destMapItem = MKMapItem(placemark: destPlacemark)
        
        // 경로 계산
        let request = MKDirections.Request()
        request.source = startMapItem
        request.destination = destMapItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let response else {
                if let error {
                    print(error)
                }
                return
            }
            let route = response.routes[0]
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let region = MKCoordinateRegion(route.polyline.boundingMapRect)
            self.mapView.setRegion(region, animated: true)
        }

        
    }
    
    @IBAction func showAttractions(_ sender: Any) {
        show(category: .attraction)
    }
    
    @IBAction func showPerformances(_ sender: Any) {
        show(category: .performance)
    }
    
    @IBAction func showAmentity(_ sender: Any) {
        show(category: .amenity)
    }
    
    @IBAction func showGiftshop(_ sender: Any) {
        show(category: .giftshop)
    }
    
    @IBAction func showRestaurant(_ sender: Any) {
        show(category: .restaurant)
    }
    
    func show(category:Category) {
        mapView.removeAnnotations(mapView.annotations)
        for obj in geoJsonObjects {
            guard let feature = obj as? MKGeoJSONFeature else { continue }
            let jsonDecoder = JSONDecoder()
            guard let pdata = feature.properties, let properties = try? jsonDecoder.decode(Property.self, from: pdata) else { continue }
            guard let objCategory = Category(rawValue: properties.category) else { continue }
            if let pointAnnotation = feature.geometry.first as? MKPointAnnotation {
                if category == objCategory {
                    let annotation = EverlandAnnotation(coordinate: pointAnnotation.coordinate, properties: properties)
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    func fetchMap() async throws -> [MKGeoJSONObject] {
        guard let url = URL(string: "https://kxapi.azurewebsites.net/geojson?apiKey=Vp3lkFGT4CyPC5t8vF8D") else { throw "invalid url" }
        let (data,_) = try await URLSession.shared.data(from: url)
        let decoder = MKGeoJSONDecoder()
        let results = try decoder.decode(data)
        return results
    }
    
    @IBAction func addOverlay(_ sender: Any) {
        mapView.removeOverlays(mapView.overlays)
        
        for obj in geoJsonObjects {
            guard let feature = obj as? MKGeoJSONFeature else { continue }
            let jsonDecoder = JSONDecoder()
            guard let pdata = feature.properties, let properties = try? jsonDecoder.decode(Property.self, from: pdata) else { continue }
            guard let objCategory = Category(rawValue: properties.category), objCategory == .section else { continue }
            if let section = feature.geometry.first as? MKPolygon {
                section.title = properties.name
                mapView.addOverlay(section)
            }
        }
        
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        if let everlandAnnotation = annotation as? EverlandAnnotation {
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as! MKMarkerAnnotationView
            marker.glyphImage = everlandAnnotation.image
            marker.animatesWhenAdded = true
            marker.tintColor = nil
            marker.glyphTintColor = nil
            if everlandAnnotation.category == .restroom {
                marker.markerTintColor = .black
                if everlandAnnotation.properties.accessibleToDisabled ?? false {
                    marker.glyphTintColor = .systemGreen
                } else {
                    marker.glyphTintColor = .white
                }
            }
            return marker
        }
        return nil
    }
    
    // 렌더러 생성
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case is MKPolyline:
            let r = MKPolylineRenderer(overlay: overlay)
            r.strokeColor = .systemRed
            r.lineWidth = 1
            return r
        case is MKCircle:
            let r = MKCircleRenderer(overlay: overlay)
            r.strokeColor = .systemBlue
            r.lineWidth = 1
            return r
        case is MKPolygon:
            let r = MKPolygonRenderer(overlay: overlay)
            switch overlay.title {
            case "유러피안 어드벤처":
                r.fillColor = .systemGreen
            case "매직랜드":
                r.fillColor = .systemRed
            case "아메리칸 어드벤처":
                r.fillColor = .systemBlue
            case "글로벌 페어":
                r.fillColor = .systemPurple
            case "주토피아":
                r.fillColor = .systemOrange
            default:
                r.fillColor = .systemYellow
            }
            r.alpha = 0.2
            return r
        default:
            return MKOverlayRenderer()
        }
    }
}

extension ViewController:CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print(error)
    }
}

extension String: Error {
    
}

