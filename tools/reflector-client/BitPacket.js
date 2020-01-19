// Represents a reflector bit packet
// 
// BitPackets are a sequence of bytes representing a fixed number of 
// bits.  They match how the data is transmitted serially:
//
// First byte in packet has MSB set and the first 7 data bits
// Remaining bytes have MSB clear and each contains the next 7 data bits
// Bytes are transmitted LSB first.  ie: first byte = data(6 downto 0),
// second byte = data(13 downto 7) etc...
class BitPacket
{
    // Constructs a new bit packet of specified width (in bits)
    // with an optional notify callback for when value changed
    // Instead of width you can also pass a string with the bit values
    // to initialize.  Width will be the length of the string
    constructor(width, notify)
    {
        if (typeof(width) === "string")
        {
            this._width = width.length;
            this._buffer = Buffer.alloc(BitPacket.byteCountForBitWidth(this._width));
            this.bits = width;
        }
        else
        {
            this._width = width;
            this._buffer = Buffer.alloc(BitPacket.byteCountForBitWidth(this._width));
            this._buffer[0] = 0x80;
        }
        if (notify)
            this.notify = notify;
    }

    // width property
    get width() 
    { 
        return this._width 
    };

    // Get the bits in the specified bit range as a string
    getBits(msb, lsb)
    {
        // Check bit range
        if (msb < 0 || msb > this.width ||
            lsb < 0 || lsb > this.width ||
            msb < lsb)
            throw new Error("invalid bit range");

        return this.bits.substr(this.width - msb-1, msb - lsb + 1);
    }
    
    // Set the bits in a specified bit range from a string
    setBits(msb, lsb, value)
    {
        // Check bit range
        if (msb < 0 || msb > this.width ||
            lsb < 0 || lsb > this.width ||
            msb < lsb)
            throw new Error("invalid bit range");

        // Check length matches
        if (msb - lsb + 1 != value.length)
            throw new Error("value length doesn't match bit range");

        let oldBits = this.bits;
        this.bits = `${oldBits.substr(0, this.width - msb - 1)}${value}${oldBits.substr(this.width - lsb)}`;
    }

    // Get the entire bit range as a string
    get bits() 
    { 
        return this.toString() 
    };

    // Set the entire bit range from a string
    set bits(value) 
    {
        if (value.length != this._width)
            throw new Error(`Bit count mismatch (expected ${this._width}, not ${value.length}`);

        // Encode
        value = value.padStart(this._buffer.length * 7, '0');
        for (let i=0; i<this._buffer.length; i++)
        {
            let subbits = value.substr(-7 - i * 7, 7);
            this._buffer[i] = parseInt(subbits, 2) | (i==0 ? 0x80 : 0);
        }

        if (this.notify)
            this.notify();
    }

    // Get the entire bit range as a string
    toString()
    {
        let bits = "";
        for (let i=this._buffer.length-1; i>=0; i--)
        {
            bits += (this._buffer[i] & 0x7f).toString(2).padStart(7, '0');
        }

        return bits.substr(-this._width);
    }

    // For a give number of bits, work out how many packet bytes are
    // required to store it.
    static byteCountForBitWidth(bitWidth)
    {
        return Math.floor((bitWidth + 6) / 7);
    }

    // Helper to enumerate the bit positions of a bit range within a packet
    // Each enumerated value returns
    //   - byte           the byte number within the packet
    //   - shiftByte      how much the byte needs to be shifted to the right
    //                    to move the bits into the least significant position
    //   - mask           how to mask the shift byte to get just the bits in the range
    //   - shiftPacket    how much to shift the masked value to the left to position
    //                    in correctly in the final extract bit range value.
    static *getBitPositions(msb, lsb)
    {
        let startBytePos = Math.floor(lsb / 7);
        let endBytePos = Math.floor(msb / 7);
        let shiftPacket = 0;
        for (let i=startBytePos; i<=endBytePos; i++)
        {
            let startBitPos = i == startBytePos ? (lsb % 7) : 0;
            let endBitPos = i == endBytePos ? (msb % 7) : 6;

            yield { 
                byte: i, 
                shiftByte: startBitPos, 
                mask: Math.pow(2, endBitPos - startBitPos + 1) - 1, 
                shiftPacket
            }

            shiftPacket += endBitPos - startBitPos + 1;
        }
    }

    // Build a get accessor function body that
    // can extract a value from a specified bit range
    // and specified BitPacket object reference
    static buildGetAccessorBody(packet, msb, lsb)
    {
        let fnGet = "";
        for (let i of BitPacket.getBitPositions(msb,lsb))
        {
            if (fnGet.length > 0)
                fnGet += " | ";
            
            let el = `buffer[${i.byte}]`;
            if (i.shiftByte != 0)
                el = `(${el} >> ${i.shiftByte})`;
            if (i.mask != 0x7F || i.byte == 0)
                el = `(${el} & 0x${i.mask.toString(16).toUpperCase()})`
            if (i.shiftPacket != 0)
                el = `(${el} << ${i.shiftPacket})`;
            fnGet += el;
        }
        return `    let buffer = ${packet}._buffer; return ${fnGet};`;
    }
    
    // Build a set accessor function body that
    // can set the value of a specified bit range
    // and specified BitPacket object reference
    static buildSetAccessorBody(packet, msb, lsb, name)
    {
        let fnSet =  `let buffer = ${packet}._buffer;\n`;

        for (let i of BitPacket.getBitPositions(msb,lsb))
        {
            let oldValueMasked;
            if ((i.mask << i.shiftByte) != 0x7f)
                oldValueMasked = `(buffer[${i.byte}] & 0x${(0xFF ^ (i.mask << i.shiftByte)).toString(16).toUpperCase()}) | `;
            else
                oldValueMasked = i.byte == 0 ? `0x80 | ` : "";
        
            let el = `value`;
            if (i.shiftPacket != 0)
                el = `(${el} >> ${i.shiftPacket})`;
            if (i.mask != 0xFF)
                el = `(${el} & 0x${i.mask.toString(16).toUpperCase()})`;
            if (i.shiftByte != 0)
                el = `(${el} << ${i.shiftByte})`;
        
            fnSet += `    buffer[${i.byte}] = ${oldValueMasked}${el};\n`
        }

        fnSet += `    if (${packet}.notify) ${packet}.notify()`;
        return fnSet;
    }
}


module.exports = BitPacket;