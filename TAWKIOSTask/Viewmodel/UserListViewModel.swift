//
//  UserListViewModel.swift
//  TAWKIOSTask
//
//  Created by Pratik on 07/02/22.
//

import Foundation
import CoreData
import UIKit

class UserListViewModel {
    
    // MARK: - Variables -
    var arrUserList = [UserListModel]()
    var arrFilteredData = [UserListModel]()
    var recordCountSize = 15
    
    func removeDuplicateRecords(posts: [UserListModel]) -> [UserListModel] {
        var fetchPosts = [UserListModel]()
        for post in posts {
            if !fetchPosts.contains(where: {$0.login == post.login }) {
                fetchPosts.append(post)
            }
        }
        return fetchPosts
    }
    
    func getUserListFromAPI(page:Int,completionHandler: @escaping ((_ response : Bool) -> Void)) {
        showLoader()
        let param : String = "\(page)&per_page=\(recordCountSize)"
        Network.shared.request(router: .getUserList(body: param)) { [self] (result: Result<[UserListModel], ErrorType>) in
            hideLoader()
            guard let res = try? result.get() else {
                return
            }
            if res.count != 0 {
                if page == 1 {
                    self.arrUserList.removeAll()
                    arrUserList = res
                    arrFilteredData = res
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.storeOfflineData()
                        completionHandler(true)
                    }
                }else{
                    if res.count != 0 {
                        for i in res{
                            self.arrUserList.append(i)
                            self.arrFilteredData.append(i)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.storeOfflineData()
                            completionHandler(true)
                        }
                    }else{
                        showMessage(text: Messages.somethingwentwrong)
                        completionHandler(true)
                    }
                }
                
            } else {
                showMessage(text: Messages.somethingwentwrong)
                completionHandler(false)
            }
        }
    }
    
    func fetchDataOffline() -> Bool {
        let arrList = self.loadUserList()
        for i in arrList {
            var obj = UserListModel()
            obj.login = i.login
            obj.type = i.type
            obj.node_id = i.node_id
            obj.avatar_url = nil
            obj.imgData = i.avatar_url
            self.arrUserList.append(obj)
        }
        let uniqueArray = self.removeDuplicateRecords(posts: self.arrUserList)
        self.arrUserList = uniqueArray
        self.arrFilteredData = uniqueArray
        return true
    }
}

extension UserListViewModel {
    
    // MARK: - Store offline data -
    func storeOfflineData(){
        if arrFilteredData.count > 0 {
            for (i, element) in arrFilteredData.enumerated() {
                fetchImage(url: element.avatar_url ?? "", index: i)
            }
        }
    }
    
    // MARK: - Save data to coredata database -
    func saveOfflineToCoreData(data:Data, login:String, type: String,node: String) {
        let managedContext = objAppDelegate.persistentContainer.viewContext
        let user = Userlist(context: managedContext)
        user.login = login
        user.type  = type
        user.avatar_url = data
        user.node_id = node
        objAppDelegate.saveContext()
    }
    
    // MARK: - Delete user entity table -
    func deleteEntity() {
        let managedObjectContext = objAppDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Userlist")
        fetchRequest.includesPropertyValues = false
        do {
            let items = try managedObjectContext.fetch(fetchRequest) as! [NSManagedObject]
            for item in items {
                managedObjectContext.delete(item)
            }
            try managedObjectContext.save()
        } catch {
            fatalError("Data not cleared")
        }
    }
    
    // MARK: - Load offline data from coredata -
    func loadUserList() -> [Userlist] {
        let context = objAppDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Userlist> = Userlist.fetchRequest()
        do {
            let userlist = try context.fetch(request)
            return userlist
        }  catch {
            fatalError("Error")
        }
    }
    
    // MARK: -  Store image with data 
    func storeImageWith(fileName: String, image: UIImage, login: String, type: String, node: String) {
        if let data = image.jpegData(compressionQuality: 0.5) {
            // Using our extension here
            let documentsURL = FileManager.getDocumentsDirectory()
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL, options: .atomic)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.saveOfflineToCoreData(data: data, login: login, type: type, node: node)
                }
            }
            catch {
                print("Unable to Write Data (\(error.localizedDescription))")
            }
        }
    }
}

extension UserListViewModel {
    
    // MARK: - Fetch image from url
    func fetchImage(url: String,index:Int) {
        let fileName = "picked\(index).jpg"
        let login = arrFilteredData[index].login ?? ""
        let type = arrFilteredData[index].type ?? ""
        let node_id = arrFilteredData[index].node_id ?? ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageURL = URL(string: url) {
                if let imageData = try? Data(contentsOf: imageURL) {
                    if let image = UIImage(data: imageData) {
                        self.storeImageWith(fileName: fileName, image: image,login: login,type: type, node: node_id)
                    }
                }
            }
        }
    }
}
