//
//  MultiVC.swift
//  ArGame
//
//  Created by Jiaqi Liu on 5/7/19.
//  Copyright © 2019 Chenyu Liu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import MultipeerConnectivity


class MultiVC: UIViewController,ARSCNViewDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate{
    // peer to peer config
    var msg = String()
    var peerID:MCPeerID!
    var mcSession:MCSession!
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    var myColor = String()
    @IBOutlet var confirmBtn: UIButton!
    @IBOutlet var quitBtn: UIButton!
    var audioPlayer : AVAudioPlayer!
    
    @IBOutlet var hostBtn: UIButton!
    @IBOutlet var backBtn: UIButton!
    @IBOutlet var joinBtn: UIButton!
    
    // default player name
    var playerAName:String = "Player A"
    var playerBName:String = "Player B"
    var poleGeomeArray = [SCNCone]()
    var poleArr = [SCNNode]()
    var currentColor = "red"
    // chessArr[i] is the chess array for the ith pole node
    // 2D array of chess object, each chessArr[i][j] denotes the jth chess array of the ith node
    var chessArr = [[String]]()
    var selectedNode : SCNNode? = nil
    var step = 0;//
    var playeMove = 0// 0:player A 1:playerB
    var playerMoveTextNode : SCNNode?
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // shows shadow of AR nodes as if they were in the real 3d place
        sceneView.autoenablesDefaultLighting = true
        
        // Hide all buttons
        confirmBtn.isHidden = true
        quitBtn.isHidden = true
        let uiRed = UIColor.red
        confirmBtn.backgroundColor = uiRed
        quitBtn.backgroundColor = uiRed
        // peer to peer setup
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self

        
        // Set the view's delegate
        sceneView.delegate = self
        
        updateText(text: playerAName+" Move")
        
        // create a 5 x 5 pole geometry array
        for __ in 0..<5{
            for _ in 0..<5{
                poleGeomeArray.append(SCNCone(topRadius: 0.01, bottomRadius: 0.01, height: 0.5))
                chessArr.append(["n","n","n","n","n"]);
            }
        }
        
        // add reflection material to the geomerty
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.9)
        
        if(!poleGeomeArray.isEmpty){
            for p in poleGeomeArray {
                p.materials = [material]
            }
        }
        
        // initialize arrary of vectors, and adjust positions accordingly.
        var arrOfVectors = [SCNVector3]()
        var baseVector = SCNVector3(x: -0.3, y: -0.2, z: -0.6)
        for __ in 1...5{
            for _ in 1...5{
                baseVector = SCNVector3(baseVector.x,baseVector.y,baseVector.z-0.1)
                arrOfVectors.append(baseVector)
            }
            baseVector = SCNVector3(baseVector.x+0.1,-0.2,-0.6)
        }
        
        for v in 0...arrOfVectors.count-1{
            // initialize node based on the geometry, vector position, and reflection material
            let node = SCNNode()
            node.name = String(v) //String(v+1)//add a name to a node
            node.position = arrOfVectors[v]
            
            node.geometry = poleGeomeArray[v]
            
            // attach the newly created node to scene view
            poleArr.append(node)
            sceneView.scene.rootNode.addChildNode(node)
        }
        sceneView.showsStatistics = false
    }
    
    @IBAction func hostPressed(_ sender: Any) {
        self.myColor = "red"
        self.hostBtn.setTitle("Hosting...", for: .normal)
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "GoFourIt", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    @IBAction func joinPressed(_ sender: Any) {
        self.myColor = "blue"
        let mcBrowser = MCBrowserViewController(serviceType: "GoFourIt", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // detect touch
        if let touch = touches.first{
            let touchLocation = touch.location(in: sceneView)
            // perform hit test and determine whether the touch location is on one of the pole
            let results = sceneView.hitTest(touchLocation, options: [:])
            // touch location is on one of the pole
            if let hitResult = results.first{
                if hitResult.node.name! != "ball" && hitResult.node.name! != "text" && hitResult.node.name! != "locked" && self.currentColor == self.myColor{
                    confirmHitNode(n:hitResult.node)
                }
            }
        }
    }
    // process hit node information, called by touchesBegan.
    // verify whether the node position already has 5 nodes:
    // if so, display a message: you may not place on this pole
    // otherwise, change the color of pole to red and display a confirmation button: confirm
    func confirmHitNode(n:SCNNode){
        
        if self.selectedNode != nil {
            // restore color for original selected pole
            let origMaterial = SCNMaterial()
            origMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.9)
            self.selectedNode!.geometry!.materials = [origMaterial]
            self.selectedNode =  nil
        }
        
        // change color of the newly selected pole
        let materialForSelected = SCNMaterial()
        materialForSelected.diffuse.contents = UIColor(red: 44, green: 55, blue: 0, alpha: 0.7) //!!merge
        n.geometry!.materials = [materialForSelected]
        // show confirm button
        let uiRed = UIColor.red
        confirmBtn.backgroundColor = uiRed
        confirmBtn.isHidden = false
        let poleNodeInd = Int(n.name!)
        // determine whether we should allow user to place chess on this pole
        confirmBtn.isUserInteractionEnabled = clearToAdd(chessArr: chessArr, poleInd: poleNodeInd!)
        if(confirmBtn.isUserInteractionEnabled){
            confirmBtn.titleLabel?.text = "Confirm"
            confirmBtn.backgroundColor = uiRed
        }
        else{
            confirmBtn.titleLabel?.text = "Pole full"
            confirmBtn.backgroundColor = uiRed
        }
        // update selected pole node to n
        self.selectedNode = n
    }
    
    // checks whether the given pole index is full, returns true if not full and false otherwise
    func clearToAdd(chessArr: [[String]],poleInd:Int) -> Bool {
        for x in chessArr[poleInd]{
            if x == "n"{
                return true;
            }
        }
        return false;
    }
    @IBAction func confirmBtnPressed(_ sender: Any) {
        insertChessOnBoard(sendData:true)
        // restore color for original selected pole
        let origMaterial = SCNMaterial()
        origMaterial.diffuse.contents = UIColor(white: 1, alpha: 0.9)
        self.selectedNode!.geometry!.materials = [origMaterial]
        self.selectedNode =  nil
        confirmBtn.isHidden = true
    }
    
    // quit button has beeen pressed
    @IBAction func quitBtnPressed(_ sender: Any) {
        // dismiss current view contorller
        dismiss(animated: true, completion: nil)
        // play a bye bye sound
        playSound(soundFileName: "ByeBye")
    }
    
    func send(msg:String) {
        if mcSession.connectedPeers.count > 0 {
            if let chessData = msg.data(using: .utf8) {
                do {
                    try mcSession.send(chessData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    // insert a chess on the selected pole node
    func insertChessOnBoard(sendData:Bool){
        let ind = Int(selectedNode!.name!)
        if(sendData){
            // send data to the connected peer
            send(msg:selectedNode!.name!)
        }
        for i in 0..<5{
            if chessArr[ind!][i] == "n"{
                chessArr[ind!][i] = self.currentColor;
                break;
            }
        }
        // alternating the player
        if currentColor == "red"{
            currentColor = "blue"
        }
        else{
            currentColor = "red"
        }
        
        
        let numBalls = getNumBalls(chessArr: chessArr, ind: ind!)
        let poleVector = self.selectedNode?.position
        
        let bally = poleVector!.y-0.30 + 0.1 * Float(numBalls);
        let ballV = SCNVector3(x: poleVector!.x, y: bally, z: poleVector!.z)
        
        //create ball
        createBall(color: currentColor, atposition: ballV )
        
        // note: can be moved outside of this function
        let mir = mirror(A: chessArr)
        
        
        var haveWin:Bool // level by level slice
        var haveWin2:Bool // side by side slice x
        var haveWin3:Bool // side by side slice y
        var haveWin4:Bool // cross layere diagonally slice
        var haveWin5:Bool // cross layere diagonally slice (mirror side)
        
        var winnerColor: String // level by level slice
        var winnerColor2: String // side by side slice x
        var winnerColor3: String // side by side slice y
        var winnerColor4: String // cross layere diagonally slice
        var winnerColor5: String // cross layere diagonally slice (mirror side)
        
        
        (haveWin,winnerColor) = checklevel(A: chessArr);
        (haveWin2,winnerColor2) = checksidex(A: chessArr);
        (haveWin3,winnerColor3) = checksidey(A: chessArr);
        (haveWin4,winnerColor4) = checkCrossLayerWin(A: chessArr);
        (haveWin5,winnerColor5) = checkCrossLayerWin(A: mir);
        
        if(haveWin || haveWin2 || haveWin3 || haveWin4 || haveWin5){
            if(haveWin){
                if(winnerColor == "red"){
                    updateText(text: "Game Over.\nWinner is "+playerAName)
                }
                else{
                    updateText(text: "Game Over.\nWinner is "+playerBName)
                }
            }
            else if(haveWin2){
                if(winnerColor2 == "red"){
                    updateText(text: "Game Over.\nWinner is "+playerAName)
                }
                else{
                    updateText(text: "Game Over.\nWinner is "+playerBName)
                }
            }
            else if(haveWin3){
                if(winnerColor3 == "red"){
                    updateText(text: "Game Over.\nWinner is "+playerAName)
                }
                else{
                    updateText(text: "Game Over.\nWinner is "+playerBName)
                }
                
            }
            else if(haveWin4){
                if(winnerColor4 == "red"){
                    updateText(text: "Game Over.\nWinner is "+playerAName)
                }
                else{
                    updateText(text: "Game Over.\nWinner is "+playerBName)
                }
            }
            else if(haveWin5){
                if(winnerColor5 == "red"){
                    updateText(text: "Game Over.\nWinner is "+playerAName)
                }
                else{
                    updateText(text: "Game Over.\nWinner is "+playerBName)
                }
            }
            // play tada sound for winner
            playSound(soundFileName: "TaDa")
            lockViewForWinner()
        }
            
        else if(self.playeMove == 0){
            // alternate player
            self.playeMove = 1
            updateText(text:playerBName+" Move")
            // play fall off sound to indicate the chess has been inserted
            playSound(soundFileName: "FallOffTrimed")
        }
        else{
            // alternate player
            self.playeMove = 0
            updateText(text:playerAName+" Move")
            // play fall off sound to indicate the chess has been inserted
            playSound(soundFileName: "FallOffTrimed")
        }
        
    }
    
    // Lock the view for winner. this function is invoked when a winner has been detected. No further user interaction besides the quit button is allowed.
    func lockViewForWinner(){
        // hide confirm button and display quit button
        quitBtn.isHidden = false
        let uiRed = UIColor.red
        quitBtn.backgroundColor = uiRed
        confirmBtn.isHidden = true
        // lock all nodes so there will no longer be any user interaction
        for x in poleArr{
            // changing the name at here will affect whether touchesBegan performs hit test checking
            x.name = "locked"
        }
    }
    
    // returns a mirrored 2d array of the original 2d string array
    func mirror(A:[[String]]) -> [[String]]{
        var mir = [[String]]();
        for _ in 0..<25{
            mir.append(["nil","nil","nil","nil","nil"])
        }
        var columnSum = 4
        var i = 0
        while(i<5){
            for j in i*5...i*5+4{
                let reverse = columnSum - j
                mir[j] = A[reverse]
            }
            i+=1
            columnSum += 10
        }
        return mir
    }
    
    func getNumBalls(chessArr:[[String]],ind:Int) -> Int{
        var count = 0
        for x in chessArr[ind]{
            if x != "n"{
                count += 1
            }
        }
        return count
    }
    
    
    func updateText(text:String){
        if(self.playerMoveTextNode == nil){
            let textGeometry = SCNText(string : text, extrusionDepth: 2.0)
            let materialB = SCNMaterial()
            materialB.diffuse.contents = UIImage(named: "art.scnassets/pinkBall.jpg")
            let materialR = SCNMaterial()
            materialR.diffuse.contents = UIImage(named: "art.scnassets/blueball.jpg")
            
            if(self.playeMove == 1) {
                textGeometry.materials = [materialR]
            }
            else{
                textGeometry.materials = [materialB]
                
            }
            let textNode = SCNNode(geometry: textGeometry)
            textNode.position = SCNVector3(-0.7, 0.3, -2.2)
            textNode.scale = SCNVector3(0.02,0.02,0.02)
            textNode.name = "text"
            self.playerMoveTextNode = textNode
            sceneView.scene.rootNode.addChildNode(textNode)
        }
        else{
            self.playerMoveTextNode!.removeFromParentNode()
            self.playerMoveTextNode = nil
            updateText(text: text)
        }
    }
    
    
    func createBall(color: String, atposition: SCNVector3 ){
        
        let ball = SCNSphere(radius: 0.05);
        let materialB = SCNMaterial()
        
        materialB.diffuse.contents = UIImage(named: "art.scnassets/pinkBall.jpg")
        let materialR = SCNMaterial()
        materialR.diffuse.contents = UIImage(named: "art.scnassets/blueball.jpg")
        
        //assign color to the ball
        if(color == "red"){
            ball.materials = [materialR]
        }else{
            ball.materials = [materialB]
        }
        let node = SCNNode()
        node.name = "ball"
        node.position = atposition
        node.geometry = ball;
        sceneView.scene.rootNode.addChildNode(node)
        
    }
    
    func checklevel(A:[[String]]) -> (Bool,String) {
        for i in 0..<5 {//for level from 0 to 4
            var currentlevel = [[String]]()
            for _ in 0..<5{
                currentlevel.append(["nil","nil","nil","nil","nil"])
            }
            var pnum = 0;
            
            for w in 0..<5{
                for l in 0..<5{
                    currentlevel[w][l] = A[pnum][i]
                    pnum += 1
                }
            }
            //check for winner on currentlevel
            var haveWinner:Bool
            var winnerColor:String
            
            (haveWinner, winnerColor) = checkWin(A: currentlevel);
            if(haveWinner){
                return (haveWinner,winnerColor)
            }
        }
        return (false,"no winner")
    }
    
    func checksidex(A:[[String]]) -> (Bool,String){
        for i in 0..<5{
            var currentside = [[String]]()
            for _ in 0..<5{
                currentside.append(["nil","nil","nil","nil","nil"])
            }
            var colume = 0;
            var k = i
            while(k<=i+20){
                currentside[colume] = A[k]
                colume+=1
                k+=5
            }

            //check for winner on currentlevel
            var haveWinner:Bool
            var winnerColor:String
            
            (haveWinner, winnerColor) = checkWin(A: currentside);
            if(haveWinner){
                return (haveWinner,winnerColor)
            }
        }
        return (false,"no winner")
    }
    
    func checksidey(A:[[String]]) -> (Bool,String){
        var i = 0
        while(i<20){
            var currentside = [[String]]()
            for _ in 0..<5{
                currentside.append(["nil","nil","nil","nil","nil"])
            }
            var colume = 0;
            for k in i...i+4{
                currentside[colume] = A[k]
                colume+=1
            }
            //check for winner on currentlevel
            var haveWinner:Bool
            var winnerColor:String
            (haveWinner, winnerColor) = checkWin(A: currentside);
            if(haveWinner){
                return (haveWinner,winnerColor)
            }
            i+=5
        }
        return (false,"no winner")
        
    }
    // checks the cross layer win from furthest left upper corner to closest bottom right corner
    func checkCrossLayerWin(A:[[String]])->(Bool,String){
        // main cross layer diagonal
        for i in 0...1{
            if A[0][i]==A[6][i+1] && A[6][i+1]==A[12][i+2] && A[12][i+2]==A[18][i+3] && A[0][i] != "n"{
                return (true,A[0][i]);
            }
            else if A[18][i]==A[12][i+1] && A[12][i+1]==A[6][i+2] && A[6][i+2]==A[0][i+3] && A[18][i] != "n"{
                return (true,A[18][i]);
            }
            else if A[24][i]==A[18][i+1] && A[18][i+1]==A[12][i+2] && A[12][i+2]==A[6][i+3] && A[24][i] != "n"{
                return (true,A[24][i]);
            }
            else if A[6][i]==A[12][i+1] && A[12][i+1]==A[18][i+2] && A[18][i+2]==A[24][i+3] && A[6][i] != "n"{
                return (true,A[6][i]);
            }
            else if A[5][i]==A[11][i+1] && A[11][i+1]==A[17][i+2] && A[17][i+2]==A[23][i+3] && A[5][i] != "n"{
                return (true,A[5][i]);
            }
            else if A[23][i]==A[17][i+1] && A[17][i+1]==A[11][i+2] && A[11][i+2]==A[5][i+3] && A[23][i] != "n"{
                return (true,A[23][i]);
            }
            else if A[1][i]==A[7][i+1] && A[7][i+1]==A[13][i+2] && A[13][i+2]==A[19][i+3] && A[1][i] != "n"{
                return (true,A[1][i]);
            }
            else if A[19][i]==A[13][i+1] && A[13][i+1]==A[7][i+2] && A[7][i+2]==A[1][i+3] && A[19][i] != "n"{
                return (true,A[19][i]);
            }
        }
        // no winner found
        return (false,"no winner")
    }
    
    // given a 5 by 5 grid representing a slice of the cube
    // determine whether there exists a winner and who is the winner
    func checkWin(A:[[String]]) -> (Bool,String) {
        // check horizontally
        for subA in A{
            if ((subA[0] == subA[1] || subA[4] == subA[1])  && (subA[1] == subA[2]) && (subA[2] == subA[3])  && subA[1] != "n"){
                return (true,subA[1]);
            }
        }
        // check vertically
        for j in 0..<5{
            if((A[0][j]==A[1][j] || A[4][j]==A[1][j]) && (A[1][j]==A[2][j]) && (A[2][j]==A[3][j]) && (A[1][j] != "n")){
                return (true,A[1][j])
            }
        }
        
        // check diagonally - part one: from upper right corner to bottom left corner
        // left diagonal
        if(A[0][3]==A[1][2] && A[1][2]==A[2][1] && A[3][0]==A[2][1] && A[0][3] != "n"){
            return (true,A[0][3])
        }
            
            // right diagonal
        else if(A[1][4]==A[2][3] && A[2][3]==A[3][2] && A[3][2]==A[4][1] && A[1][4] != "n"){
            return (true,A[1][4])
        }
            
            // middle diagonal
        else if((A[1][3]==A[2][2] && A[2][2]==A[3][1]) && (A[1][3] != "n") && (A[0][4]==A[1][3] || A[4][0]==A[1][3])){
            return (true,A[1][3])
        }
            
            // check diagonally - part one: from upper right corner to bottom left corner
            
            // left diagonal
        else if(A[1][0]==A[2][1] && A[2][1]==A[3][2] && A[3][2]==A[4][3] && A[1][0] != "n"){
            return (true,A[1][0])
        }
            
            // right diagonal
        else if(A[0][1]==A[1][2] && A[1][2]==A[2][3] && A[2][3]==A[3][4] && A[0][1] != "n"){
            return (true,A[0][1])
        }
            
        else if((A[1][1]==A[2][2] && A[2][2]==A[3][3]) && (A[1][1] != "n") && (A[1][1]==A[0][0] || A[1][1]==A[4][4])){
            return (true,A[1][1])
        }
        
        // if arrived here, then definitly no answer has been found
        return (false,"no winner yet")
    }
    // plays sound based on the sound file name string
    func playSound(soundFileName:String) {
        // establish sound url to be played
        let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "wav")
        // load sound via sound url
        audioPlayer = try! AVAudioPlayer(contentsOf: soundURL!)
        // play audio
        audioPlayer.play()
    }
    

    // MARK - Peer to peer delegation methods
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        switch state {
//        case MCSessionState.connected:
//            print("Connected: \(peerID.displayName)")
//
//        case MCSessionState.connecting:
//            print("Connecting: \(peerID.displayName)")
//
//        case MCSessionState.notConnected:
//            print("Not Connected: \(peerID.displayName)")
//        }
        if(state == MCSessionState.connected){
            print("Connected: \(peerID.displayName)")
            DispatchQueue.main.async { // Correct
                self.backBtn.isHidden = true
                self.hostBtn.isHidden = true
                self.joinBtn.isHidden = true
            }
        }
        else if(state == MCSessionState.connecting){
            print("Connecting: \(peerID.displayName)")
        }
        else{
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let RecevedData:Data = data
        // received data
        DispatchQueue.main.async { [unowned self] in let res = String(decoding: RecevedData, as: UTF8.self)
            print("Received Message: " + res)
            self.selectedNode = self.poleArr[Int(res)!]
            self.insertChessOnBoard(sendData:false)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        DispatchQueue.main.async { // Correct
            self.backBtn.isHidden = true
            self.hostBtn.isHidden = true
            self.joinBtn.isHidden = true
        }
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    

    
}
