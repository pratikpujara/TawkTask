//
//  UserViewcontroller.swift
//  TAWKIOSTask
//
//  Created by Pratik on 04/02/22.
//

import Foundation
import CoreData
import UIKit

class UserViewcontroller: UIViewController {
    
    //MARK: - Outlets & Var declaration -
    @IBOutlet var tableViewUserList : UITableView!
    @IBOutlet var searchBar : UISearchBar!
    @IBOutlet var searchBarView : UIView!
    
    var currentPage : Int = 0
    var isListLoad : Bool = false
    var isSearch = false
    let objUserlistViewModel = UserListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBarView.dropShadow()
        tableViewUserList.estimatedRowHeight = 100
        tableViewUserList.rowHeight = UITableView.automaticDimension
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.setOfflineData),
            name: NSNotification.Name(rawValue: "InternetConnectionError"),
            object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.isHidden = true
        objUserlistViewModel.arrUserList.removeAll()
        callUserListAPI(page: currentPage)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Offline Data
    @objc func setOfflineData() {
        hideLoader()
        showToastMessage(message: Messages.noInternetConnection)
        if objUserlistViewModel.fetchDataOffline() {
            DispatchQueue.main.async {
                self.tableViewUserList.reloadData()
            }
        }
    }
    
    //MARK: - User list api call -
    func callUserListAPI(page:Int) {
        if isSearch {
            return
        }
        objUserlistViewModel.getUserListFromAPI(page: page) { response in
            if self.isListLoad == true {
                self.isListLoad = false
            }
            DispatchQueue.main.async {
                self.tableViewUserList.reloadData()
            }
        }
    }
    
    func getListFromAPI(_ pageNumber: Int){
        self.isListLoad = false
        self.tableViewUserList.reloadData()
    }
    
    // MARK: - Load More Pagination
    func loadMoreList(page:Int){
        if isListLoad == true {
            callUserListAPI(page: page)
        }
    }
}

//MARK:  - UISearchBar Methods -
extension UserViewcontroller : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.lowercased().count == 0 {
            self.objUserlistViewModel.arrUserList.removeAll()
            isSearch = false
            self.objUserlistViewModel.arrUserList = self.objUserlistViewModel.arrFilteredData
            tableViewUserList.reloadData()
            searchBar.resignFirstResponder()
            return
        }
        self.objUserlistViewModel.arrUserList.removeAll()
        isSearch = true
        
        let userData = self.objUserlistViewModel.removeDuplicateRecords(posts: self.objUserlistViewModel.arrFilteredData)
        self.objUserlistViewModel.arrUserList.removeAll()
        self.objUserlistViewModel.arrFilteredData = userData
        self.objUserlistViewModel.arrUserList = self.objUserlistViewModel.arrFilteredData.filter({ (user) -> Bool in
            if user.login?.lowercased().range(of:searchText.lowercased()) != nil {
                return true
            }
            return false
        })
        tableViewUserList.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
}


//MARK:  - UITableView Methods -
extension UserViewcontroller : UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.objUserlistViewModel.arrUserList.count == 0{
            return Utilities.showNoDataFoundLabel(tableview: self.tableViewUserList, strMsg: "No users found")
        }else{
            tableViewUserList.backgroundView = nil
            return self.objUserlistViewModel.arrUserList.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserListTableViewCell", for: indexPath) as! UserListTableViewCell
        cell.lblName.text = ""
        cell.lblDetails.text = ""
        cell.imgUser.image = nil
        
        if self.objUserlistViewModel.arrUserList.count > 0{
            let objUser = self.objUserlistViewModel.arrUserList[indexPath.row]
            cell.configureCell(objUser: objUser,index: indexPath.row)
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if Reachability.isConnectedToNetwork(){
            if isListLoad == false {
                if !(indexPath.row + 1 < self.objUserlistViewModel.arrUserList.count) {
                    self.isListLoad = true
                    let lastId = self.objUserlistViewModel.arrUserList.last?.id
                    self.loadMoreList(page: lastId ?? 0)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let obj = self.objUserlistViewModel.arrUserList[indexPath.row]
        let profileVC = Utilities.viewController(name: ViewController.ProfileViewcontroller, onStoryBoared: "Main") as! ProfileViewcontroller
        profileVC.strName = obj.login ?? ""
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
}

