//
//  ViewController.swift
//  VirtualTourist 1.0
//
//  Created by admin on 11/16/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var mapPin:Pin!
    var mapRegion: MKCoordinateRegion!
    private var collectionViewRegion: MKCoordinateRegion!
    
    var pinContext: NSManagedObjectContext {
        return delegate.stack.context
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        if let array = self.readSavedMapPosition() {
            
        let mkcr = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: array[0], longitude: array[1]), span: MKCoordinateSpan(latitudeDelta: array[2], longitudeDelta: array[3]))
            self.mapView.setRegion(mkcr, animated: true)
        }
        
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.dropPin(_:)))
        longPress.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPress)
        
        mapView.delegate = self
        
        
        let pins = fetchPins()
        for pin in pins {
                mapView.addAnnotation(pin)
        }
    }
    
    
    private func fetchPins() -> [Pin] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: "Pin", in: pinContext)
        
        do {
            let results = try pinContext.fetch(fetchRequest)
            return results as! [Pin]
        } catch {
            return [Pin]()
        }

    }

    
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: false)
        
        self.mapView.frame.origin.y -= self.deleteLabel.frame.height * (editing ? 1 : -1)
    }
    
    func deletePin(pin: Pin) {
        mapView.removeAnnotation(pin)
        pinContext.delete(pin)
        do{
            try delegate.stack.saveContext()
        }catch{
            print("There was an error while saving context")
        }
    }
    
    
    private func readSavedMapPosition() -> [Double]? {
        let defaults = UserDefaults.standard
        let array = defaults.object(forKey: "savedMKCRArray") as? [Double]
        print("map position read: \(String(describing: array))")
        return array
    }

    
    private func saveMapPosition(mkcr: MKCoordinateRegion) {
        let defaults = UserDefaults.standard
        let array = [mkcr.center.latitude, mkcr.center.longitude, mkcr.span.latitudeDelta, mkcr.span.longitudeDelta]
        print("map position saved: \(array)")
        defaults.set(array, forKey: "savedMKCRArray")
    }
    
    
     func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Map view region changed, saving new position")
        let currentRegion = mapView.region
        self.saveMapPosition(mkcr: currentRegion)
    }
    
    
    private func setSpans(pin: Pin){
        
        let latDelta:CLLocationDegrees = 50.0
        let longDelta:CLLocationDegrees = 50.0
        let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        
        
        let collectionLatDelta = 15.0
        let collectionLongDelta = 15.0
        let collectionSpan:MKCoordinateSpan = MKCoordinateSpanMake(collectionLatDelta, collectionLongDelta)
        
        
        let pinRegion:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        let collectionRegion:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, collectionSpan)
        
        collectionViewRegion = collectionRegion
        mapRegion = pinRegion
    
    }
    
    
    internal func dropPin(_ gestureRecognizer: UIGestureRecognizer) {
        
        let tapPoint: CGPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: mapView)
        
        if UIGestureRecognizerState.began == gestureRecognizer.state {
            let pin = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: pinContext)
            mapView.addAnnotation(pin)
            
            
           setSpans(pin: pin)
            

            do{
                try delegate.stack.saveContext()
            }catch{
                print("There was an error while saving")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        let pin = view.annotation as! Pin
        mapPin = pin
        FlickrClient.sharedInstance.pin = mapPin
        
        if isEditing == true {
        self.mapView.removeAnnotation(mapPin)
            deletePin(pin: mapPin)
        } else {
            performSegue(withIdentifier: "pinSegueIdentifier", sender: self)
            }            
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pinSegueIdentifier" {
            
            if mapRegion != nil{
            saveMapPosition(mkcr: mapRegion)
            } 
            mapView.deselectAnnotation(mapPin, animated: false)
            let controller = segue.destination as! CollectionVC
            controller.pin = mapPin
            controller.mapRegion = collectionViewRegion
        }
    }
    

    
}




