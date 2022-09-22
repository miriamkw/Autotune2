//
//  ResultViewController.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//

import UIKit

class ResultViewController: UIViewController {
    
    var ME: String?
    var RMSE: String?
    var advice: String?
    
    @IBOutlet weak var MELabel: UILabel!
    @IBOutlet weak var RMSELabel: UILabel!
    @IBOutlet weak var adviceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MELabel.text = ME
        RMSELabel.text = RMSE
        adviceLabel.text = advice
    }
    
    @IBAction func recalculatePressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
