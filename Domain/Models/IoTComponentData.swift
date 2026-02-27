#if os(iOS)
import Foundation

struct IoTComponent: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ComponentCategory
    let description: String
    let useCase: String
    let iconName: String
    let componentImageName: String
    // Rich detail fields
    let specs: [String: String]
    let pinout: [PinInfo]
    let connectionGuide: String
    let relatedComponents: [String]
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: IoTComponent, rhs: IoTComponent) -> Bool { lhs.id == rhs.id }
}

struct PinInfo: Identifiable, Hashable {
    let id = UUID()
    let pin: String
    let label: String
    let description: String
}

enum ComponentCategory: String, CaseIterable {
    case microcontroller = "Microcontroller"
    case sensor = "Sensor"
    case actuator = "Actuator"
    case network = "Network/Comm"
}

struct IoTComponentsDatabase {
    static let shared = IoTComponentsDatabase()
    
    let components: [IoTComponent] = [
        // MARK: - Microcontrollers
        IoTComponent(
            name: "ESP32",
            category: .microcontroller,
            description: "A powerful, low-cost microchip with built-in Wi-Fi and dual-mode Bluetooth. It features a dual-core Xtensa LX6 processor running up to 240 MHz.",
            useCase: "Perfect for IoT edge devices, connected smart home hubs, and wireless sensor nodes. Used when wireless connectivity is mandatory.",
            iconName: "cpu",
            componentImageName: "esp32_component",
            specs: [
                "CPU": "Dual-core Xtensa LX6 @ 240 MHz",
                "RAM": "520 KB SRAM",
                "Flash": "4 MB (expandable)",
                "Wi-Fi": "802.11 b/g/n",
                "Bluetooth": "BLE 4.2 + Classic",
                "GPIO": "34 programmable pins",
                "ADC": "12-bit, 18 channels",
                "Operating Voltage": "3.3V (5V tolerant I/O)"
            ],
            pinout: [
                PinInfo(pin: "3V3", label: "3.3V Power", description: "3.3V regulated power output for sensors"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground reference"),
                PinInfo(pin: "GPIO2", label: "Built-in LED", description: "Onboard LED, also used for boot mode"),
                PinInfo(pin: "GPIO21", label: "SDA (I2C)", description: "I2C data line for sensors like MPU6050"),
                PinInfo(pin: "GPIO22", label: "SCL (I2C)", description: "I2C clock line"),
                PinInfo(pin: "GPIO18", label: "SCLK (SPI)", description: "SPI clock for displays & memory"),
                PinInfo(pin: "GPIO23", label: "MOSI (SPI)", description: "SPI Master Out Slave In"),
                PinInfo(pin: "GPIO19", label: "MISO (SPI)", description: "SPI Master In Slave Out"),
                PinInfo(pin: "GPIO1/3", label: "UART TX/RX", description: "Default serial communication pins"),
                PinInfo(pin: "EN", label: "Enable/Reset", description: "Pull LOW to reset the chip")
            ],
            connectionGuide: "1. Power ESP32 via USB-C or 5V → VIN pin (onboard regulator steps to 3.3V).\n2. Connect sensors to 3V3 and GND first.\n3. For I2C sensors: SDA → GPIO21, SCL → GPIO22.\n4. For SPI devices: MOSI→GPIO23, MISO→GPIO19, SCLK→GPIO18, CS→any free GPIO.\n5. Program using Arduino IDE with ESP32 board package or VS Code + PlatformIO.\n6. Upload via USB; hold BOOT button if device doesn't enter programming mode automatically.",
            relatedComponents: ["DHT11 Temp/Humidity", "MPU6050 Gyro/Accel", "Relay Module", "Servo Motor SG90"]
        ),
        
        IoTComponent(
            name: "Arduino Uno",
            category: .microcontroller,
            description: "An open-source microcontroller board based on the ATmega328P. It has 14 digital I/O pins, 6 analog inputs, a 16 MHz crystal oscillator, USB connection, and a reset button.",
            useCase: "Great for beginners, prototyping physical computing projects, and controlling basic sensors/motors. The most popular entry point into embedded systems.",
            iconName: "memorychip",
            componentImageName: "arduino_uno_component",
            specs: [
                "CPU": "ATmega328P @ 16 MHz",
                "Flash": "32 KB",
                "SRAM": "2 KB",
                "EEPROM": "1 KB",
                "Digital I/O": "14 pins (6 PWM)",
                "Analog Input": "6 pins (10-bit ADC)",
                "Operating Voltage": "5V",
                "Input Voltage": "7–12V (barrel jack)"
            ],
            pinout: [
                PinInfo(pin: "5V", label: "5V Power", description: "Regulated 5V power output"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground reference"),
                PinInfo(pin: "A0–A5", label: "Analog Input", description: "10-bit ADC channels for sensors"),
                PinInfo(pin: "D2–D13", label: "Digital I/O", description: "General purpose digital pins"),
                PinInfo(pin: "D3,5,6,9,10,11", label: "PWM Output", description: "Pulse Width Modulation for motor/servo control"),
                PinInfo(pin: "D0/D1", label: "UART RX/TX", description: "Hardware serial pins"),
                PinInfo(pin: "A4/A5", label: "SDA/SCL (I2C)", description: "I2C communication pins"),
                PinInfo(pin: "D10–12", label: "SS/MOSI/MISO (SPI)", description: "SPI hardware bus pins"),
                PinInfo(pin: "RESET", label: "Reset", description: "Resets the microcontroller")
            ],
            connectionGuide: "1. Connect Arduino via USB to your computer for power and programming.\n2. For sensors needing 5V: use the 5V and GND header pins.\n3. For analog sensors (like LDR, potentiometer): connect to A0–A5 pins.\n4. For digital sensors (like DHT11): connect signal → any D-pin, add pull-up if needed.\n5. For servos: PWM signal → D9 or D10, power from external 5V (not Arduino 5V).\n6. Upload sketches using Arduino IDE. Set board to 'Arduino Uno' and select correct COM port.",
            relatedComponents: ["Servo Motor SG90", "Ultrasonic HC-SR04", "LDR Photoresistor", "DHT11 Temp/Humidity"]
        ),
        
        IoTComponent(
            name: "Raspberry Pi 4",
            category: .microcontroller,
            description: "A small, affordable single-board computer with a powerful ARM Cortex-A72 CPU, USB 3.0, and Gigabit Ethernet. Runs full Linux OS.",
            useCase: "Used for running full operating systems, computer vision (like OpenCV), complex AI processing, and heavy web servers. The powerhouse of hobbyist SBCs.",
            iconName: "macmini.fill",
            componentImageName: "raspberry_pi_component",
            specs: [
                "CPU": "Quad-core ARM Cortex-A72 @ 1.8 GHz",
                "RAM": "2/4/8 GB LPDDR4X",
                "USB": "2× USB 3.0 + 2× USB 2.0",
                "Display": "2× micro-HDMI (4K@60fps)",
                "GPIO": "40-pin header",
                "Network": "Gigabit Ethernet + Wi-Fi 5",
                "Bluetooth": "5.0",
                "Power": "5V 3A via USB-C"
            ],
            pinout: [
                PinInfo(pin: "Pin 1", label: "3.3V Power", description: "3.3V power output (max 50 mA)"),
                PinInfo(pin: "Pin 2", label: "5V Power", description: "5V power from USB supply (pass-through)"),
                PinInfo(pin: "Pin 6", label: "Ground", description: "Common ground"),
                PinInfo(pin: "GPIO2/3", label: "SDA/SCL (I2C)", description: "Hardware I2C bus 1"),
                PinInfo(pin: "GPIO14/15", label: "UART TX/RX", description: "Hardware serial (Mini UART)"),
                PinInfo(pin: "GPIO10/9/11", label: "MOSI/MISO/SCLK", description: "SPI bus 0"),
                PinInfo(pin: "GPIO18", label: "PCM CLK / PWM0", description: "Hardware PWM output"),
                PinInfo(pin: "GPIO17-27", label: "General GPIO", description: "Configurable input/output pins")
            ],
            connectionGuide: "1. Insert a microSD card with Raspberry Pi OS image.\n2. Connect via USB-C (5V/3A) for power — use official PSU to avoid brownouts.\n3. For GPIO sensors: use 3.3V pin only (GPIO is NOT 5V tolerant!).\n4. Use a level shifter when connecting 5V Arduino sensors to Pi GPIO.\n5. Enable I2C/SPI via: sudo raspi-config → Interface Options.\n6. Access remotely via SSH: ssh pi@<ip-address> after enabling SSH in raspi-config.",
            relatedComponents: ["MPU6050 Gyro/Accel", "Ultrasonic HC-SR04", "Relay Module"]
        ),
        
        // MARK: - Sensors
        IoTComponent(
            name: "Ultrasonic HC-SR04",
            category: .sensor,
            description: "An ultrasonic distance sensor that measures distance by sending 40 kHz sound waves and timing the echo. Measurement range: 2 cm to 400 cm.",
            useCase: "Used for obstacle avoidance in robots, measuring tank water levels, and presence detection in smart parking systems.",
            iconName: "wave.3.right",
            componentImageName: "ultrasonic_hcsr04",
            specs: [
                "Operating Voltage": "5V DC",
                "Current Consumption": "15 mA",
                "Ranging Distance": "2 cm – 400 cm",
                "Accuracy": "±3 mm",
                "Measuring Angle": "15°",
                "Trigger Input": "10 µs TTL pulse",
                "Echo Output": "TTL PWM signal"
            ],
            pinout: [
                PinInfo(pin: "VCC", label: "5V Power", description: "Connect to Arduino 5V output"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground"),
                PinInfo(pin: "TRIG", label: "Trigger Input", description: "Send 10µs HIGH pulse to start measurement → connect to any digital pin"),
                PinInfo(pin: "ECHO", label: "Echo Output", description: "Returns pulse width proportional to distance → connect to digital input pin")
            ],
            connectionGuide: "1. VCC → Arduino 5V, GND → Arduino GND.\n2. TRIG → Arduino D9 (or any digital output pin).\n3. ECHO → Arduino D10 (or any digital input pin).\n⚠️ For Raspberry Pi: ECHO outputs 5V — use a voltage divider (10kΩ + 20kΩ) to reduce to 3.3V before connecting to GPIO.\n4. Formula: Distance (cm) = Echo pulse duration (µs) / 58\n5. Code: pulse LOW TRIG → wait 2µs → pulse HIGH for 10µs → pulse LOW → read ECHO duration.",
            relatedComponents: ["ESP32", "Arduino Uno", "Servo Motor SG90"]
        ),
        
        IoTComponent(
            name: "DHT11 Temp/Humidity",
            category: .sensor,
            description: "A basic, low-cost digital temperature and humidity sensor using a capacitive humidity sensor and a thermistor. Outputs a calibrated digital signal.",
            useCase: "Used in smart weather stations, greenhouse monitoring, and indoor climate control systems.",
            iconName: "thermometer.sun",
            componentImageName: "dht11_sensor",
            specs: [
                "Operating Voltage": "3.3V – 5V",
                "Temperature Range": "0°C – 50°C (±2°C)",
                "Humidity Range": "20% – 90% RH (±5%)",
                "Sampling Rate": "1 Hz (once per second)",
                "Signal": "Single-wire digital",
                "Body Size": "15.5mm × 12mm × 5.5mm"
            ],
            pinout: [
                PinInfo(pin: "VCC", label: "Power (3.3–5V)", description: "Connect to 3.3V or 5V"),
                PinInfo(pin: "DATA", label: "Signal Output", description: "Single-wire serial data — connect to digital pin"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground")
            ],
            connectionGuide: "1. VCC → 3.3V or 5V, GND → GND.\n2. DATA → Arduino D7 (or any free digital pin).\n3. Add a 10kΩ pull-up resistor between DATA and VCC (required for signal integrity).\n4. Use the DHT library in Arduino IDE: #include <DHT.h>.\n5. Read interval must be ≥ 1 second between readings.\n6. For ESP32: same wiring, but use 3.3V. Use the DHTesp library for better compatibility.",
            relatedComponents: ["ESP32", "Arduino Uno", "Relay Module"]
        ),
        
        IoTComponent(
            name: "MPU6050 Gyro/Accel",
            category: .sensor,
            description: "A 6-axis MotionTracking device combining a 3-axis gyroscope and a 3-axis accelerometer on one chip. Uses I2C interface and includes onboard Digital Motion Processor (DMP).",
            useCase: "Crucial for drone stabilization, robotic balancing, device orientation tracking, and kinetic interaction analysis — the core sensor behind Kineprint.",
            iconName: "gyroscope",
            componentImageName: "mpu6050_sensor",
            specs: [
                "Operating Voltage": "3.3V – 5V (onboard regulator)",
                "Gyroscope Range": "±250/±500/±1000/±2000 °/s",
                "Accelerometer Range": "±2/±4/±8/±16 g",
                "ADC Resolution": "16-bit",
                "Interface": "I2C (400 kHz Fast Mode)",
                "I2C Address": "0x68 (AD0 LOW) or 0x69 (AD0 HIGH)",
                "Current": "3.9 mA (active)"
            ],
            pinout: [
                PinInfo(pin: "VCC", label: "Power (3.3–5V)", description: "Power supply (module has 3.3V regulator)"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground"),
                PinInfo(pin: "SDA", label: "I2C Data", description: "Connect to Arduino A4 or ESP32 GPIO21"),
                PinInfo(pin: "SCL", label: "I2C Clock", description: "Connect to Arduino A5 or ESP32 GPIO22"),
                PinInfo(pin: "INT", label: "Interrupt Output", description: "Optional: signals when new data is ready — connect to a digital interrupt pin"),
                PinInfo(pin: "AD0", label: "I2C Address Select", description: "LOW = 0x68 address, HIGH = 0x69 (allows two MPU6050 on same bus)")
            ],
            connectionGuide: "1. VCC → 3.3V (Arduino) or 3.3V/5V (ESP32 module), GND → GND.\n2. SDA → A4 (Arduino) or GPIO21 (ESP32).\n3. SCL → A5 (Arduino) or GPIO22 (ESP32).\n4. No pull-up resistors needed (module has them built in).\n5. Install 'MPU6050' library by Electronic Cats in Arduino IDE.\n6. Use I2CScanner sketch to confirm address (should be 0x68).\n7. Calibrate offsets before use: run MPU6050_calibration sketch, save offsets to code.",
            relatedComponents: ["ESP32", "Arduino Uno", "Raspberry Pi 4"]
        ),
        
        IoTComponent(
            name: "LDR Photoresistor",
            category: .sensor,
            description: "A light-dependent resistor whose resistance decreases when light intensity increases. Resistance ranges from ~1MΩ (dark) to ~1kΩ (bright light).",
            useCase: "Automated streetlights, solar tracking systems, and detecting day/night cycles in weather stations.",
            iconName: "sun.max.fill",
            componentImageName: "ldr_sensor",
            specs: [
                "Resistance (Dark)": "~1 MΩ",
                "Resistance (10 Lux)": "~8–20 kΩ",
                "Resistance (Bright)": "~1 kΩ",
                "Peak Wavelength": "560 nm (green-yellow light)",
                "Response Time": "20 ms (rise), 30 ms (fall)",
                "Operating Temp": "-30°C to +70°C"
            ],
            pinout: [
                PinInfo(pin: "Leg 1", label: "One terminal", description: "Connect to VCC through a 10kΩ fixed resistor to form a voltage divider"),
                PinInfo(pin: "Leg 2", label: "Other terminal", description: "Connect to GND; the midpoint of the divider goes to analog input")
            ],
            connectionGuide: "1. Wire as a voltage divider: VCC → 10kΩ resistor → LDR → GND.\n2. Connect the midpoint (between 10kΩ and LDR) to Arduino A0.\n3. analogRead(A0) returns higher values in bright light, lower in dark.\n4. Convert to lux using calibration or lookup tables.\n5. Use in comparators (LM393) to get a digital HIGH/LOW threshold trigger.\n6. For ESP32: connect midpoint to any ADC pin (GPIO32–GPIO39 preferred for stable ADC2).",
            relatedComponents: ["Arduino Uno", "ESP32", "Relay Module"]
        ),
        
        IoTComponent(
            name: "PIR Motion Sensor",
            category: .sensor,
            description: "A Passive Infrared sensor that measures infrared light radiating from objects in its field of view. Detects motion by sensing changes in IR levels.",
            useCase: "Security alarms, automatic lighting systems, and human presence detection in smart buildings.",
            iconName: "person.wave.2.fill",
            componentImageName: "pir_sensor",
            specs: [
                "Operating Voltage": "5V – 12V",
                "Detection Range": "up to 7 meters",
                "Detection Angle": "110° cone",
                "Output Signal": "Digital HIGH (3.3V) on motion",
                "Delay Time": "Adjustable 5s–300s",
                "Sensitivity": "Adjustable via onboard trimmer",
                "Quiescent Current": "~50 µA"
            ],
            pinout: [
                PinInfo(pin: "VCC", label: "Power (5–12V)", description: "DC power supply (5V from Arduino works)"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground"),
                PinInfo(pin: "OUT", label: "Signal Output", description: "Digital HIGH when motion is detected → connect to digital input pin")
            ],
            connectionGuide: "1. VCC → Arduino 5V, GND → GND, OUT → D7 (or any digital pin).\n2. Allow 30–60 seconds warm-up time after powering on (sensor calibrates).\n3. Two potentiometers on the module: left adjusts sensitivity, right adjusts hold time.\n4. Use digitalRead() to poll for HIGH state.\n5. For low-power designs: connect OUT to an interrupt pin (D2 or D3) and use attachInterrupt().\n6. Avoid placing near heat sources (radiators, sunlight) to prevent false triggers.",
            relatedComponents: ["Arduino Uno", "ESP32", "Relay Module"]
        ),
        
        // MARK: - Actuators
        IoTComponent(
            name: "Servo Motor SG90",
            category: .actuator,
            description: "A small, high-precision rotary actuator controlled via PWM signal. Rotates 0°–180°. Includes metal gears in the MG90S variant for extra torque.",
            useCase: "Controlling robot arms, steering mechanisms in RC cars, opening/closing smart locks, and camera pan-tilt mounts.",
            iconName: "arrow.triangle.2.circlepath",
            componentImageName: "sg90_servo",
            specs: [
                "Operating Voltage": "4.8V – 6V",
                "Stall Torque": "1.8 kg·cm at 4.8V",
                "Speed": "0.1 sec/60° at 4.8V",
                "Rotation": "0° to 180°",
                "PWM Frequency": "50 Hz (20 ms period)",
                "Pulse Width": "1 ms = 0°, 1.5 ms = 90°, 2 ms = 180°",
                "Weight": "9 g"
            ],
            pinout: [
                PinInfo(pin: "Red wire", label: "VCC (4.8–6V)", description: "⚠️ Do NOT power from Arduino 5V header; use external 5V supply for multiple servos"),
                PinInfo(pin: "Brown/Black wire", label: "Ground", description: "Share GND with Arduino GND"),
                PinInfo(pin: "Orange/Yellow wire", label: "PWM Signal", description: "Connect to Arduino PWM pin (D9, D10, or D11)")
            ],
            connectionGuide: "1. NEVER power servos from Arduino's 5V pin for real projects — it causes reset/brownouts.\n2. Use an external 5V/1A supply; connect its GND to Arduino GND (common ground).\n3. Signal wire (orange) → Arduino D9.\n4. In Arduino IDE: #include <Servo.h> → myServo.attach(9) → myServo.write(90).\n5. For ESP32: use ESP32Servo library. Attach to any GPIO (recommended: 12–19).\n6. Calibrate endpoints if servo doesn't reach full 0° or 180° — adjust min/max pulse in attach().",
            relatedComponents: ["Arduino Uno", "ESP32", "Stepper Motor"]
        ),
        
        IoTComponent(
            name: "DC Motor",
            category: .actuator,
            description: "An electric machine that converts DC electrical energy into rotational mechanical energy. Speed controlled by voltage/PWM; direction by polarity reversal.",
            useCase: "Driving wheels of robot rovers, cooling fans, conveyor belts, and propellers.",
            iconName: "fan.fill",
            componentImageName: "dc_motor",
            specs: [
                "Operating Voltage": "3V – 12V (typical hobby motors)",
                "No-load Current": "~70 mA at 6V",
                "Stall Current": "~400 mA at 6V",
                "No-load Speed": "~9000 RPM at 6V",
                "Shaft Diameter": "2 mm standard"
            ],
            pinout: [
                PinInfo(pin: "Terminal A", label: "Motor Lead +", description: "Polarity sets direction: A→+ means clockwise"),
                PinInfo(pin: "Terminal B", label: "Motor Lead −", description: "Reverse A/B connection reverses rotation direction")
            ],
            connectionGuide: "1. Never connect DC motor directly to Arduino GPIO — motors draw too much current and cause resets.\n2. Use an L298N or L293D motor driver between Arduino and motor.\n3. L298N: IN1→D8, IN2→D9 (direction), ENA→D10 (PWM speed control).\n4. Power L298N with motor battery (6–12V), connect L298N GND to Arduino GND.\n5. Add a 0.1µF ceramic capacitor across motor terminals to suppress EMI noise.\n6. Speed control: analogWrite(10, 128) = 50% speed. analogWrite(10, 255) = 100%.",
            relatedComponents: ["Arduino Uno", "ESP32", "Relay Module"]
        ),
        
        IoTComponent(
            name: "Relay Module",
            category: .actuator,
            description: "An electrically operated switch that allows a small microcontroller signal to safely control high-power circuits — AC or DC regardless of voltage.",
            useCase: "Switching AC appliances (lamps, water pumps, heaters). Ideal wherever you need MCU-level logic to control mains voltage.",
            iconName: "switch.2",
            componentImageName: "relay_module",
            specs: [
                "Coil Voltage": "5V DC",
                "Coil Current": "~70–80 mA",
                "Max AC Load": "250V AC / 10A",
                "Max DC Load": "30V DC / 10A",
                "Contact Types": "NO (Normally Open), NC (Normally Closed), COM (Common)",
                "Trigger Logic": "Active LOW (some modules: Active HIGH)"
            ],
            pinout: [
                PinInfo(pin: "VCC", label: "5V Power", description: "Power for relay coil"),
                PinInfo(pin: "GND", label: "Ground", description: "Common ground"),
                PinInfo(pin: "IN", label: "Signal Input", description: "Connect to Arduino digital pin; LOW usually activates the relay"),
                PinInfo(pin: "COM", label: "Common AC/DC", description: "One side of the load circuit"),
                PinInfo(pin: "NO", label: "Normally Open", description: "Open when relay is off; closed when relay is activated — use for loads you want OFF by default"),
                PinInfo(pin: "NC", label: "Normally Closed", description: "Closed when relay is off — use for fail-safe circuits")
            ],
            connectionGuide: "1. VCC → Arduino 5V, GND → GND, IN → D7.\n2. For AC appliances: connect LIVE wire through COM→NO, and return NEUTRAL directly.\n3. In code: digitalWrite(7, LOW) activates relay; HIGH releases it (for active-LOW modules).\n4. ⚠️ Always work with AC power when the circuit is UNPLUGGED. Use a properly rated enclosure.\n5. Add a flyback diode (1N4007) across the relay coil for protection if not on a module.\n6. For multiple relays: use a relay driver board; each relay needs ~80mA which may exceed Arduino's total 200mA limit.",
            relatedComponents: ["ESP32", "Arduino Uno", "DC Motor"]
        ),
        
        IoTComponent(
            name: "Stepper Motor",
            category: .actuator,
            description: "A brushless DC motor that divides a full rotation into discrete equal steps (typically 200 steps = 1.8° each). Extremely precise position control without feedback sensors.",
            useCase: "3D printers (Kinetic Printing!), CNC machines, precise robotic positioning, and automated camera sliders.",
            iconName: "gearshape.2.fill",
            componentImageName: "stepper_motor",
            specs: [
                "Step Angle": "1.8° per step (200 steps/revolution)",
                "Voltage": "5V (28BYJ-48) or 12V (NEMA17)",
                "Phase Current": "1.5A (NEMA17 typical)",
                "Holding Torque": "0.45 N·m (NEMA17)",
                "Driver Required": "A4988 or DRV8825 for NEMA17",
                "Motor Type": "4-wire bipolar (NEMA17)"
            ],
            pinout: [
                PinInfo(pin: "A1/A2", label: "Coil A leads", description: "Motor coil A windings (typically black & green or red & blue)"),
                PinInfo(pin: "B1/B2", label: "Coil B leads", description: "Motor coil B windings"),
                PinInfo(pin: "A4988 STEP", label: "Step signal", description: "Each HIGH pulse advances motor by one step → connect to Arduino digital pin"),
                PinInfo(pin: "A4988 DIR", label: "Direction signal", description: "HIGH = clockwise, LOW = counter-clockwise"),
                PinInfo(pin: "A4988 EN", label: "Enable (active LOW)", description: "Pull LOW to enable driver; HIGH disables (motor freewheels)")
            ],
            connectionGuide: "1. Use A4988 driver module between Arduino and motor.\n2. A4988 STEP → Arduino D3, DIR → D4, EN → D5.\n3. Motor coils A → A4988 outputs 1A & 2A, coils B → 1B & 2B.\n4. A4988 VMOT → 12V supply, GND → common GND.\n5. A4988 VDD → Arduino 5V (logic supply).\n6. Add 100µF electrolytic capacitor on VMOT/GND to protect driver from inductive spikes.\n7. Set A4988 current limit via VREF trimmer: VREF = I_max × 8 × R_sense (R_sense ≈ 0.1Ω → 1.5A = 1.2V).\n8. Microstepping: MS1/MS2/MS3 pins select 1,2,4,8,16 microsteps for smoother motion.",
            relatedComponents: ["Arduino Uno", "ESP32", "Servo Motor SG90"]
        )
    ]
    
    func getComponents(by category: ComponentCategory) -> [IoTComponent] {
        return components.filter { $0.category == category }
    }
}
#endif
