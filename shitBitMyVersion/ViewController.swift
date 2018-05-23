//
//  ViewController.swift
//  shitBitMyVersion
//
//  Created by Jaryd Saevitzon on 4/27/18.
//  Copyright © 2018 M117. All rights reserved.
//

import UIKit
import CoreBluetooth


let hrService = CBUUID(string: "0x180D");
let hrmCharCBUUID = CBUUID(string: "2A37");
var maxHeartRate = 0;
//Changed: Added Text for the motivational message
let messages = ["Start Workout When Ready", "Heart Rate is too low", "Good Job! Keep it Up!"];
let partialMaxHeartRate = 140;


class ViewController: UIViewController {
    var cbCentralManager : CBCentralManager!;
    var heartRateSensor  : CBPeripheral!;

    @IBOutlet weak var heartRateText: UILabel!
    
    //Changed: Added maxHeartRateText and motivation message
    @IBOutlet weak var maxHeartRateText: UILabel!
    @IBOutlet weak var motiviationMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        //Changed: Initializing the labels to zeros
        maxHeartRateText.text = String(0);
        heartRateText.text = String(0);
        motiviationMessage.text = messages[0];
        motiviationMessage.backgroundColor = UIColor.white;
        
        cbCentralManager = CBCentralManager(delegate: self, queue: nil);
        
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state;
        
        if state == .unknown {
            print("State unknown");
        }
        else if state == .resetting {
            print("State resetting");
        }
        else if state == .unsupported {
            print("State unsupported");
        }
        else if state == .poweredOn {
            print("Device powered on");
            cbCentralManager.scanForPeripherals(withServices: [hrService]);
        }
        else if state == .poweredOff {
            print("Device powered off");
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //called if bluetooth device discovered
        heartRateSensor = peripheral;
        heartRateSensor.delegate = self;
        
        //can stop scanning now
        cbCentralManager.stopScan();
        
        //connect
        cbCentralManager.connect(heartRateSensor);
    }
    
    //connected to HRS
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        //TODO: lookup heartRateServiceCBUUID, and update discoverServices()
        print("CONNECTED");
        let ac = UIAlertController(title: "Connected", message: "Connected To Heartrate",
                                   preferredStyle: .alert);
        ac.addAction(UIAlertAction(title: "OK", style: .default));
        self.present(ac, animated: true);
        heartRateSensor.discoverServices([hrService]);
    }
    
    //Unable to connect to HRS
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let ac = UIAlertController(title: "Not Connected", message: "Could not connect To Heartrate",
                                   preferredStyle: .alert);
        ac.addAction(UIAlertAction(title: "OK", style: .default));
        self.present(ac, animated: true);
        return
    }
    
    //Disconnected from HRS
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let ac = UIAlertController(title: "Disconnected", message: "Disconnected from Heartrate",
                                   preferredStyle: .alert);
        ac.addAction(UIAlertAction(title: "OK", style: .default));
        self.present(ac, animated: true);
        return
    }
    
}

extension ViewController : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //better way to do next line because it may fail
        if let services = peripheral.services {
            for serv in services {
                peripheral.discoverCharacteristics(nil, for: serv);
            }
        } else {return;}
    }
    
    
    //Only .notify characteristic should be necessary
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for char in characteristics {
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char);
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "2A37") {
            
            //update heart rate
            let hr = heartRate(from: characteristic);
            
            //for debugging
            print("Characteristic heartrate \(characteristic.uuid)");
            print("\(hr)");
            
            
            //motivational messages
            //if hr > maxHeartRate! could crash. Changing it...
            if  hr > maxHeartRate {
                maxHeartRate = hr;
                maxHeartRateText.text = String(hr);
            }
            
            //Changed: Added motivational stuff
            if hr >= (partialMaxHeartRate) {
                motiviationMessage.text = messages[2];
                motiviationMessage.backgroundColor = UIColor.green;
            }
            else{
                motiviationMessage.text = messages[1];
                motiviationMessage.backgroundColor = UIColor.red;
            }
            
            //moved this outside of blocks.
            motiviationMessage.textColor = UIColor.white;
            heartRateText.text = String(hr);
        }
        else {
            print("Characteristic unconcerned about: ")
            print(characteristic.uuid);
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData);
        return Int(byteArray[1]);
    }
}











