//
//  CollectionVC.swift
//  VirtualTourist 0.0
//
//  Created by admin on 11/11/16.
//  Copyright © 2016 JPDaines. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "Cell"

class CollectionVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    static let sharedInstance = CollectionVC()

    var pin: Pin!
    var mapRegion: MKCoordinateRegion!

    
    

    @IBOutlet weak var photosLabel: UILabel!
    @IBOutlet weak var collectionMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var toolBarButton: UIBarButtonItem!

    var pinCount = 1
    var blockOperations: [BlockOperation] = []
    var selectedCells: [NSIndexPath] = [] {
        didSet {
            toolBarButton.title = selectedCells.isEmpty ? "Load New Collection" : "Delete Selected Photos"
        }
    }
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var pinContext: NSManagedObjectContext {
        return delegate.stack.context
    }

    
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo>? = {
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.pinContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        return fetchedResultsController
}()


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionMapView.isUserInteractionEnabled = false
        photosLabel.isHidden = true

        
        self.automaticallyAdjustsScrollViewInsets = false
        fetchedResultsController?.delegate = self
        collectionView.allowsMultipleSelection = true
        
        
        if let array = self.readSavedMapPosition() {
            print("Loading saved region")
            let mkcr = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: array[0], longitude: array[1]), span: MKCoordinateSpan(latitudeDelta: array[2], longitudeDelta: array[3]))
            self.collectionMapView.setRegion(mkcr, animated: true)
        }

    
        

        func fetchPins() -> [Pin] {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Pin.fetchRequest()
            fetchRequest.entity = NSEntityDescription.entity(forEntityName: "Pin", in: pinContext)
            
            do {
                let results = try pinContext.fetch(fetchRequest)
                return results as! [Pin]
            } catch {
                return [Pin]()
            }
        }
        
        let pins = fetchPins()
         for pin in pins {
            collectionMapView.addAnnotation(pin)
        }
        
        
        
        do {
            try self.fetchedResultsController?.performFetch()
            self.collectionView.reloadData()
        } catch {
            print("error fetching images!")
        }
        
        
        
    if fetchedResultsController?.fetchedObjects?.count == 0 {
        
        FlickrClient.sharedInstance.searchByLatLon(){ [weak self] (success) -> Void in
            if success {
                do {
                    try self?.fetchedResultsController?.performFetch()
                            self?.collectionView.reloadData()
                } catch {
                    print("error fetching images!")
                }
            }
        }
    }
}
    
    
    private func loadNewPhotos(){
        for photo in (fetchedResultsController?.fetchedObjects )! {
            pinContext.delete(photo)
        }
        do{
            try delegate.stack.saveContext()
            collectionView.reloadData()
            FlickrClient.sharedInstance.searchByLatLon(){ [weak self] (success) -> Void in
                if success {
                    do {
                        try self?.fetchedResultsController?.performFetch()
                        self?.collectionView.reloadData()

                    } catch {
                        print("error fetching images!")
                    }
                }
            }
        }catch{
            print("There was an error while saving context")
        }

    }
    
    
    
    
    private func readSavedMapPosition() -> [Double]? {
        let defaults = UserDefaults.standard
        let array = defaults.object(forKey: "savedMKCRArray") as? [Double]
        print("map position read: \(array)")
        return array
    }
    
    private func pinFinishedDownload() {
        if let objects = self.fetchedResultsController?.fetchedObjects {
            if objects.count == 0 {
                self.collectionView.isHidden = true
            }
        }
    }
    
    
    private func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        for indexPath in selectedCells {
            photosToDelete.append(fetchedResultsController?.object(at: indexPath as IndexPath) as Photo!)
        }
        for photo in photosToDelete {
            pinContext.delete(photo)
        }
        do{
            try delegate.stack.saveContext()
            collectionView.reloadData()
        }catch{
            print("There was an error while saving context")
        }
        
        selectedCells = [NSIndexPath]()
    }
    
    @IBAction func toolBarWasPressed(_ sender: AnyObject) {
        
        if selectedCells.count != 0 {
            deleteSelectedPhotos()
        } else {
            loadNewPhotos()
            self.pinCount = self.pinCount + 1
            print(self.pinCount)
            if pinCount > pin.totalPages{
            collectionView.isHidden = true
            photosLabel.isHidden = false
            }
        }
    }
    

    
    // MARK: UICollectionViewDataSource
    
   func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let sections = fetchedResultsController?.sections {
        let currentSection = sections[section]
        return currentSection.numberOfObjects
    }
    return 0
}
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "reuseIdentifier", for: indexPath) as! CollectionViewCell
   
        configureCell(cell: cell, atIndexPath: indexPath as NSIndexPath)
        
        let photo = (fetchedResultsController?.object(at: indexPath))! as Photo
        
        if photo.filePath != nil {
            DispatchQueue.main.async {
                cell.imageView.image = photo.image
                cell.activityIndicator.isHidden = true
            }
        }else{
            DispatchQueue.main.async {
                cell.imageView.image = #imageLiteral(resourceName: "Image")
                cell.activityIndicator.isHidden = false
                cell.activityIndicator.startAnimating()
            }
        }
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCells.append(indexPath as NSIndexPath)
        let selectedCell = collectionView.cellForItem(at: indexPath as IndexPath)
        selectedCell?.layer.borderWidth = 5.0
        selectedCell?.layer.borderColor = UIColor.gray.cgColor
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let index = selectedCells.index(of: indexPath as NSIndexPath) {
            selectedCells.remove(at: index)
            let deselectedCell = collectionView.cellForItem(at: indexPath as IndexPath)
            deselectedCell?.layer.borderWidth = 0.0
        }
    }
    
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            // use the "weak" to avoid a stron reference cycle 
            
        case .insert:
            blockOperations.append(
                BlockOperation(){ [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                }
            )
        case .update:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                }
            )
        case .delete:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                }
            )
        case .move:
            blockOperations.append(
                BlockOperation() { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }

                }
            )
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        let batchUpdatesToPerform = {() -> Void in
            for operation in self.blockOperations {
                operation.start()
               // self.toolBarButton.isEnabled = false
            }
        }
        self.collectionView!.performBatchUpdates(batchUpdatesToPerform) { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        }
    }
}
