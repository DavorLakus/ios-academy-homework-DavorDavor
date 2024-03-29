//
//  DetailsViewController.swift
//  ShowsTV
//
//  Created by Infinum  on 28.07.2021..
//

import Foundation
import SVProgressHUD
import Alamofire
import UIKit


class DetailsViewController : UIViewController {
    
    // MARK: properties
    var user:User?
    var authInfo:AuthInfo?
    var show:Show?
    private var reviews:[Review]?
    
    // MARK: outlets
    
    @IBOutlet private weak var detailsTableView: UITableView!
    @IBOutlet private weak var detailsTitleLabel: UILabel!
    @IBOutlet private weak var detailsDescriptionLabel: UITableView!
    @IBOutlet private weak var detailsRating: UITableView!
    @IBOutlet private weak var showTitleLabel: UILabel!

    // MARK: functions, API fetching
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showTitleLabel.text = show?.title
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 34, weight: .light)]
        self.navigationController?.navigationBar.titleTextAttributes = attributes
        
        setupTableView()
        guard let authInfo = authInfo else {return}
        guard let show = show else {return}
        let show_id = show.id
     AF .request(
        "https://tv-shows.infinum.academy/shows/\(show_id)/reviews",
             method: .get,
             parameters: ["page": "1", "items": "100"], // pagination arguments
             headers: HTTPHeaders(authInfo.headers)
         )
         .validate()
         .responseDecodable(of: ReviewsResponse.self) { [weak self] dataResponse in
            switch dataResponse.result {
            case .success(let reviewsResponse):
                guard let self = self else {return}
                self.setReviews(reviews: reviewsResponse.reviews)
            case .failure(let error):
                print("Error parsing data: \(error)")
            }
         }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // hide navigation bar
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    
    func setReviews(reviews:[Review]){
        self.reviews = reviews
        detailsTableView.reloadData()
    }
    
    func setUserResponseAndAuthInfoAndShow(user:User, authInfo:AuthInfo, show:Show) {
        self.user = user
        self.authInfo = authInfo
        self.show = show
    }
    
    @IBAction private func writeAReviewOnClick(_ sender: UIButton) {
        guard let user = user else{return}
        guard let show = show else{return}
        guard let authInfo = authInfo else{return}
        navigateToReview(user: user, authInfo: authInfo, show: show)
    }
}

// MARK: - table view row and cell setup

extension DetailsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let reviews = reviews else {return 0}
        return 1 + reviews.count
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: DetailsTableViewCell.self),
                for: indexPath
            ) as! DetailsTableViewCell
            cell.configure(with: show!)
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: ReviewsTableViewCell.self),
            for: indexPath
        ) as! ReviewsTableViewCell
        guard let reviews = reviews else { return UITableViewCell() }
        cell.configure(with: reviews[indexPath.row - 1])

        return cell
    }
    
}

// MARK: - tableView setup

private extension DetailsViewController {

    func setupTableView() {
        detailsTableView.rowHeight = UITableView.automaticDimension
        detailsTableView.estimatedRowHeight = 250

        detailsTableView.tableFooterView = UIView()

        detailsTableView.delegate = self
        detailsTableView.dataSource = self
    }
}

// MARK: - delegation setup
extension DetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let cell = tableView.cellForRow(at: indexPath)
        else {return}
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 0.3
        flash.fromValue = 1
        flash.toValue = 0.1
        flash.autoreverses = true
        flash.repeatCount = 1
        cell.layer.add(flash, forKey: nil)
        detailsTableView.deselectRow(at: indexPath, animated: true)

    }
}


// MARK: - navigation

extension DetailsViewController {
    func navigateToReview(user:User, authInfo:AuthInfo, show:Show) {
        
        let storyboard = UIStoryboard(name: "Review", bundle: nil)

        guard let reviewViewController = storyboard.instantiateViewController(withIdentifier: "ReviewViewController") as? ReviewViewController else {return}

       let navigationController = UINavigationController(rootViewController: reviewViewController)
        
        reviewViewController.delegate = self

        reviewViewController.setUserResponseAndAuthInfoAndShow(user: user, authInfo: authInfo, show: show)
        
       present(navigationController, animated: true)
        
    }
}

extension DetailsViewController: ReviewViewControllerDelegate {
    func didAddReview(review: Review) {
        reviews?.insert(review, at: 0)
        detailsTableView.reloadData()
    }
}
