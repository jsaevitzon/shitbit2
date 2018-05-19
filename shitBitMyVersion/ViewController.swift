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
var maxHeartRate : Int?;

class ViewController: UIViewController {
    var cbCentralManager : CBCentralManager!;
    var heartRateSensor  : CBPeripheral!;

    @IBOutlet weak var heartRateText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad();
        maxHeartRate = -1;
        cbCentralManager = CBCentralManager(delegate: self, queue: nil);
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state;
        
        if state == .unknown {
            
        }
        else if state == .resetting {
            
        }
        else if state == .unsupported {
            
        }
        else if state == .poweredOn {
            //TODO: Make this so it only looks for heart rate monitors
            cbCentralManager.scanForPeripherals(withServices: [hrService]);
        }
        else if state == .poweredOff {
            
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
                //allow hrm to notify phone of incoming data
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char);
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: "2A37") {
            //update heart rate
            print("Characteristic heartrate \(characteristic.uuid)");
            let hr = heartRate(from: characteristic);
            
            if hr > maxHeartRate! {
                maxHeartRate = hr;
            }
            
            heartRateText.text = String(hr) + "1";
        }
        else {
            print("Characteristic unconcerned about: ")
            print(characteristic.uuid);
        }
    }
    
    
    //TODO: GONNNA HAVE TO REVAMP THIS CODE... WAY TOO COPPIED
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        /*
        // See: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.heart_rate_measurement.xml
        // The heart rate mesurement is in the 2nd, or in the 2nd and 3rd bytes, i.e. one one or in two bytes
        // The first byte of the first bit specifies the length of the heart rate data, 0 == 1 byte, 1 == 2 bytes
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    */
        return Int(byteArray[1]);
    }
}











