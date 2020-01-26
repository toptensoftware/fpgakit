let Reflector = require('./Reflector');
let ReflectorUI = require('./ReflectorUI');

// This is a simple sandbox example for the Reflector component.
// 
// See the following project for the FPGA counter-part to this example
//
//         ./boards/mimasv2/reflector-tx-rx
//
// How to use:
//
//  1. Run `npm install` to get dependent modules installed
//  2. Upload the `reflector-tx-rx` design to the FPGA
//  3. Update the portName in the options below to match your setup
//      (/dev/ttyACM1 is the default port name under linux.   For Windows
//       use the Device Manager to find the COM port number).  You can
//       also leave portName blank to run without an attached FPGA.
//  4. Run: `node sandbox`
//  5. Monitor activity in displayed UI. (Press buttons on FPGA board
//         to see their state reflected in the sandbox UI)
//  6. Press Ctrl+C or type exit when finished
//  7. View the generated .vcd file by running `gtkwave sandbox.vcd`

(async function()
{
    // Reflector establishes the connection with the FPGA over serial port
    let reflector = new Reflector({
        receiveBitCount: 16,
        sendBitCount: 21,
        portName: "COM4",
        portOptions: { 
            baudRate: 115200 
        },
        receiveAccessors: {                 // Declare bit fields from FPGA
            "i_buttons": [ 15, 12 ],
            "i_counter": [ 7, 0 ],
        },
        sendAccessors: {                    // Declare bit fields to FPGA
            "o_leds": [ 7, 0 ],
            "o_counter": [ 19, 8 ],
        },
        vcdFile: "sandbox.vcd",
    });

    // Open connection
    await reflector.open();

    // The accessors declared above are now available as properties
    // For sendAccessors, changes will be automatically sent to the FPGA
    // For receiveAccessors, they'll update when those signals in the FPGA change
    reflector.o_leds = 0x01;

    // Use a timer to change things.
    let timer = setInterval(function() {

        // Counter
        reflector.o_counter++;

        // Rotate LEDs
        reflector.o_leds = ((reflector.o_leds << 1) | (reflector.o_leds >> 7)) & 0xFF;

    }, 500);

    // This event notifies us that either something sent or received changed
    // Note the use of reflector.formatXxx() methods to get values and format 
    // for display
    reflector.on('change', function() {
        let msg =  `  to FPGA: counter: ${reflector.formatHex("o_counter")} leds: ${reflector.formatLeds("o_leds")}\n`;
            msg += `from FPGA: counter: ${reflector.formatHex("i_counter")} buttons: ${reflector.formatLeds("i_buttons")}`;
        ui.showStatus(msg);
    });

    // This is a simple console UI that displays a status string at the top 
    // of the screen and provides a prompt where commands can be entered
    let ui = new ReflectorUI();
    ui.on('line', function(line) {
        console.log("You typed:", line);
    });
    await ui.run();

    // Clean up
    clearInterval(timer);
    await reflector.close();
})();
