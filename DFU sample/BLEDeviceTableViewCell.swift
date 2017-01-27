//
//  BLEDeviceTableViewCell.swift
//  DFU sample
//
//  Created by Paul Aigueperse on 17-01-23.
//  Copyright © 2017 CleverToday. All rights reserved.
//

import UIKit

class BLEDeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel:UILabel?
    @IBOutlet weak var adresseLabel:UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
