import RIBs

// MARK: - Navigation Protocols

protocol PhotoUploadRouting: ViewableRouting {
    // Photo upload routing methods if needed
}

final class PhotoUploadRouter: ViewableRouter<PhotoUploadInteractable, PhotoUploadViewControllable>, PhotoUploadRouting {
    
    override init(interactor: PhotoUploadInteractable, viewController: PhotoUploadViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    // MARK: - PhotoUploadRouting
    
    // Add any routing methods specific to PhotoUpload if needed
}

// MARK: - ViewControllable Protocol

protocol PhotoUploadViewControllable: ViewControllable {
    // Add any view controller specific methods if needed
}