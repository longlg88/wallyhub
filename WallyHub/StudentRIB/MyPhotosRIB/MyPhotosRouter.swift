import RIBs
import UIKit

// MARK: - Navigation Protocols

protocol MyPhotosRouting: ViewableRouting {
    func presentCamera()
    func presentGallery()
    func dismissImagePicker()
    
    // 📸 저장된 이미지 가져오기
    func getPendingImageForUpload() -> UIImage?
}

final class MyPhotosRouter: ViewableRouter<MyPhotosInteractable, MyPhotosViewControllable>, MyPhotosRouting {
    
    override init(interactor: MyPhotosInteractable, viewController: MyPhotosViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    // MARK: - MyPhotosRouting
    
    func presentCamera() {
        viewController.presentCamera()
    }
    
    func presentGallery() {
        viewController.presentGallery()
    }
    
    func dismissImagePicker() {
        viewController.dismissImagePicker()
    }
    
    // 📸 저장된 이미지 가져오기
    func getPendingImageForUpload() -> UIImage? {
        if let myPhotosInteractor = interactor as? MyPhotosInteractor {
            return myPhotosInteractor.getPendingImageForUpload()
        }
        return nil
    }
}

// MARK: - ViewControllable Protocol

protocol MyPhotosViewControllable: ViewControllable {
    func presentCamera()
    func presentGallery() 
    func dismissImagePicker()
}