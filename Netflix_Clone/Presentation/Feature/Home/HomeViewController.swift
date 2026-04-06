//
//  ViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import NSObject_Rx

final class HomeViewController: BaseViewController<HomeView> {
    private let viewModel: HomeViewModel // init 메서드에서 생성 후 할당
    private var sections: [HomeViewModel.Section] = []
    
    
    // viewModel: HomeViewModel = HomeViewModel() 때문에 ViewModel의 init()을 실행하고 옴
    // 이유 -> HomeViewModel의 기본 값 생성을 위해 init()이 실행되어야 하기 때문
    // 메모리에 로드됨 (가장 먼저 호출)
    init(viewModel: HomeViewModel = HomeViewModel()) {
        // 전달받은 뷰모델을 저장
        self.viewModel = viewModel
        
        // 부모 컨트롤러 초기화
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // init() -> loadView()
    // 실제 뷰(UI)를 만드는 단계
    override func loadView() {
        super.loadView()
        self.navigationController?.isNavigationBarHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // 메모리 로드가 끝난 상태
    // 생명주기에서 시작 타이밍을 잡음
    // 뷰가 메모리에 올라왔을 때 한 번만 호출. 여기서 초기 설정을 함
    // init() -> loadView() -> viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        setupDataSources()
        setupBindings()
        viewModel.input.accept(.viewDidLoad) // VM에 화면 떴음을 알림
    }
    
    // 테이블 뷰한테 내가 데이터를 준다고 등록
    private func setupDataSources() {
        mainView.sectionsTableView.register(
            HomeSectionTableViewCell.self,
            forCellReuseIdentifier: HomeSectionTableViewCell.reuseIdentifier
        )

        mainView.sectionsTableView.dataSource = self
        mainView.sectionsTableView.delegate = self
    }
    
    // View <-> ViewModel 파이프 연결
    private func setupBindings() {
        bindInput()
        bindOutput()
    }
    
    // 프로필 버튼 탭 -> 화면 전환
    private func bindInput() {
        mainView.topBarView.profileButton.rx.tap // Void Event
            .map { HomeViewModelInput.profileButtonTapped }
            .bind(to: viewModel.input)
            .disposed(by: rx.disposeBag)
    }
    
    // 라우트가 바뀌면 해당 스트림 발화
    private func bindOutput() {
        viewModel.output.sections
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, sections in
                owner.sections = sections
                owner.mainView.sectionsTableView.reloadData()
            }
            .disposed(by: rx.disposeBag)
        
        // 라우팅 로직
        viewModel.output.route
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, route in
                owner.route(to: route)
                owner.viewModel.input.accept(.didFinishRouting)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.presentAlert(message: message)
            }
            .disposed(by: rx.disposeBag)
    }
    
    private func route(to route: HomeViewModel.Route) {
        switch route {
        case .profile:
            let profileViewController = makeProfileViewController()
            
            if let navigationController {
                navigationController.pushViewController(profileViewController, animated: true)
            } else {
                let modalNavigationController = UINavigationController(rootViewController: profileViewController)
                profileViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    systemItem: .close,
                    primaryAction: UIAction { [weak modalNavigationController] _ in
                        modalNavigationController?.dismiss(animated: true)
                    }
                )
                modalNavigationController.modalPresentationStyle = .fullScreen
                present(modalNavigationController, animated: true) // BottomSheet ///  .fullScreen
            }
        }
    }

    private func makeProfileViewController() -> UIViewController {
        ProfileViewController()
    }

    private func presentAlert(message: String) {
        let alertController = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertController, animated: true)
    }
}

private final class HomeSectionTableViewCell: UITableViewCell {
    static let reuseIdentifier = "HomeSectionTableViewCell"

    private var sectionView: HorizontalPosterSectionView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sectionView?.removeFromSuperview()
        sectionView = nil
    }

    func configure(with section: HomeViewModel.Section) {
        sectionView?.removeFromSuperview()

        let sectionView = HorizontalPosterSectionView(title: section.title, items: section.items)
        contentView.addSubview(sectionView)

        sectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.sectionView = sectionView
    }
}

// MARK: - DataSource, Delegate
// TableView를 사용할 때 DataSource와 Delegate 이렇게 두 개의 프로토콜 사용
// 나누는 이유는 단일책임원칙과 가독성+유지보수
// DataSource : 무엇을 보여줄 것인가 -> 데이터 개수 파악, 실제 데이터 전달, 셀 생성
// Delegate : 어떻게 보여주고 반응할까 -> 셀 높이 결정, 클릭 이벤트 처리, 레이아웃 세부 조정

// 데이터 공급
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HomeSectionTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? HomeSectionTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(with: sections[indexPath.row])
        return cell
    }
}

// 이벤트 관리
extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.input.accept(.sectionSelected(index: indexPath.row))
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
