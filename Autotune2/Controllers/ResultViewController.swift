//
//  ResultViewController.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//

import UIKit

class ResultViewController: UIViewController {
    
    var percentageInsulinDemandValue: String?
    var advice: String?
    
    @IBOutlet weak var insulinDemandLabel: UILabel!
    @IBOutlet weak var adviceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        insulinDemandLabel.text = percentageInsulinDemandValue
        adviceLabel.text = advice
    }
    
    @IBAction func recalculatePressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}