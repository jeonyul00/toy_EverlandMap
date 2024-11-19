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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        menuContainerView.layer.cornerRadius = 20
        menuContainerView.clipsToBounds = true
        let center = CLLocationCoordinate2D(latitude: 37.294259, longitude: 127.2039509)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: false)
    }
    
}


extension ViewController: MKMapViewDelegate {
    
}
