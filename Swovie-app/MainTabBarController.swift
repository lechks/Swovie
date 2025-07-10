import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let matchVC = UINavigationController(rootViewController: MatchViewController())
        matchVC.tabBarItem = UITabBarItem(title: "Свайп",
                                          image: UIImage(systemName: "hand.point.right"),
                                          tag: 0)

        let ratingVC = UINavigationController(rootViewController: RatingViewController())
        ratingVC.tabBarItem = UITabBarItem(title: "Оценка",
                                           image: UIImage(systemName: "star"),
                                           tag: 1)

        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        profileVC.tabBarItem = UITabBarItem(title: "Профиль",
                                            image: UIImage(systemName: "person.circle"),
                                            tag: 2)

        let catalogVC = UINavigationController(rootViewController: CatalogViewController())
        catalogVC.tabBarItem = UITabBarItem(title: "Каталог",
                                            image: UIImage(systemName: "film"),
                                            tag: 3)

        viewControllers = [matchVC, ratingVC, profileVC, catalogVC]
    }
}
