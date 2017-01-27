//
//  BLEScannerTableViewController.swift
//  DFU sample
//
//  Created by Paul Aigueperse on 17-01-23.
//  Copyright © 2017 CleverToday. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEScannerTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate {


    var centralManager: CBCentralManager?
    var peripheralsDict: NSMutableDictionary = NSMutableDictionary()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var devicesNumberLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
    }
    
    @IBAction func helpButtonClicked(_ sender: Any) {
        
        UIApplication.shared.openURL(URL(string: "https://barracksiot.github.io/")!)
    }
    override func viewDidAppear(_ animated: Bool) {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        peripheralsDict.setValue(peripheral, forKey: "\(peripheral.identifier)")
        tableView.reloadData()
        self.devicesNumberLabel.text = "\(peripheralsDict.count)"
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if (central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return peripheralsDict.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:BLEDeviceTableViewCell = self.tableView.dequeueReusableCell(withIdentifier:"deviceCell")! as! BLEDeviceTableViewCell
        
        let peripheral = peripheralsDict.allValues[indexPath.row] as! CBPeripheral
        cell.nameLabel?.text = peripheral.name
        cell.adresseLabel?.text = "\(peripheral.identifier)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "showMain"?:
            
            centralManager?.stopScan()
            
            let vc = segue.destination as! MainViewController
            if let i = tableView.indexPathForSelectedRow as NSIndexPath? {
                vc.bleDevice = self.peripheralsDict.allValues[i.row] as? CBPeripheral
            }
            
        default:
            print("Unknown segue identifier : \(segue.identifier)")
        }
    }


}
