import TransitionButton
import UIKit

class StartViewController: UIViewController {
    
    let SingleMode = TransitionButton(frame: CGRect(x: 137 , y: 700, width: 150, height: 60));
    
    let MultiMode = TransitionButton(frame: CGRect(x: 137, y: 600, width: 150, height: 60))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // transition button related
        self.view.addSubview(SingleMode)
        self.view.addSubview(MultiMode)//add second button
        
        ///add background image to the current view
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "art.scnassets/bgblack.jpg")?.draw(in: self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
        
        // set view for button
        SingleMode.backgroundColor = .red
        SingleMode.setTitle("Solo", for: .normal)
        SingleMode.cornerRadius = 20
        SingleMode.spinnerColor = .white
        SingleMode.titleLabel?.sizeToFit()
        SingleMode.addTarget(self, action: #selector(startBtnPressed(_:)), for: .touchUpInside)
        
        // set view for MultiButton
        MultiMode.backgroundColor = .red
        MultiMode.setTitle("Connect", for: .normal)
        MultiMode.cornerRadius = 20
        MultiMode.spinnerColor = .white
        MultiMode.titleLabel?.sizeToFit()
        MultiMode.addTarget(self, action: #selector(multiBtnPressed(_:)), for: .touchUpInside)
        
    }
    @IBAction func multiBtnPressed(_ MultiMode: TransitionButton) {
        MultiMode.startAnimation()
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            
            DispatchQueue.main.async(execute: { () -> Void in
                //  stop playing the music and perform segue transfer
                self.performSegue(withIdentifier: "routeToMulti", sender: self)
                MultiMode.stopAnimation(animationStyle: .expand, completion: {
                    let secondVC = UIViewController()
                    self.present(secondVC, animated: true, completion: nil)
                })
            })
        })
    }
    
    
    // perform animation affect on button and invoke perform segue
    @IBAction func startBtnPressed(_ SingleMode: TransitionButton) {
        SingleMode.startAnimation()
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            
            DispatchQueue.main.async(execute: { () -> Void in
                //  stop playing the music and perform segue transfer
                self.performSegue(withIdentifier: "routeToHome", sender: self)
                SingleMode.stopAnimation(animationStyle: .expand, completion: {
                    let secondVC = UIViewController()
                    self.present(secondVC, animated: true, completion: nil)
                })
            })
        })
    }
}

