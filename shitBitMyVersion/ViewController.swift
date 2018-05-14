//
//  ViewController.swift
//  shitBitMyVersion
//
//  Created by Jaryd Saevitzon on 4/27/18.
//  Copyright © 2018 M117. All rights reserved.
//

import UIKit
import CoreBluetooth


let heartRateService = CBUUID(string: "0x180D");

class ViewController: UIViewController {
    var cbCentralManager : CBCentralManager!;
    var heartRateSensor  : CBPeripheral!;

    @IBOutlet weak var heartRateText: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad();
        
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
            cbCentralManager.scanForPeripherals(withServices: [heartRateService]);
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
        heartRateSensor.discoverServices([heartRateService]);
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
                print(serv);
                peripheral.discoverCharacteristics(nil, for: serv);
            }
            
        } else {return;}
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for char in characteristics {
                if char.properties.contains(.read) {
                    peripheral.readValue(for: char);
                }
                if char.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: char);
                }
                //if char.properties.contains(.write) {
                   // peripheral.writeValue(nil, for: char)
                // }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}
