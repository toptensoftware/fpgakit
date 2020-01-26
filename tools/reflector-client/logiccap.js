let SerialPort = require('serialport');
let BitPacket = require('./BitPacket');
let VcdFileWriter = require('./VcdFileWriter');

let portName = "COM4";
let baudRate = 115200;
let receiveBitCount = 50;
let accessors = {
    "s_calib_done": [49, 49],
    "s_ram_write" : [48, 48],
    "s_ram_read" : [47, 47],
    "s_ram_wait" : [46, 46], 
    "s_ram_addr" : [45, 16],
    "s_ram_din" : [15, 8],
    "s_ram_dout" : [7, 0],
}

// Process accessors
for (let k in accessors)
{
    accessors[k] = {
        from: accessors[k][0],
        to: accessors[k][1],
        width: accessors[k][0] - accessors[k][1] + 1
    }
}

// open serial port
let serialPort = new SerialPort(portName, { baudRate : baudRate});
serialPort.on('data', onReceive);

// allocate receive buffer
let receiveBufferUsed = -1;
let receiveBuffer = Buffer.alloc(BitPacket.byteCountForBitWidth(receiveBitCount));
let receivedBuffers = [];

let idleTimer;
function startIdleTimer()
{
    // Clear old timer
    if (idleTimer)
         clearTimeout(idleTimer);

    // Start new timer
    idleTimer = setTimeout(() => {
        writeVcdFile();
    }, 1000);
}

// Handler for data received via serial port
function onReceive(data)
{
    for (let i=0; i<data.length; i++)
    {
        // Start of a packet?
        if ((data[i] & 0x80) != 0)
        {
            receiveBufferUsed = 0;
        }
        else if (receiveBufferUsed < 0)
        {
            // Haven't received start of packet byte yet
            continue;
        }

        // Copy byte to the buffer
        receiveBuffer[receiveBufferUsed++] = data[i];

        // Has the entire packet been received?
        if (receiveBufferUsed == receiveBuffer.length)
        {
            // Queue it
            receivedBuffers.push(receiveBuffer);

            // Reset idle timer
            startIdleTimer();

            // Start a new buffer
            receiveBufferUsed = -1;
            receiveBuffer = Buffer.alloc(BitPacket.byteCountForBitWidth(receiveBitCount));
        }
    }
}

function writeVcdFile()
{
    // Take ownership of current packet list
    let buffers = receivedBuffers;
    receivedBuffers = [];

    // Create Vcd writer
    let w = new VcdFileWriter("logiccap.vcd");

    // Workin bit packet
    let bp = new BitPacket(receiveBitCount);

    // Setup headers
    w.setCreator("LogicCap v1.0");
    w.setTimeScale("1 us");
    w.addModule("signals");
    for (let a of Object.keys(accessors))
    {
        let acc = accessors[a];

        if (acc.width == 1)
            acc.signal = w.addSignal(a, "reg 1", "U");
        else
            acc.signal = w.addSignal(a, `reg ${acc.width}`, "b" + "U".repeat(acc.width));
    }

    w.closeHeaders();

    // Process all packets
    for (let i=0; i<buffers.length; i++)
    {
        w.setTime(i+1);

        bp._buffer = buffers[i];

        // Write signals
        for (let a of Object.keys(accessors))
        {
            let acc = accessors[a];
            
            if (acc.width == 1)
                w.setSignal(acc.signal, bp.getBits(acc.from, acc.to));
            else
                w.setSignal(acc.signal, "b" + bp.getBits(acc.from, acc.to));
        }
    }

    w.close();

    console.log(`VCD file written. ${buffers.length} samples.`);
}