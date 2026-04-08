//
//  LifecycleViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/3/26.
//

import UIKit

final class LifecycleViewController: UIViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        print("\(#function)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() { // memory 올라감
        super.loadView()
        print("\(#function)")
    }
    
    override func viewDidLoad() { // memory load End
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) { // 뷰가 이제 보일꺼임
        super.viewWillAppear(true)
        print("\(#function)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("\(#function)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("\(#function)")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("\(#function)")
    }
    
    deinit {
        print("\(#function)")
    }
}


import SwiftUI

struct ExampleView: View {
    
    var body: some View {
        VStack {
            
        }
        .onAppear {

        }
        .task { // async await

        }
        .onDisappear {
            
        }
    }
}
