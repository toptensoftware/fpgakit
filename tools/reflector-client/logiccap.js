let SerialPort = require('serialport');
let BitPacket = require('./BitPacket');
let VcdFileWriter = require('./VcdFileWriter');
var spawn = require('child_process').spawn;

// Default options
let options = {
    port: "/dev/ttyACM1",
    baud: 115200,
    bitCount: -1,
    fields: [],
    sampleRate: 100000000n,
    autoView: -1,
    vcdfile: "logiccap.vcd"
}

// Process command line args...
for (let i=2; i<process.argv.length; i++)
{
    let arg = process.argv[i];
    if (arg.startsWith("--"))
    {
        let parts = arg.substr(2).split(":");
        switch (parts[0].toLowerCase())
        {
            case "port":
                options.port = parts[1];
                break;

            case "baud":
                options.baud = Number(parts[1]);
                break;

            case "rate":
                options.sampleRate = BigInt(parts[1]);
                break;

            case "bitcount":
                options.bitCount = Number(parts[1]);
                break;

            case "vcdfile":
                options.vcdfile = parts[1];
                break;
    
            case "autoview":
                options.autoView = Number(parts[1]);
                break;
        }
    }
    else
    {
        let signals = arg.split(",");
        for (let s of signals)
        {
            let m = s.match(/^(.*)\[(\d+)\.\.(\d+)\]$/);
            if (m)
            {
                options.fields.push({
                    name: m[1],
                    from: Number(m[2]),
                    to: Number(m[3]),
                    width: Number(m[2]) - Number(m[3]) + 1
                });
                continue;
            }

            m = s.match(/^(.*)\[(\d+)\]$/);
            if (m)
            {
                options.fields.push({
                    name: m[1],
                    width: Number(m[2]),
                });
                continue;
            }

            options.fields.push({
                name: s,
                width: 1,
            })
        }
    }
}

// Fill out missing bit positions
let bitPos = 0;
for (let i=options.fields.length - 1; i>=0; i--)
{
    let a = options.fields[i];
    if (a.from === undefined)
    {
        a.to = bitPos;
        a.from = bitPos + a.width - 1;
    }
    bitPos = a.from + 1;
}

// Dump and sum total width
let totalWidth = 0;
for (let i=0; i<options.fields.length; i++)
{
    let a = options.fields[i];
    totalWidth += a.width;
    if (a.width > 1)
        console.log(`${a.name}[${a.from} downto ${a.to}] (${a.width} bits)`);
    else
        console.log(`${a.name}`);
}
console.log(`Total bit count: ${totalWidth}`);
console.log();

// Check bit count matches
if (options.bitCount < 0)
{
    options.bitCount = totalWidth;
}
else if (options.bitCount != totalWidth)
{
    console.log(`Bit count mismatch: --bitcount:${options.bitCount} doesn't match total width ${totalWidth}`);
    process.exit(7);
}

// open serial port
let serialPort = new SerialPort(options.port, { baudRate : options.baud});
serialPort.on('data', onReceive);

// allocate receive buffer
let receiveBufferUsed = -1;
let receiveBuffer = Buffer.alloc(BitPacket.byteCountForBitWidth(options.bitCount));
let receivedBuffers = [];

let idleTimer;
function startIdleTimer()
{
    // Clear old timer
    if (idleTimer)
        clearTimeout(idleTimer);
    else
        console.log("Capturing...");

    // Start new timer
    idleTimer = setTimeout(() => {
        writeVcdFile();
        idleTimer = null;
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
            receiveBuffer = Buffer.alloc(BitPacket.byteCountForBitWidth(options.bitCount));
        }
    }
}

function writeVcdFile()
{
    // Take ownership of current packet list
    let buffers = receivedBuffers;
    receivedBuffers = [];

    // Don't bother if less that the required sample
    if (options.autoView > 0 && buffers.length < options.autoView)
    {
        console.log(`Discarding spurious ${buffers.length} samples`);
        console.log();
        return;
    }

    // Work out fs per second
    let fsPerSample = 1000000000000000n / options.sampleRate;

    // Create Vcd writer
    let w = new VcdFileWriter(options.vcdfile);

    // Workin bit packet
    let bp = new BitPacket(options.bitCount);

    // Setup headers
    w.setCreator("LogicCap v1.0");
    w.setTimeScale("1 fs");
    w.addModule("signals");

    for (let i=0; i<options.fields.length; i++)
    {
        let f = options.fields[i];

        if (f.width == 1)
            f.signal = w.addSignal(f.name, "reg 1", "U");
        else
            f.signal = w.addSignal(f.name, `reg ${f.width}`, "b" + "U".repeat(f.width));
    }

    w.closeHeaders();

    // Process all packets
    for (let i=0; i<buffers.length; i++)
    {
        w.setTime(fsPerSample * BigInt(i+1));

        bp._buffer = buffers[i];

        // Write signals
        for (let j=0; j<options.fields.length; j++)
        {
            let f = options.fields[j];
            
            if (f.width == 1)
                w.setSignal(f.signal, bp.getBits(f.from, f.to));
            else
                w.setSignal(f.signal, "b" + bp.getBits(f.from, f.to));
        }
    }

    w.setTime(buffers.length + 1);
    w.close();

    console.log(`VCD file written. ${options.vcdfile} - ${buffers.length} samples.`);
    console.log();

    spawn('gtkwave', [`--save=${options.vcdfile}.gtkw`, options.vcdfile], {
        detached: true
    });
}