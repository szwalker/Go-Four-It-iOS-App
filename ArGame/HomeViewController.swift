import TransitionButton
import SkyFloatingLabelTextField
import AVFoundation
import UIKit

class HomeViewController: UIViewController,UITextFieldDelegate {
    
    var AtextField:SkyFloatingLabelTextField = SkyFloatingLabelTextField()
    var BtextField:SkyFloatingLabelTextField = SkyFloatingLabelTextField()
    
    var inputA:String = String()

    var audioPlayer : AVAudioPlayer!
    let button = TransitionButton(frame: CGRect(x: 137 , y: 600, width: 150, height: 60));
    let backbutton = TransitionButton(frame: CGRect(x: 137 , y: 700, width: 150, height: 60));

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lightGreyColor = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1.0)
        let overcastBlueColor = UIColor(red: 0, green: 187/255, blue: 204/255, alpha: 1.0)
        
        let AtextField = SkyFloatingLabelTextField(frame: CGRect(x: self.view.frame.width/2-(130/2), y: self.view.frame.height/2-45, width: 130, height: 45))
        AtextField.placeholder = "    Red Player"
        AtextField.title = "Red Player"
        AtextField.tintColor = UIColor.red
        AtextField.textColor = lightGreyColor
        AtextField.lineColor = lightGreyColor
        AtextField.selectedTitleColor = UIColor.red
        AtextField.selectedLineColor = UIColor.red
        AtextField.lineHeight = 2.0
        AtextField.selectedLineHeight = 2.0
        self.view.addSubview(AtextField)
        
        let BtextField = SkyFloatingLabelTextField(frame: CGRect(x: self.view.frame.width/2-(130/2), y: self.view.frame.height/2+45, width: 130, height: 45))
        BtextField.placeholder = "    Blue Player"
        BtextField.title = "Blue Player"
        BtextField.tintColor = overcastBlueColor
        BtextField.textColor = lightGreyColor
        BtextField.lineColor = lightGreyColor
        BtextField.selectedTitleColor = overcastBlueColor
        BtextField.selectedLineColor = overcastBlueColor
        BtextField.lineHeight = 2.0
        BtextField.selectedLineHeight = 2.0
        self.view.addSubview(BtextField)
        // set delegate for textfields
        AtextField.delegate = self
        BtextField.delegate = self
        
        // add actions
        AtextField.addTarget(self, action: #selector(AtextFieldComplete(_:)), for: .editingDidEnd)
        BtextField.addTarget(self, action: #selector(BtextFieldComplete(_:)), for: .editingDidEnd)

        // transition button related
        self.view.addSubview(button)
        self.view.addSubview(backbutton)//add second button

        
        // play music for the first view
        let soundURL = Bundle.main.url(forResource: "Wind", withExtension: "wav")
        audioPlayer = try! AVAudioPlayer(contentsOf: soundURL!)
        audioPlayer.play()
        
        ///add background image to the current view
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "art.scnassets/bgblack.jpg")?.draw(in: self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
        
        // set view for button
        button.backgroundColor = .red
        button.setTitle("START", for: .normal)
        button.cornerRadius = 20
        button.spinnerColor = .white
        button.titleLabel?.sizeToFit()
        button.addTarget(self, action: #selector(startBtnPressed(_:)), for: .touchUpInside)
        
        // set view for backbutton
        backbutton.backgroundColor = .red
        backbutton.setTitle("BACK", for: .normal)
        backbutton.cornerRadius = 20
        backbutton.spinnerColor = .white
        backbutton.titleLabel?.sizeToFit()
        backbutton.addTarget(self, action: #selector(backBtnPressed(_:)), for: .touchUpInside)
        
    }
    // record user inputs for A text field
    @objc func AtextFieldComplete(_ textField: UITextField) {
        AtextField.text = textField.text;
    }
    
    // record user inputs for B text field
    @objc func BtextFieldComplete(_ textField: UITextField) {
        BtextField.text = textField.text;
    }
    // dissable keyboard when user finish typing
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.AtextField.resignFirstResponder()
        self.BtextField.resignFirstResponder()
    }
    
    
    
    // pass player name information to the AR view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "routeToAR"{
            let destinationVC = segue.destination as! ViewController
            if AtextField.text != nil{
                destinationVC.playerAName = AtextField.text!
            }
            if BtextField.text != nil{
                destinationVC.playerBName = BtextField.text!
            }
        }
    }

    // delegate method for textfield to quit keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true;
    }
    
    // perform animation affect on button and invoke perform segue
    @IBAction func startBtnPressed(_ button: TransitionButton) {
        button.startAnimation()
        audioPlayer.stop()
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            sleep(1)
            DispatchQueue.main.async(execute: { () -> Void in
                //  stop playing the music and perform segue transfer
                self.performSegue(withIdentifier: "routeToAR", sender: self)
                button.stopAnimation(animationStyle: .expand, completion: {
                    let secondVC = UIViewController()
                    self.present(secondVC, animated: true, completion: nil)
                })
            })
        })
    }
    @IBAction func backBtnPressed(_ backbutton: TransitionButton) {
        backbutton.startAnimation()
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            DispatchQueue.main.async(execute: { () -> Void in
                backbutton.stopAnimation(animationStyle: .expand, completion: {
                    self.dismiss(animated: true, completion: nil)
                })
            })
        })
    }
}
