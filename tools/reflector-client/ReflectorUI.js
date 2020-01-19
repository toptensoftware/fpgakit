let events = require('events');
const ansiEscapes = require('ansi-escapes');
const readline = require('readline');

// Creates a simple non-scrolling console based user-interface
// 
// To use:
// 1. Create an instance: 
//       let ui = new ReflectorUI()
// 2. Hook up an event handler for typed lines:
//       ui.on('line', (line) => {});
// 3. Call run and await:
//       await ui.run();
// 4. Call showStatus at any time to update what's 
//    shown in the first lines of the screen
// 5. Call console.log in 'line' event handler to write
//    response for that command
// run() will complete when user types "exit" or presses Ctrl+C
class ReflectorUI extends events.EventEmitter
{
    // Constructor
    constructor()
    {
        super();
    }

    // Show status message
    showStatus(msg)
    {
        process.stdout.write(ansiEscapes.cursorHide);
        process.stdout.write(ansiEscapes.cursorSavePosition);
        process.stdout.write(ansiEscapes.cursorTo(0,0));
        process.stdout.write(msg);
        process.stdout.write(ansiEscapes.cursorRestorePosition);
        process.stdout.write(ansiEscapes.cursorShow);
    }

    // Run the UI
    async run()
    {
        // Resolver for shutdown
        let finished;

        // Clear screen and make room for status line
        process.stdout.write(ansiEscapes.clearScreen);
        process.stdout.write("\n\n");

        // Setup Readline
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            prompt: "> ",
        });

        // Do initial prompt
        process.stdout.write(ansiEscapes.cursorTo(0,6));
        rl.prompt();

        // Type line handler
        rl.on('line', (line) => {
        
            // Quit?
            if (line.trim() == "exit")
            {
                rl.close();
                return;
            }
            
            // Display command result
            process.stdout.write(ansiEscapes.cursorTo(0,2));
            process.stdout.write(ansiEscapes.eraseDown);

            // Generate event
            this.emit("line", line);
        
            // Prompt again
            process.stdout.write(ansiEscapes.cursorTo(0,6));
            rl.prompt();
        });

        // Close handler, resolve waiting promise
        rl.on('close', () => {
            finished();
        });

        // Wait for it to finish
        await (new Promise((resolve, reject) => { finished = resolve}));

        // Done!
        process.stdout.write("\n\n");
    }    
}

module.exports = ReflectorUI;
