//
//  MainViewController.swift
//  DFU sample
//
//  Created by Paul Aigueperse on 17-01-25.
//  Copyright © 2017 CleverToday. All rights reserved.
//

import UIKit
import CoreBluetooth
import Barracks
import iOSDFULibrary

protocol ViewControllerPage {
    
    func index() -> Int
}


class MainViewController: UIViewController, DFUServiceDelegate, DFUProgressDelegate, CBCentralManagerDelegate, LoggerDelegate {
    
    var client:BarracksClient?
    var updateResponse: UpdateCheckResponse!
    
    var dfuServiceController: DFUServiceController?
    var bleDevice:CBPeripheral?
    var updatePath:URL?
    var centralManager:CBCentralManager?
    
    
    // IBOutlets
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var versionIDTextField: UITextField!
    @IBOutlet weak var versionIdLabel: UILabel!
    @IBOutlet weak var updateStateLabel: UILabel!
    @IBOutlet weak var updateNameLabel: UILabel!
    @IBOutlet weak var updateSizeLabel: UILabel!
    @IBOutlet weak var installStateLabel: UILabel!
    @IBOutlet weak var installProgressBar: UIProgressView!
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    /// Callback from Barracks for check update request
    class MyUpdateCallback : UpdateCheckCallback {
        weak var parent: MainViewController!
        func onUpdateAvailable(_ request:UpdateCheckRequest, update:UpdateCheckResponse) {
        
            parent.setUpdate(update: update, error: nil)
        }
        func onUpdateUnavailable(_ request:UpdateCheckRequest){
            
            parent.setUpdate(update: nil, error: nil)
        }
        func onError(_ request:UpdateCheckRequest, error:Error?){
            
            parent.setUpdate(update: nil, error: error)
        }
    }
    
    
    /// PackageDownloadCallback from Barracks
    class MyDownloadCallback : PackageDownloadCallback {
        weak var parent: MainViewController! = nil
        func onError(_ response: UpdateCheckResponse, error: Error?) {
            
            parent.installStateLabel?.text = error?.localizedDescription
        }
        func onProgress(_ response: UpdateCheckResponse, progress: UInt) {
            
            parent.installProgressBar.setProgress(Float(progress / 100) / 2, animated: true)
            
        }
        func onSuccess(_ response: UpdateCheckResponse, path: String) {
            
            parent.installStateLabel.text? = "Start DFU"
            parent.setFirmewareUrl(path: path)
            parent.startDiscover()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI setup
        self.mainButton.layer.cornerRadius = self.mainButton.layer.bounds.size.height / 2
        self.view.subviews[1].layer.cornerRadius = 10
        self.deviceNameLabel.text = bleDevice?.name
        
        // Init the Barracks Client
        self.client = BarracksClient("YOUR_API_KEY",
                                     baseUrl: "https://app.barracks.io/api/device/update/check",
                                     ignoreSSL:true)
        
        mainButton.tag = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        self.versionIDTextField?.becomeFirstResponder()
    }

    @IBAction func maintButtonClicked(_ sender: UIButton) {
        
        switch sender.tag {
        case 0:
            checkUpdate()
        case 1:
            installUpdate()
        case 2:
            self.dismiss(animated: true, completion: nil)
            
        default:
            print("Default")
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        cancelButton.isHidden = dfuServiceController?.abort() ?? true
    }
    
    /// Ask Barracks if a new update is availabe for the given unitIt + versionId
    func checkUpdate() {
        
        if(versionIDTextField.text != nil && !versionIDTextField.text!.isEmpty){
            self.versionIDTextField.resignFirstResponder()
            let request = UpdateCheckRequest(unitId: "nrf52-iOS", versionId: versionIDTextField.text ?? "")
            let callback = MyUpdateCallback()
            callback.parent = self
           client?.checkUpdate(request, callback:callback)
        }
    }
    
    /// Download update from Barracks then proceed to DFU
    func installUpdate(){
    
        installProgressBar.isHidden = false
        installStateLabel.isHidden = false
        updateStateLabel.isHidden = true
        mainButton.isHidden = true
        cancelButton.isHidden = false
        
        // Download update from barracks
        installStateLabel?.text = "Download update"
        let callback = MyDownloadCallback()
        callback.parent = self
        client?.downloadPackage(updateResponse!, callback: callback)
    }

    
    func startDiscover(){
        
        // Start central mangaer to find ble device and start DFU
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    
    // MARK: - Bluetooth
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if(central.state == .poweredOn){
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Start DFU process as soon as the centralManager get the target device
        if(peripheral.identifier == bleDevice?.identifier){
            centralManager?.stopScan()
            self.bleDevice = peripheral
            startDfuProcess()
        }
    }
    
    // MARK: - DFU
    
    /// Start the dfu process
    func startDfuProcess(){
        
        guard bleDevice != nil else {
            print("No DFU peripheral was set")
            return
        }
        
        let dfuInitiator = DFUServiceInitiator(centralManager: centralManager!, target: bleDevice!)
        dfuInitiator.delegate = self
        dfuInitiator.progressDelegate = self
        dfuInitiator.logger = self
        
        // This enables the experimental Buttonless DFU feature from SDK 12.
        // Please, read the field documentation before use.
        dfuInitiator.enableUnsafeExperimentalButtonlessServiceInSecureDfu = false
        
        let fw = DFUFirmware(urlToZipFile: updatePath!)
        if(fw != nil){
            self.dfuServiceController = dfuInitiator.with(firmware: fw!).start()
            cancelButton.isEnabled = true
        }else{
            print("Error creating Zip file")
        }
    }
    
    
    func dfuStateDidChange(to state: DFUState) {
        
        self.installStateLabel?.text = state.description()
        
        if(state == .completed){
            cancelButton.isHidden = true
            mainButton.isHidden = false
            mainButton.tag = 2
            mainButton.setTitle("BACK TO DEVICES LIST", for: .normal)
        }
    }

    
    func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        print("dfu error : \(message)")
    }
    
    func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        installProgressBar.setProgress(50 + (Float(progress)/100.0 / 2), animated: true)
    }
    
    func logWith(_ level: LogLevel, message: String) {
        print("logWith (\(level.name())) : \(message)")
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.versionIDTextField?.resignFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        dfuServiceController?.abort()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        dfuServiceController?.abort()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func helpButtonClicked(_ sender: Any) {
        
        UIApplication.shared.openURL(URL(string: "https://barracksiot.github.io/")!)
    }
    

    // MARK: - Setters
    
    func setUpdate(update:UpdateCheckResponse?, error:Error?){
    
        if(update != nil){
            self.updateResponse = update!
            updateStateLabel?.text = "New Update Available"
            updateNameLabel?.text = update!.versionId
            updateSizeLabel?.text = "\(Int(update!.packageInfo.size / 1000)) ko"
            versionIdLabel.isHidden = false
            versionIDTextField?.isUserInteractionEnabled = false
            mainButton.setTitle("PROCEED", for: .normal)
            mainButton.tag = 1
            
        }else if (error != nil){
            updateStateLabel?.text = error?.localizedDescription
        }else{
            updateStateLabel?.text = "No Update Available"
        }
        
    }
    
    
    /// We need to ansure that the file is a zip file.
    func setFirmewareUrl(path:String){
        
        var updatePath = path
        let ext = (path as NSString).pathExtension
        
        if(!ext.isEmpty && ext.lowercased() != "zip"){
            
            let extLengh = ext.characters.count
            updatePath = updatePath.replacingCharacters(in: updatePath.index(updatePath.endIndex, offsetBy: -extLengh)..<updatePath.endIndex, with: "zip")
            
        }else{
            updatePath += ".zip"
        }
        
        let fileManager = FileManager.default
        
        // Rename file
        do {
            if(fileManager.fileExists(atPath: updatePath)){
                try fileManager.removeItem(atPath: updatePath)
            }
            
            try fileManager.moveItem(atPath: path, toPath: updatePath)
            self.updatePath = URL(fileURLWithPath: updatePath)
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)") }
    }


}
