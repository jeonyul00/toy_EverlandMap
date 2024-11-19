//
//  ViewController.swift
//  EverlandMap
//
//  Created by 전율 on 11/19/24.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var menuContainerView: UIView!
    var geoJsonObjects = [MKGeoJSONObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        menuContainerView.layer.cornerRadius = 20
        menuContainerView.clipsToBounds = true
        let center = CLLocationCoordinate2D(latitude: 37.294259, longitude: 127.2039509)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: false)
        
        Task {
            geoJsonObjects = try await fetchMap()
            
            for obj in geoJsonObjects {
                guard let feature = obj as? MKGeoJSONFeature else { continue }
                let jsonDecoder = JSONDecoder()
                guard let pdata = feature.properties, let properties = try? jsonDecoder.decode(Property.self, from: pdata) else { continue }
                guard let category = Category(rawValue: properties.category) else { continue }
                if let pointAnnotation = feature.geometry.first as? MKPointAnnotation {
                    if category == .attraction {
                        let annotation = EverlandAnnotation(coordinate: pointAnnotation.coordinate, properties: properties)
                        mapView.addAnnotation(annotation)
                        
                    }
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
    
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        if let everlandAnnotation = annotation as? EverlandAnnotation {
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as! MKMarkerAnnotationView
            marker.glyphImage = everlandAnnotation.image
            return marker
        }
        return nil
    }
}

extension String: Error {
    
}

