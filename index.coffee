chalk     = require 'chalk'

##| log - A simple pointer, by default, to console.log
##|
##| You can redefine this in your code if you want to log the output to a database,
##| file or any other tool.
##|

module.exports.log = console.log.bind(console);

##| setTitle - Change the terminal title in iTerm2 (OSX) and Byobu (Linux/OSX)
##| @param title [string] The title for the tab
##|
##| This is a helper function that can be used to set the terminal title.  It works
##| in iTerm2 when running OSX or byobu which is a great way to run scripts remotely
##| for testing purposes.
##|

module.exports.setTitle = (title) ->
    process.stdout.write('\x1b]0;' + title + '\x07');
    process.stdout.write('\x1b]2;' + title + '\x07');

##| reportException - Displays an error message (@see reportError)
##| @param where [string] Text to display before the error message
##| @param e [Error] An exception / Error object
##|
##| Just like reportError except that it ends the program
module.exports.reportException = (where, e)->

    module.exports.reportError where, e
    process.exit(1)
    false

##| reportError - Displays an error message
##| @param where [string] Text to display before the error message
##| @param e [Error] An exception / Error object
##|
module.exports.reportError = (where, e)->

    module.exports.log "-----------------------------------------------------------------------------------------------------"
    module.exports.log chalk.blue "Exception in   : " + chalk.yellow(where)
    if e?
        module.exports.log chalk.blue "Exception text : " + chalk.green(e.toString())

    ##|
    ##|  If the Error has a stack, look through the stack and find the lines that
    ##|  reference local CoffeeScript files.
    ##|
    if e? and e.stack?

        str = e.stack

        ##|
        ##|  RegExp to skip the "co" module as it's pointless in our output
        rePromise1 = new RegExp "node_modules.co.*"

        ##|  RegExp to skip native code in our stack output
        rePromise2 = new RegExp "\\(native\\)"

        ##|
        ##|  RegExp to find local coffeescript files
        reCode     = new RegExp "at([^/]+)\\(*(.*.coffee):([0-9]+):([0-9]+).*", "i"

        ##|  RegExp to remove extra spacing from part of the line
        reNoSpace  = new RegExp "[ \\(]", "g"

        sourceCode = null
        strResult  = ""

        lines = str.split /\n/
        for line in lines

            if rePromise1.test line then continue
            if rePromise2.test line then continue

            m = line.match reCode
            if m?

                fn       = m[1]
                filename = m[2]
                lineNum  = parseInt m[3]
                charNum  = parseInt m[4]

                fn = fn.replace reNoSpace, ""
                displayFilename = filename.replace /^.*\//, ""
                if fn? and fn.length
                    newLine = "  at " + chalk.yellow(fn) + " "
                else
                    newLine = "  "

                newLine += "in " + chalk.red(displayFilename) + ":#{lineNum} +#{charNum}"

                if !sourceCode?
                    sourceCode = fetchSourceCode(filename, lineNum, charNum)
                    line = sourceCode + newLine
                else
                    line = newLine

            strResult += line + "\n"

        module.exports.log chalk.cyan strResult

    module.exports.log "-----------------------------------------------------------------------------------------------------"
    false

##|
##|  Initialize error handlers
##+--------------------------------------------------------------------------------------------
if !module.exports.initialized?
    module.exports.initialized = true

    process.on 'uncaughtException', (err) =>
        module.exports.reportException "Uncaught Exception", err

    process.on 'unhandledRejection', (err) =>
        module.exports.reportException "Unhandled Rejection", err


##|
##|  Read source code file, return the broken bits
fetchSourceCode = (filename, lineNum, charPos) ->

    try
        minLine = lineNum - 3
        maxLine = lineNum + 3

        str = "\n"
        source = fs.readFileSync(filename).toString('utf8')
        cs_lines = source.split '\n'
        for n in [0...cs_lines.length]
            if n >= minLine and n <= maxLine
                strNum = "#{n} |"
                strNum = " " + strNum while strNum.length < 6
                if n == lineNum-1
                    strNum = chalk.bold.white(" > ") + chalk.bold.cyan(strNum);
                else
                    strNum = "   " + strNum

                str += strNum
                if n == lineNum-1
                    str += chalk.bold.gray(cs_lines[n])
                    str += "\n              "
                    for a in [0...charPos]
                        str += " "
                    str += chalk.bold.red("^")
                else
                    str += chalk.gray(cs_lines[n])
                str += "\n"

        str += "\n"
        str

    catch e
        return ""
