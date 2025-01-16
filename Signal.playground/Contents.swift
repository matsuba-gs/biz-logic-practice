import UIKit
import Foundation // Timerクラスを使用するために必要なモジュール
import PlaygroundSupport // Playground上でTimerクラスを機能させるために必要なモジュール

// デフォルトだとTimerクラスを継続的に処理させることが出来ないため、フラグを変更
PlaygroundPage.current.needsIndefiniteExecution = true

// 信号機クラス
class Signal {
    enum SignalColor {
        case green
        case yellow
        case red
    }
    enum SignalState {
        case on       // 点灯
        case blinking // 点滅
        case off      // 消灯
    }
    
    var name :String
    var color :SignalColor?
    var state :SignalState
    var limit: Int // 今の状態における維持時間
    
    var greenTime: Int      // sec
    let yellowTime: Int = 2 // sec
    let redTime: Int = 3    // sec
    
    var intersection: Intersection?
    
    init(name: String, greenTime time: Int) {
        self.name = name
        self.color = .red // 初期値は赤信号
        self.state = .on
        self.limit = self.redTime
        self.greenTime = time
    }
    
    func setIntersection(intersection: Intersection) {
        self.intersection = intersection
    }
    
    func isTimeout(count: Int) -> Bool {
        return self.limit <= count ? true : false
    }
 
    // 点灯
    func steadyOn(color: SignalColor, time: Int) {
        self.change(color: color, state: .on, time: time)
    }
    
    // 点滅
    func blink(color: SignalColor, time: Int) {
        self.change(color: color, state: .blinking, time: time)
    }
    
    // 消灯
    func turnOff(time: Int) {
        self.change(color: nil, state: .off, time: time)
    }
    
    private func change(color: SignalColor?, state: SignalState, time: Int = 0) {
        self.color = color
        self.state = state
        self.limit = time
        
        intersection?.update()
    }
    
    func getColor() -> SignalColor? {
        return self.color
    }
    
    func getSignal() -> String {
        switch self.color {
        case .green:
            return "\(self.name): 🟢⚫️⚫️"
        case .yellow:
            return "\(self.name): ⚫️🟡⚫️"
        case .red:
            return "\(self.name): ⚫️⚫️🔴"
        default:
            return "\(self.name): ⚫️⚫️⚫️"
        }
    }
}

class SidewalkSignal: Signal {
    // TODO: 歩道の信号
}

// 交差点クラス
class Intersection {
    var signalA: Signal
    var signalB: Signal
    var currentSignal: Signal
    
    var timer: Timer?
    var count: Int = 0
    var roundLimit: Int
    var round: Int = 0
    
    init(greenTimeA: Int, greenTimeB: Int, roundLimit: Int) {
        signalA = Signal(name: "Signal A", greenTime: greenTimeA)
        signalB = Signal(name: "Signal B", greenTime: greenTimeB)
        currentSignal = signalA
        self.roundLimit = roundLimit
    }
    
    func start() {
        // オブザーバー的な
        signalA.setIntersection(intersection: self)
        signalB.setIntersection(intersection: self)
        
        // signalAが青、signalBが赤でスタート
        currentSignal.steadyOn(color: .green, time: currentSignal.greenTime)
        
        // 任意の箇所でTimerクラスを使用して1秒毎にcountup()メソッドを実行させるタイマーをセット
        timer = Timer.scheduledTimer(
            timeInterval: 1, // タイマーの実行間隔を指定(単位はn秒)
            target: self, // ここは「self」でOK
            selector: #selector(countup), // timeInterval毎に実行するメソッドを指定
            userInfo: nil, // ここは「nil」でOK
            repeats: true // 繰り返し処理を実行したいので「true」を指定
        )
    }

    // Timerクラスに設定するメソッドは「@objc」キワードを忘れずに付与する
    @objc private func countup() {
        // countの値をインクリメントする
        count += 1
        
        if !currentSignal.isTimeout(count: count) {
            print(".")
            return
        }
        
        // タイムアウトしたら次の色に切り替え
        switch currentSignal.color {
        case .green:
            currentSignal.blink(color: .yellow, time: currentSignal.yellowTime)
        case .yellow:
            currentSignal.steadyOn(color: .red, time: currentSignal.redTime)
        case .red:
            if currentSignal === signalB {
                round += 1
                
                // 指定回数ローテーションしたら停止
                if roundLimit <= round {
                    timer?.invalidate()
                    return
                }
            }
            
            // 信号切り替え
            currentSignal = currentSignal === signalA ? signalB : signalA
            currentSignal.steadyOn(color: .green, time: currentSignal.greenTime)
        default:
            // タイマーを止める
            timer?.invalidate()
        }
        
        count = 0
    }
    
    func update() {
        print("\(signalA.getSignal())   \(signalB.getSignal())")
    }
}


let intersection = Intersection(greenTimeA: 15, greenTimeB: 10, roundLimit: 3)
intersection.start()
