#if os(iOS)
import Foundation

@available(iOS 16.0, *)
struct IoTComponent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ComponentCategory
    let description: String
    let useCase: String
    let iconName: String
}

@available(iOS 16.0, *)
enum ComponentCategory: String, CaseIterable {
    case microcontroller = "Microcontroller"
    case sensor = "Sensor"
    case actuator = "Actuator"
    case network = "Network/Comm"
}

@available(iOS 16.0, *)
struct IoTComponentsDatabase {
    static let shared = IoTComponentsDatabase()
    
    let components: [IoTComponent] = [
        // Microcontrollers
        IoTComponent(name: "ESP32", category: .microcontroller, description: "A powerful, low-cost microchip with built-in Wi-Fi and dual-mode Bluetooth. It features a dual-core processor.", useCase: "Perfect for IoT edge devices, connected smart home hubs, and wireless sensor nodes. Used when wireless connectivity is mandatory.", iconName: "cpu"),
        IoTComponent(name: "Arduino Uno", category: .microcontroller, description: "An open-source microcontroller board based on the ATmega328P. It has 14 digital I/O pins and 6 analog inputs.", useCase: "Great for beginners, prototyping physical computing projects, and controlling basic sensors/motors.", iconName: "memorychip"),
        IoTComponent(name: "Raspberry Pi 4", category: .microcontroller, description: "A small, affordable single-board computer with a powerful ARM Cortex-A72 CPU, USB 3.0, and Gigabit Ethernet.", useCase: "Used for running full operating systems, computer vision (like OpenCV), complex AI processing, and heavy web servers.", iconName: "macmini.fill"),
        
        // Sensors
        IoTComponent(name: "Ultrasonic HC-SR04", category: .sensor, description: "An ultrasonic distance sensor that measures distance by sending out sound waves and timing how long they take to bounce back.", useCase: "Used for obstacle avoidance in robots, measuring tank water levels, and presence detection.", iconName: "wave.3.right"),
        IoTComponent(name: "DHT11 Temp/Humidity", category: .sensor, description: "A basic, low-cost digital temperature and humidity sensor. It uses a capacitive humidity sensor and a thermistor.", useCase: "Used in smart weather stations, greenhouse monitoring, and indoor climate control systems.", iconName: "thermometer.sun"),
        IoTComponent(name: "MPU6050 Gyro/Accel", category: .sensor, description: "A 6-axis MotionTracking device that combines a 3-axis gyroscope and a 3-axis accelerometer.", useCase: "Crucial for drone stabilization, robotic balancing, device orientation tracking, and kinetic interaction.", iconName: "gyroscope"),
        IoTComponent(name: "LDR Photoresistor", category: .sensor, description: "A light-dependent resistor whose resistance decreases when light intensity increases.", useCase: "Automated streetlights, solar tracking systems, and detecting day/night cycles.", iconName: "sun.max.fill"),
        IoTComponent(name: "PIR Motion Sensor", category: .sensor, description: "A Passive Infrared sensor that measures infrared light radiating from objects in its field of view.", useCase: "Security alarms, automatic lighting, and human presence detection.", iconName: "person.wave.2.fill"),
        
        // Actuators
        IoTComponent(name: "Servo Motor SG90", category: .actuator, description: "A small, high-precision rotary actuator that allows for precise control of angular position (usually 0 to 180 degrees).", useCase: "Controlling robot arms, steering mechanisms in RC cars, and opening/closing smart locks.", iconName: "arrow.triangle.2.circlepath"),
        IoTComponent(name: "DC Motor", category: .actuator, description: "An electric machine that converts direct current electrical energy into mechanical energy.", useCase: "Driving the wheels of a robotic rover, running cooling fans, or powering conveyor belts.", iconName: "fan.fill"),
        IoTComponent(name: "Relay Module", category: .actuator, description: "An electrically operated switch that allows a low-power signal (like from an Arduino) to control a high-power circuit.", useCase: "Switching on/off AC appliances like lamps, heaters, and water pumps safely.", iconName: "switch.2"),
        IoTComponent(name: "Stepper Motor", category: .actuator, description: "A brushless DC electric motor that divides a full rotation into a number of equal steps. Extremely precise.", useCase: "Used in 3D printers (Kinetic Printing!), CNC machines, and precise positioning robots.", iconName: "gearshape.2.fill")
    ]
    
    func getComponents(by category: ComponentCategory) -> [IoTComponent] {
        return components.filter { $0.category == category }
    }
}
#endif
