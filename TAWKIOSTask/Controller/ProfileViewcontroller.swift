//
//  ProfileViewcontroller.swift
//  TAWKIOSTask
//
//  Created by Pratik on 04/02/22.
//

import Foundation
import CoreData
import UIKit

class ProfileViewcontroller: UIViewController {
    
    // MARK: -  IBOutlets 
    @IBOutlet var imgUserProfilePicture : UIImageView!
    @IBOutlet var labelFollowers : UILabel!
    @IBOutlet var labelFollowing : UILabel!
    @IBOutlet var labelHeaderTitle : UILabel!
    @IBOutlet var labelName : UILabel!
    @IBOutlet var labelCompany : UILabel!
    @IBOutlet var labelBlog : UILabel!
    @IBOutlet var txtNotes : UITextView!
    
    // MARK: -  Variables 
    var strName = ""
    var objUserProfile : UserProfileModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelFollowing.text = ""
        labelFollowers.text = ""
        labelBlog.text = ""
        labelCompany.text = ""
        labelName.text = ""
        txtNotes.text = ""
        
        labelFollowers.layer.borderWidth = 1.0
        labelFollowers.layer.borderColor = UIColor.orange.cgColor
        labelFollowers.layer.cornerRadius = 5
        labelFollowers.layer.masksToBounds = true
        
        labelFollowing.layer.borderWidth = 1.0
        labelFollowing.layer.borderColor = UIColor.orange.cgColor
        labelFollowing.layer.cornerRadius = 5
        labelFollowing.layer.masksToBounds = true
        
        labelHeaderTitle.text = strName
        
        txtNotes.layer.borderWidth = 1.0
        txtNotes.layer.borderColor = UIColor.orange.cgColor
        txtNotes.layer.cornerRadius = 5
        txtNotes.layer.masksToBounds = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.loadOfflineData),
            name: NSNotification.Name(rawValue: "InternetConnectionError"),
            object: nil)
        
        
        if Reachability.isConnectedToNetwork(){
            userProfileAPI()
        }else{
            loadOfflineData()
        }
    }
    
    //MARK: - User profile list api call -
    func userProfileAPI() {
        showLoader()
        let param : String = "\(strName)"
        Network.shared.request(router: .getUserProfile(body: param)) { (result: Result<UserProfileModel, ErrorType>) in
            hideLoader()
            guard let res = try? result.get() else { return }
            self.objUserProfile = res
            self.setUserProfileData()
        }
    }
    
    // MARK: - Load offline data with predicate -
    @objc func loadOfflineData() {
        hideLoader()
        showToastMessage(message: Messages.noInternetConnection)
        var name = ""
        var blog = ""
        var login = ""
        var company = ""
        var img = Data()
        var note = ""
        var followers = ""
        var following = ""
        
        var predicate: NSPredicate = NSPredicate()
        predicate = NSPredicate(format: "login contains[c] '\(strName)'")
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Profile")
        fetchRequest.predicate = predicate
        do {
            let result = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
            for data in result {
                if strName == data.value(forKey: "login") as! String {
                    name = data.value(forKey: "name") as! String
                    login = data.value(forKey: "login") as! String
                    note = data.value(forKey: "note") as! String
                    blog = data.value(forKey: "blog") as! String
                    company = data.value(forKey: "company") as! String
                    following = data.value(forKey: "following") as! String
                    followers = data.value(forKey: "followers") as! String
                    img =  data.value(forKey: "avatar_url") as! Data
                    break
                }
            }
        } catch let error as NSError {
            print("Not fetch. \(error)")
        }
        
        if following == ""{
            labelFollowing.text = ""
        }else{
            labelFollowing.text = "Followings: \(following)"
        }
        
        labelName.text = name
        labelBlog.text = blog
        labelCompany.text = company
        txtNotes.text = note
        
        if followers == ""{
            labelFollowers.text = ""
        }else{
            labelFollowers.text = "Followers: \(followers)"
        }
        
        DispatchQueue.main.async {
            self.imgUserProfilePicture.image = UIImage(data: (img) as Data)
        }
    }
    
    // MARK: - Fetch profile from coredata -
    private func loadProfileList() -> [Profile] {
        let context = objAppDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Profile> = Profile.fetchRequest()
        do {
            let userlist = try context.fetch(request)
            return userlist
        }  catch {
            fatalError("Error")
        }
        return []
    }
    
    // MARK: - Store offline profile data -
    func saveOfflineData(data:Data){
        
        let managedContext = objAppDelegate.persistentContainer.viewContext
        let user = Profile(context: managedContext)
        user.login = objUserProfile?.login ?? ""
        user.blog = objUserProfile?.blog ?? ""
        user.company = objUserProfile?.company ?? ""
        user.name = objUserProfile?.name ?? ""
        user.followers = "\(objUserProfile?.followers ?? 0)"
        user.following = "\(objUserProfile?.following ?? 0)"
        user.type  = objUserProfile?.type ?? ""
        
        if let imageData = imgUserProfilePicture.image?.pngData() {
            user.avatar_url = imageData
        }
        
        user.note = txtNotes.text
        objAppDelegate.saveContext()
    }
    
    
    // MARK: - set data -
    func setUserProfileData() {
        labelName.text = objUserProfile?.name
        labelBlog.text = objUserProfile?.blog
        labelCompany.text = objUserProfile?.company
        
        if objUserProfile?.following != 0{
            labelFollowing.text = "Followings: \(objUserProfile?.following ?? 0)"
        }else{
            labelFollowing.text = ""
        }
        
        if objUserProfile?.followers != 0{
            labelFollowers.text = "Followers: \(objUserProfile?.followers ?? 0)"
        }else{
            labelFollowers.text = ""
        }
        downloadImage(strURL: objUserProfile?.avatar_url ?? "")
    }
    
    // MARK: - save click -
    @IBAction func btnSaveClicked(_ sender:UIButton) {
        updateUserProfileData()
    }
    
    // MARK: - download asynchornous image -
    func downloadImage(strURL:String) {
        if let url = URL(string: strURL) {
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    self.imgUserProfilePicture.image = UIImage(data: data)
                    self.saveOfflineData(data:data)
                }
            }
            task.resume()
        }else{
            self.imgUserProfilePicture.image = UIImage(named: "userProfile")
        }
    }
    
    // MARK: - back click -
    @IBAction func btnBackClicked(_ sender:UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK: - update data with textview note data -
    func updateUserProfileData() {
        var managedContext:NSManagedObjectContext!
        managedContext = objAppDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Profile", in: managedContext)
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entity
        let predicate = NSPredicate(format: "(login = %@)", strName)
        request.predicate = predicate
        do {
            let results =
            try managedContext.fetch(request)
            let objectUpdate = results[0] as! NSManagedObject
            objectUpdate.setValue(txtNotes.text!, forKey: "note")
            do {
                try managedContext.save()
                
                loadOfflineData()
            }catch let error as NSError {
                showToastMessage(message: error.description)
            }
        }
        catch let error as NSError {
            showToastMessage(message: error.description)
        }
    }
}
