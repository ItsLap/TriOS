
-- To make your own apps, you can either run this program once (it will create a folder from which you can use pastebin/ even edit in to make apps). Or you can right click on the screen (not on an app and when the program is running) and you can choose App from the drop down menu.
-- This has alot of features and configurable options e.g app icon size or even the colour theme, so be sure to look below at the variables and config to your liking.

-- =============================== User Config Below ==============================

local folderDir = "TriangleOS"
local osVersion = "0.1"
-- Defining folderDir as the folder you keep your apps in and the osVersion is the version of the os you are using

local editFile = ".TriOSEditFile"
local runFile = ".TriOSRunFile"
local compressedFileExtension = ".tricmprs"
-- Defining the temporary files for compression and decompression aswell as the extension it uses

local appMaxHeight = 3
local appMaxNameLength = 11
-- appMaxHeight is the height of the icons on the page and namelength will not only concatenate the apps to that value, it will also be the width of the icons on the page

local pageNumber = 1
-- Setting the page number that the program loads with

local colours = {
  app = colors.blue,
  folder = colors.lightBlue,
  addNew = colors.cyan,
  page = colors.green,
  dropMenuTop = colors.gray,
  dropMenuBottom = colors.lightGray,
  infoText = colors.lightBlue,
  decoText = colors.yellow,
  searchBackground = colors.cyan,
  filterBackground = colors.purple,
  filterOn = colors.red,
  filterOff = colors.lime
}
-- Colour theme for the apps and the page icons

-- ============================== End Of User Config ==============================

if fs.exists(folderDir) and not fs.isDir(folderDir) then

  error("folderDir variable is assigned to an already existing file.")
end
-- Seeing if the folderDir is a file already on the local computer

if not fs.exists(folderDir) then

  fs.makeDir(folderDir)
end
-- Making the folderDir if its not already made

os.run({}, "rom/programs/clear")
term.setTextColor(colours.infoText)
print("Setting things up...")
-- The boot up message

os.run({}, "update.lua", osVersion)

local maxX,maxY = term.getSize()
-- Getting the max dimensions of the screen

local searchFilterName = "Filter"
-- The word that is displayed where the filter is

local activeFilterTags = {}
-- Defining a table that i will be keeping the active filter tags in

local terminate = false
-- Defining the terminate variable as false to use later on

local clipboard = nil
-- Defining the clipBoard variable as nil for use later on

local addNewVisible = true
-- Setting the AddNew icon to visible

local oldPullEvent = os.pullEvent
os.pullEvent = os.pullEventRaw
-- Defining os.pullEvent as os.pullEventRaw so that the read() function will use raw instead of the normal os.pullEvent

local dropMenuPower = {
  Shell = function() terminate = true end,
  Restart = function() os.reboot() end,
  Shutdown = function() os.shutdown() end
}
-- Functions that are called when the user left clicks the power button on the top right

local dropMenuFilterTags = {
  Folders = function() checkFilterTags("Folders") end,
  Files = function() checkFilterTags("Files") end,
  Hidden = function() checkFilterTags("Hidden") end,
  AddNew = function() checkAddNew() end
}
-- Tag Filters that will be displayed visually

local dropMenuFolders = {
  Delete = function(name) fs.delete(appFolder .. "/" .. name) end,
  Copy = function(name) clipboard = {appFolder, name} end
}
-- Functions that are called when the user right clicks an option for a folder in the drop menu

local dropMenuApps = {
  Delete = function(name) fs.delete(appFolder .. "/" .. name) end,
  Copy = function(name) clipboard = {appFolder, name} end,
  Edit = function(name)

    local tempFile = fs.open(editFile,"w")
    tempFile.write(decompress(appFolder .. "/" .. name))
    tempFile.close()
    -- Preparing the temporary file with the file to edit's contents

    os.run({}, "rom/programs/edit " .. editFile)
    -- Editting the temporary file instead of the file from the file system

    local currFile = fs.open(appFolder .. "/" .. name, "w")
    currFile.write(compress(editFile))
    currFile.close()
    -- Writing the compressed version of the file to the file system

    fs.delete(editFile)
  end,
  Rename = function(name)

    clearScreen()
    term.setTextColor(colours.infoText)
    print("Enter the new name of the app below or press enter again to not rename:")
    -- Prompting the user for an input

    term.setTextColor(colors.white)
    local newName = read() .. compressedFileExtension
    -- Getting user input

    term.setTextColor(colours.infoText)
    -- Setting the text colour so i don't have to set it in the if statements

    if not fs.exists(appFolder .. "/" .. newName) then
      -- Checking if the name doesn't already exist in the current directory

      fs.move(appFolder .. "/" .. name, appFolder .. "/" .. newName)
      print("File successfully renamed")
      sleep(1)
      -- If the directory already doesn't have an app/folder of that name then it will rename the app

    elseif newName == "" then
      -- Checking if they have put anything in the read()

      print("New name not set")
      sleep(1)
      -- If they haven't put anything in the read() then it won't try to set a new name
    else

      print("Name already exists in current directory")
      sleep(1)
      -- Informing the user that the name they chose already exists
    end
  end
}
-- Functions that are called when the user right clicks an option for an app in the drop menu

local dropMenuOpts = {
  App = function()

    clearScreen()
    Triangle()
    -- Loading the OS version

    term.setCursorPos(1,2)
    term.setTextColor(colours.infoText)
    print("Enter name of new app below or leave blank to not create:")
    term.setTextColor(colors.white)
    -- Prompting the user to enter the new app name

    local appName = wordSplit(read())
    -- Immediately splitting the user input at the spaces

    if appName[1] and not fs.exists(appFolder .. "/" .. appName[1]) then
      -- Checking if the user inputted a app name and seeing if it exists already or not

      os.run({}, "rom/programs/edit " .. editFile)
      -- Edit the new file

      if fs.exists(editFile) then
        -- Seeing if the user has made any changes to the editted temporary file

        local userFile = fs.open(appFolder .. "/" .. appName[1] .. compressedFileExtension, "w")
        userFile.write(compress(editFile))
        userFile.close()
        -- If the user has made changes to the temp file, it will compress the file and write the compressed version to the file system

        fs.delete(editFile)
        -- Deleting the temporary file
      end

    elseif appName[1] and fs.exists(appName[1]) then

      term.setTextColor(colours.infoText)
      print("Name already exists")
      sleep(1)
      -- Notifying the user that the name already exists
    else

      term.setTextColor(colours.infoText)
      print("No new app created")
      sleep(1)
      -- If the user didn't enter something then it gives a message, sleeps (so the user can see the message) and then goes back to the app page
    end
  end,

  Folder = function()

    clearScreen()
    Triangle()
    -- Loading the OS version

    term.setCursorPos(1,2)
    term.setTextColor(colours.infoText)
    print("Enter the name of the new folder below or leave blank to not create:")
    term.setTextColor(colors.white)
    -- Prompting the user for the new folder name

    local folderName = wordSplit(read())
    -- Immediately splitting the user input into a table

    if folderName[1] and not fs.exists(folderName[1]) then
      -- Checking if the user inputted a app name and seeing if it exists already or not

      fs.makeDir(appFolder .. "/" .. folderName[1])
      -- Makes the new folder

    elseif folderName[1] and fs.exists(folderName[1]) then
      -- Catches if the user has inputted an folder name that already exists

      term.setTextColor(colours.infoText)
      print("Name already exists")
      sleep(1)
      -- Notifying the user that the name they have inputted already exists
    else

      term.setTextColor(colours.infoText)
      print("No new folder created")
      sleep(1)
      -- If the user didn't enter something then it gives a message, sleeps (so the user can see the message) and then goes back to the app page
    end
  end
}
-- The drop menu you see if you don't right click on an app

if http then
  -- First seeing if you have the http api enabled before doing anything

  local testFile = http.get("http://pastebin.com/raw.php?i=DSMHN2iF")

  if testFile then

    testPaste = testFile.readAll()
    testFile.close()
    -- Reading a test file that i have made just to make sure you can access pastebin.com
  end

  if testPaste == "test" then
    -- Seeing if the test paste has "test" in it's contents (should always return test)

    dropMenuOpts.Pastebin = function()
      -- Adding the Pastebin option to the dropMenuOpts

      clearScreen()
      Triangle()
      -- Loading the OS version

      term.setCursorPos(1,2)
      term.setTextColor(colours.infoText)
      print("Enter the pastebin url after http://pastebin.com/ below or leave blank to not create:")
      term.setTextColor(colors.white)
      -- Prompting the user for the pastebin url

      local pasteURL = wordSplit(read())
      -- Immediately splitting the user input into a table

      if pasteURL[1] then
        -- Seeing if the user has entered anything

        local pasteFile = http.get("http://pastebin.com/raw.php?i=" .. textutils.urlEncode(pasteURL[1]))
        local pasteContents = pasteFile.readAll()
        pasteFile.close()
        -- Getting the user's file from pastebin

        if pasteContents then
          -- Checking if the pastebin url is valid and is actually a file

          term.setTextColor(colours.infoText)
          print("Enter the file name you want to download as:")
          term.setTextColor(colors.white)
          -- Prompting the user for the file name to download as

          local pasteFile = wordSplit(read())
          -- Getting the file name and splitting the user input into a table

          if pasteFile[1] and not fs.exists(appFolder .. "/" .. pasteFile[1]) then
            -- Checking if the user has entered anything and also checking if the file already exists or not

            local file = fs.open(appFolder .. "/" .. pasteFile[1], "w")
            file.write(pasteContents)
            file.close()
            -- If everything goes well it will make the file

            term.setTextColor(colours.infoText)
            print("Successfully made file")
            sleep(1)
            -- Letting the user know it was successful

          elseif pasteFile[1] and fs.exists(appFolder .. pasteFile[1]) then
            -- Catching if the use has entered a file name but it already exists

            term.setTextColor(colours.infoText)
            print("File already exists. Press Y to force or enter another key to not force:")
            local event, key, held = os.pullEvent("key")
            -- Seeing if the user wants to force make the file

            if key == 21 then
              -- In this case 21 is the key Y

              local file = fs.open(appFolder .. "/" .. pasteFile[1], "w")
              file.write(pasteContents)
              file.close()
              -- Writing over the old file with the newly downloaded file

              term.setTextColor(colours.infoText)
              print("Successfully force made file")
              sleep(1)
              -- Letting the use know that the file was replaced
            else

              term.setTextColor(colours.infoText)
              print("Aborted making the file")
              sleep(1)
              -- If the user hasn't entered a valid name e.g either spaces or nothing
            end
          end
        else

          term.setTextColor(infoText)
          print("Invalid paste URL")
          sleep(1)
          -- Letting the user know that the pastebin url's contents aren't there e.g invalid url
        end
      else

        term.setTextColor(colours.infoText)
        print("No url specified")
        sleep(1)
        -- If no input was given it returns to the app page
      end
    end
  end
end
-- First checking if the user can access pastebin.com and if they can then will add the pastebin option to dropMenuOpts

local filterTags = {

  Folders = function (tab)

    local out = {}
    -- Defining the out table to be later returned

    for i=1, #tab do
      -- Iterating for the amount of values the tab table has

      if not fs.isDir(appFolder .. "/" .. tab[i]) then

        table.insert(out,#out+1,tab[i])
      end
      -- Removing the folders from the table
    end

    return out
    -- Returning the filtered table
  end,

  Files = function (tab)

    local out = {}
    -- Defining the out table to be later returned

    for i=1,#tab do
      -- Iterating for the amount of values the tab table has

      if fs.isDir(appFolder .. "/" .. tab[i]) then

        table.insert(out,#out+1,tab[i])
      end
      -- Removing the files from the table
    end

    return out
    -- Returning the filtered table
  end,

  Hidden = function (tab)

    local out = {}
    -- Defining the out table to be later returned

    for i=1,#tab do
      -- Iterating for the amount of values the tab table has

      if tab[i]:sub(1,1) ~= "." then

        table.insert(out,#out+1,tab[i])
      end
      -- Adding the Filtered Files to the out table
    end

    return out
    -- Returning the filtered table
  end,

  AddNew = function(tab) return tab end
}
-- The tags that the directory can be filtered for

local numFilterTags = 0

for key,val in pairs(dropMenuFilterTags) do

  numFilterTags = numFilterTags + 1
end
-- Getting the number of filter tags for later use

for key,val in pairs(dropMenuFilterTags) do
  -- Iterating for the number of key/value pairs in dropMenuFilterTags

  if key == "Hidden" then
    -- Seeing if the key is "Hidden"

    activeFilterTags[key] = true
    -- Setting the key to activated
  else

    activeFilterTags[key] = false
    -- Setting the key to deactivated
  end
end
-- Making the activeFilterTags table

local directoryBeforeSearch
-- Declaring directoryBeforeSearch variable here so i can compare with it later on

function checkFilterTags(name)
  if activeFilterTags[name] then
    -- Seeing what the status of the filter was before

    activeFilterTags[name] = false
    -- Removing the filter from the active tags list
  else

    activeFilterTags[name] = true
    pageNumber = 1
    -- Adding the filter to the tags list aswell as resetting the page number so it won't error
  end
end

function checkAddNew()
  if activeFilterTags.AddNew then
    -- Seeing what the status of AddNew was before

    activeFilterTags.AddNew = false
    addNewVisible = true
    -- Removing AddNew from the active tags list and setting it's visibility to true
  else

    activeFilterTags.AddNew = true
    pageNumber = 1
    addNewVisible = false
    -- Adding AddNew to the tags list aswell as resetting the page number so it won't error and setting it's visibility to false
  end
end

function fileSort(fileTab,appFolder,searchWord)

  local out = {}
  local files = {}

  for key,val in pairs(activeFilterTags) do
    -- iterating over the activeFilterTags table

    if val then

      fileTab = filterTags[key](fileTab)
      -- Assigning fileTab to the new table that the filterTags tag will return
    end
  end
  -- Applying any filters that the user has put on

  directoryBeforeSearch = fileTab
  -- Defining directoryBeforeSearch as fileTab before it has been filtered with the search word

  for i=1,#fileTab do

    local searchedName = fileTab[i]:lower():sub(1,#fileTab[i]-#compressedFileExtension)
    -- Defining the searchedName variable for files

    if fs.isDir(appFolder .. "/" .. fileTab[i])  and fileTab[i]:lower():find(searchWord) then
      -- First iterating for the amount of items in the fileTab table and then checking if its a directory and putting it in the appropriate table

      table.insert(out,#out+1,fileTab[i])

    elseif searchedName:find(searchWord) then
      if fileTab[i]:lower():sub(#fileTab[i]-#compressedFileExtension+1,#fileTab[i]) ~= compressedFileExtension then

        local tempVarFile = fs.open(appFolder .. "/" .. fileTab[i],"r")
        local tempVarFileContents = tempVarFile.readAll()
        tempVarFile.close()

        local tempFile = fs.open(editFile,"w")
        tempFile.write(tempVarFileContents)
        tempFile.close()

        local actualFile = fs.open(appFolder .. "/" .. fileTab[i],"w")
        actualFile.write(compress(editFile))
        actualFile.close()

        fs.delete(editFile)

        fs.move(appFolder .. "/" .. fileTab[i], appFolder .. "/" .. fileTab[i] .. compressedFileExtension)
      end

      table.insert(files,#files+1,fileTab[i])
    end
  end
  -- Sorting the fileTab table into the files and out table

  for i=1,#files do

    table.insert(out,#out+1,files[i])
  end
  -- merging the files table with the out table

  if addNewVisible then
    -- Checking if the visible var is true

    out[#out+1] = "+"
    -- Making the addNew icon
  end

  return out
  -- Returning the sorted table
end
-- Function for sorting files and folders so that the folders will appear first

function fileToLines(file)

  local read = fs.open(file,"r")
  local lines = {}

  while true do

    local currLine = read.readLine()

    if currLine then

      table.insert(lines, currLine)
    else

      break
    end
  end
  -- While loop to keep on adding the current line to a table and if theres no current line, it will break

  read.close()
  return lines
end
-- Function to return a table of the lines of a file

function wordSplit(string)

  local out = {}

  for word in string:gmatch("%S+") do
    -- Splitting the string at the spaces

    table.insert(out, word)
    -- Inserting the value into a table
  end

  return out
  -- Returning the table
end
-- Receives a string and returns a table that's the string split at the spaces

function fillArea(tab)

  term.setBackgroundColor(tab[5])
  -- Setting the right background colour

  for i=0,tab[4]-tab[2] do
    -- Running for how many rows there are (indexes 2,4 == y values and indexes 1,3 == x values in the table)

    local j = 0

    while j <= tab[3]-tab[1] do
      -- I use a while loop here because i iterate up with variable amounts

      term.setCursorPos(tab[1]+j,tab[2]+i)
      -- Positioning the cursor for the next string whether it be a space or the word

      if tab[6] and math.floor(j-((tab[3]-tab[1])/2)+#tab[6]/2) == 0 and math.floor(i-(tab[4]-tab[2])/2) == 0 then
        -- If statement seeing whether the iterators have hit the place where it should be writing the word out

        term.write(tab[6])
        j = j + #tab[6]
        -- Only runs when the above if statement has found the place where the word will be centered
      else

        j = j + 1
        term.write(" ")
        -- Writing " " so the background text colour is visible
      end
    end
  end
end
-- Defining the function for filling an area of the screen with a word centered in it

function checkNum(num)

  local out = ""

  while num > 254 do

    out = out .. string.char(0)
    num = num - 254
  end
  -- While to iterate when num is bigger than 254

  if num >= 13 then num = num + 1 end
  -- Making sure num isn't byte 13

  return out .. string.char(num)
  -- Returning the bytes instead of the number.
end
-- Function that compression uses, if the number given in the arguments is bigger than 254 it will keep on adding the byte 0 to the return

function compress(fileName)

  local lines = fileToLines(fileName)
  -- Splitting the file into it's lines in a table
  local outTable = {{}}

  for line=1,#lines do

    local spaces = 0
    local word = ""
    outTable[line+1] = {}

    local function sortWord(word)
      if #word > 0 then

        local wordFound = false

        for i=1,#outTable[1] do
          -- Iterating over the first index of outTable

          if outTable[1][i] == word then
            -- Checking if the word already exists or not

            table.insert(outTable[line+1],i+3)
            wordFound = true
            break
          end
        end

        if not wordFound then

          table.insert(outTable[1],word)
          table.insert(outTable[line+1],#outTable[1]+3)
        end
        -- Adding the word to the index if it hasn't been found

      end
    end
    -- Function to add any new words to the index

    local function sortSpaces(spaces)
      if spaces > 0 then

        if spaces > 1 then
          -- Checking if the number of spaces is bigger than 1 so it can add a different byte depending on if it is or not

          table.insert(outTable[line+1],2)
          table.insert(outTable[line+1],spaces)
        else

          table.insert(outTable[line+1],3)
        end
      end
    end
    -- Function to handle spaces in the file

    local currLine = ""

    for i=1,#lines[line] do
      -- For to handle the entire compression to convert the file into bytes

      local currChar = lines[line]:sub(i,i)

      if currChar == " " then
        -- A crude way to split up the lines into words and spaces

        spaces = spaces + 1
        sortWord(word)
        word = ""
      else

        word = word .. currChar
        sortSpaces(spaces)
        spaces = 0
      end
    end

    sortWord(word)
    sortSpaces(spaces)
  end

  local outString = ""

  for i=1,#outTable do
    -- For loop to combine the outTable into an output string

    for j=1,#outTable[i] do
      if i == 1 then
        if #outString > 0 then outString = outString .. " " end

        outString = outString .. outTable[i][j]
      else

        outString = outString .. checkNum(outTable[i][j])
      end
    end

    if i == 1 then
      -- Adding the new line character to the end of the line. The index is always at line 1 so i choose to add a \n to the end of line 1

      outString = outString .. "\n"
    else

      outString = outString .. string.char(1)
    end
  end

  return outString
end
-- The compression function

function decompress(fileName)

  local lines = fileToLines(fileName)
  -- Splitting the file into it's lines in a table

  local index = wordSplit(lines[1])
  -- Seperating the index table from the body table

  local body = {}
  table.remove(lines,1)

  for line=1,#lines do
    -- For to convert the compressed file into it's original lines and where the indexes should go

    if line > 1 then

      table.insert(body,10)
    end
    -- Inserting the character 10 every time the file goes onto a new line. This is because character 10 actually is the new line character

    for i=1,#lines[line] do
      -- For loop to convert the bytes into the corresponding indexes

      local indexNum = string.byte(lines[line]:sub(i))

      if indexNum >= 13 then

        indexNum = indexNum - 1
      end

      table.insert(body,indexNum)
    end
  end

  local counter = 1
  local fullFile = ""

  while counter < #body do
    -- While loop to convert the indexes into the corresponding words (aparts from the special characters)

    if body[counter] == 0 then
      -- Checking if the current index is 0 and then converting it into it's actual index (because 0 means it's bigger than 254)

      local multiples = 0

      while body[counter] == 0 do

        counter = counter + 1
        multiples = multiples + 254
      end
      -- Adding up the multiples of 254

      fullFile = fullFile .. index[body[counter] + multiples-3]
      -- Inserting the corresponding word with the full index from adding the multiples and the current index

    elseif body[counter] == 1 then
      -- Seeing if the current index is 1 which is the new line character

      fullFile = fullFile .. "\n"

    elseif body[counter] == 2 then
      -- Seeing if the current index is 2 and then seeing what the next index is to make that next index * spaces.

      counter = counter + 1

      for i=1,body[counter] do

        fullFile = fullFile .. " "
      end
      -- Iterating for the amount of spaces that should be in and adding them

    elseif body[counter] == 3 then
      -- Seeing if the current index is 3 and inserting a space into the file

      fullFile = fullFile .. " "

    else

      fullFile = fullFile .. index[body[counter]-3]
    end
    -- If nothing before has caught the index, the corresponding word to that index will be inserted into the file.

    counter = counter + 1
  end

  return fullFile
end
-- The decompression function

function loadApps(appFolder,appFolderNav,searchWord)

  local pages = {}
  local apps = fileSort(fs.list(appFolder),appFolder,searchWord)
  -- Getting the app names from the appFolder

  local numberXApps = math.floor(maxX/(appMaxNameLength+1))
  -- Seeing how many apps it can fit on one line

  if appFolderNav[2] then

    negY = 5
  else

    negY = 3
  end
  -- Seeing whether or not there needs to be more space for other icons on the page or not

  local appsPerPage = math.floor((maxY-negY)/(appMaxHeight+1))*numberXApps
  -- Seeing the total number of apps per page it can fit

  for i=1,math.ceil(#apps/appsPerPage) do
    -- Running for the number of pages it has to create

    pages[i] = {}

    for j=0,appsPerPage-1 do
      -- Running for the number of apps per page

      if not apps[1] then break end
      -- Seeing if it has done all the apps in the table

      local shortenedAppName = "+"
      -- Defining the shortenedAppName variable locally here

      if fs.isDir(appFolder .. "/" .. apps[1]) then

        iconType = "folder"
        colour = colours.folder
        -- Setting the iconType var to folder and setting the colour

        shortenedAppName = apps[1]:sub(1,appMaxNameLength)
        -- Defining the shortened icon name for the app

      elseif apps[1] == "+" then

        iconType = "addNew"
        colour = colours.addNew
        -- Setting the iconType var to addNew and setting the colour

      else

        iconType = "file"
        colour = colours.app
        -- Setting the iconType var to file and setting the colour

        shortenedAppName = apps[1]:sub(1,#apps[1]-#compressedFileExtension):sub(1,appMaxNameLength)
        -- Defining the shortened icon name for the app
      end
      -- Seeing what icon colour to display for apps[1]

      local indent = (j%numberXApps)*appMaxNameLength+(j%numberXApps)+2
      -- Finding what the indent of the X value is

      pages[i][j+1] = {indent,negY+math.floor(j/numberXApps)*(appMaxHeight+1),indent+appMaxNameLength-1,appMaxHeight+negY-1+math.floor(j/numberXApps)*(appMaxHeight+1),colour,shortenedAppName,apps[1],iconType}
      -- Making the value for each app in a table in the following format: {x1,y1,x2,y2,background colour, substringed app name (for display purposes), original app name, icon type}

      table.remove(apps,1)
      -- Removing the last value from the table
    end

    if not apps[1] then break end
    -- Seeing if it has done all the apps in the table
  end

  return pages
  -- Returning the pages table after making it
end
-- Making a function to load the apps from the appFolder into a table thats split up into pages

function Triangle()

  term.setCursorPos(1,1)
  term.setTextColor(colours.decoText)
  term.write("Triangle Version: " .. osVersion)
  term.setTextColor(colors.white)
end
-- Displaying the version number at the top left of the screen

function otherArea(pageNumber)
  return {
  plus = {maxX-math.ceil((maxX)/2)+1,maxY-1,maxX,maxY-1,colours.page,"page "..pageNumber+1},
  minus = {1,maxY-1,math.floor((maxX)/2)-1,maxY-1,colours.page,"page "..pageNumber-1},
  power = {maxX-2,1,maxX,1,colors.red,"O"},
  back = {1,3,2,3,colours.page,"<"},
  searchBar = {1,maxY,maxX-#searchFilterName-1,maxY,colours.searchBackground},
  searchFilter = {maxX-#searchFilterName-1,maxY,maxX,maxY,colours.filterBackground,searchFilterName}
  }
end
-- Getting the updated pageNumber for the pages aswell as setting the power button at the top right of the screen

function addPaste(tab)
  if clipboard then

    dropMenuOpts.Paste = function() paste() end
  end
end
-- Function to add the paste option once you have a clipboard from using copy

function paste()
  if appFolder ~= clipboard[1] then
    fs.copy(clipboard[1] .. "/" .. clipboard[2], appFolder .. "/" .. clipboard[2])
  end
end
-- Function for pasting a file

function loadPage(pageNumber,appFolderNav,searchWord)

  local otherAreaTab = otherArea(pageNumber)
  -- Getting the otherArea table with the updated pageNumber

  local topFolder = fs.list(folderDir)
  -- Defining topFolder as the folders/files in the upper folder to be used later on

  Triangle()
  -- displaying the OS Version

  if appFolderNav[2] then

    term.setBackgroundColor(colors.black)
    term.setTextColor(colours.infoText)
    -- Getting the colours ready

    local dirLink = "CC:" .. appFolderNav[2]
    -- Defining the dirLink variable so it won't concatenate with what it was before

    for i=1,#appFolderNav-2 do

      dirLink = dirLink .. "/" .. appFolderNav[i+2]
    end
    -- Making the dirLink by conatenation without what folderDir is

    if #dirLink > maxX-4 then

      dirLink = dirLink:sub(#dirLink-maxX+4,#dirLink)
    end

    term.setCursorPos(4,3)
    term.write(dirLink)
    term.setTextColor(colors.white)
    -- Seeing if dirLink is longer than the page and making a sub string if it is when writing it out
  end
  -- Seeing if the user is in a folder and then displaying the back button and the directory link

  if appPages[1] then
    for i=1,#appPages[pageNumber] do

      fillArea(appPages[pageNumber][i])
    end
  end
  -- Displaying the app icons on the screen

  for key,val in pairs(otherAreaTab) do
    -- Iterating for all of the values in the otherAreaTab table

    local fillCatch = true
    -- Defining a variable so i can use it later on

    if key == "searchBar"then
      if directoryBeforeSearch[1] then

        fillArea(val)
      end

      fillCatch = false
    end
    -- Seeing if there are appPages then it will display the search bar

    if key == "minus" then
      if appPages[pageNumber-1] then

        fillArea(val)
      end

      fillCatch = false
    end
    -- Seeing if theres a table before displaying the previous page icon

    if key == "plus" then
      if appPages[pageNumber+1] then

        fillArea(val)
      end

      fillCatch = false
    end
    -- Seeing if theres a table before displaying the next page icon

    if key == "back" then
      if appFolderNav[2] then

        fillArea(val)
      end

      fillCatch = false
    end
    -- Seeing if the user is in a folder to see if it should display the back icon

    if fillCatch then

      fillArea(val)
    end
    -- Catching if the other if statements haven't returned true
  end

  if #searchWord > 0 then
    -- Checking if the searchWord has characters in it

    term.setTextColor(colors.white)
    term.setBackgroundColor(colours.searchBackground)
    term.setCursorPos(2,maxY)
    -- Getting ready for the text to be written

    local searchWordWrite = searchWord
    -- Defining another variable as searchWord so that it won't substring searchWord

    if #searchWord > maxX-5-#searchFilterName then
      -- Seeing if the searchWord string is longer than the screen

      searchWordWrite = searchWord:sub(#searchWord-maxX+5+#searchFilterName,#searchWord)
      -- Making a substring of searchWord so that it will fit on the string
    end

    term.write(searchWordWrite)
    term.setCursorBlink(true)
    term.setTextColor(colors.white)
    -- Writing searchWordWrite to the screen and then resetting the text colour

  elseif directoryBeforeSearch[1] then

    term.setCursorPos(2,maxY)
    term.setBackgroundColor(colours.searchBackground)
    term.setTextColor(colors.white)
    term.write("Type to search")
    -- Making place holder text for the search bar

  elseif not topFolder[1] and activeFilterTags.AddNew then

    term.setCursorPos(1,3)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colours.dropMenuBottom)
    print("Right click to start making apps/folders")
    term.setTextColor(colors.white)
    -- Welcoming the user into the program and telling them how to get started
  end
end
-- Loads the entire page onto the screen using fillArea alot

function clickedApp(pageNumber,clickX,clickY)
  if appPages[1] then
    for i=1, #appPages[pageNumber] do
      -- Iterating for the number of apps in the page

      if appPages[pageNumber][i][1] <= clickX and appPages[pageNumber][i][3] >= clickX and appPages[pageNumber][i][2] <= clickY and appPages[pageNumber][i][4] >= clickY then
        -- Comparing the clicked x and y values with each of the app's x and y values

        return appPages[pageNumber][i]
        -- returning the original app name in the appPages table
      end
    end
  end

  return false
  -- Returning false if it hasn't already returned a value
end
-- Detecting what app the user has clicked (if they have clicked one that is)

function clickedOther(pageNumber,clickX,clickY)
  for key,val in pairs(otherArea(pageNumber)) do
    -- Iterating for the length of the table the otherArea() function returns

    if val[1] <= clickX and val[3] >= clickX and val[2] <= clickY and val[4] >= clickY then
      -- Comparing the clicked x and y values with each of the icon's x and y values

      return key
      -- Returning the key of the key/value pair in the otherArea table
    end
  end

  return false
  -- Returning false if the func hasn't already returned a value
end
-- Detecting if the user has clicked the page icons or the close icon

function clearScreen()

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.setCursorBlink(false)
  os.run({}, "rom/programs/clear")
end
-- Clearing the screen and resetting the taxt colour and the background colour

function loadDropMenu(dropMenuOptionsFuncs,name,x,y,filterBool,isCreate)

  local dropMenuOptions = {}

  for key,_ in pairs(dropMenuOptionsFuncs) do

    table.insert(dropMenuOptions,1,key)
  end
  -- Making the dropMenuOptions table from the functions's keys

  if y + #dropMenuOptions > maxY then

    y = y - (y+#dropMenuOptions-maxY)
  end
  -- Seeing if the drop menu will go off the screen and correcting it if it does

  if x+appMaxNameLength > maxX then

    x = x - (x+appMaxNameLength-maxX)
  end
  -- Seeing if the drop menu will go off the screen and correcting it if it does

  if name then

    term.setCursorPos(x,y)
    fillArea({x,y,x+appMaxNameLength,y,colours.dropMenuTop})
    term.setCursorPos(x,y)

    local shortenedName

    if not fs.isDir(appFolder .. "/" .. name) and not isCreate then

      shortenedName = name:sub(1,#name-#compressedFileExtension):sub(1,appMaxNameLength)
    else

      shortenedName = name:sub(1,appMaxNameLength)
    end
    -- Defining shortenedName differently depending on whether its a file or a folder

    term.write(shortenedName)
    -- Writing the app name in the right colour and at the right place
  end
  -- Seeing if the name argument has been given

  fillArea({x,y+1,x+appMaxNameLength,y+#dropMenuOptions,colours.dropMenuBottom})
  -- Filling the below area for the drop menu options

  for i=1,#dropMenuOptions do
    -- Iterating through the dropMenuOptions table

    if filterBool and activeFilterTags[dropMenuOptions[i]] then
      -- Seeing if filterBool is true and if the filter is active

      term.setTextColor(colours.filterOn)
      -- Setting the text colour to filterOn if the filter is on

    elseif filterBool then
      -- Seeing if filterBool is true but the filter is not active

      term.setTextColor(colours.filterOff)
      -- Setting the text colour to filterOff if the filter is off
    end

    term.setCursorPos(x,y+i)
    term.write(dropMenuOptions[i]:sub(1,appMaxNameLength))
    term.setTextColor(colors.white)
  end
  -- Writing the options in their places and making sure they don't go over the appMaxNameLength

  return dropMenuOptions,dropMenuOptionsFuncs,name,x,y
  -- Returning the changed coordinates of the drop menu
end
-- Loading the drop menu from where the user has clicked

function dropMenu(dropMenuOptions,dropMenuOptionsFuncs,name,x,y)

  local event, button, clickX, clickY = os.pullEvent("mouse_click")
  -- Getting a user mouse click input

  if button == 1 then
    -- Seeing if the user has left clicked

    for i=1,#dropMenuOptions do
      --Iterating for the amount of options in the drop menu

      if x <= clickX and x+appMaxNameLength >= clickX and y+i <= clickY and y+i >= clickY then
        -- Detecting whether the user has clicked an option

        dropMenuOptionsFuncs[dropMenuOptions[i]](name)
        -- Running the function in the drop menu
      end
    end
  end
end
-- Function for detecting if the user has clicked an option in the drop menu

appFolderNav = {folderDir}
-- Making the nav table so its easy to modify the directory navigation

local event = "mouse_click"
-- Giving the event var a value

local searchWord = ""
-- Defining searchWord as an empty string

while not terminate do
  -- Running while the terminate variable is false

  appFolder = ""
  -- Defining the appFolder as an empty string before adding strings to it
  for i=1,#appFolderNav do

    appFolder = appFolder .. "/" .. appFolderNav[i]
  end
  -- Remaking the appFolder directory navigation

  appPages = loadApps(appFolder,appFolderNav,searchWord)
  -- Loading the apps into a sorted table

  if event == "mouse_click" or event == "key" then

    clearScreen()
    loadPage(pageNumber,appFolderNav,searchWord)
  end
  -- First checking if the last event was a mouse click or a key press (to make it that little bit more efficient) before clearing and then loading the current page

  if not dropMenuOpts.paste then

    addPaste()
  end
  -- while the paste option is not in the dropMenuOpts table it tries to add paste to dropMenuOpts

  local event, button, x, y = os.pullEvent()
  -- Waiting for a mouse click event

  local currentFolder = fs.list(appFolder)
  -- Getting whatever is in the current folder for later use

  if event == "mouse_click" then

    local clickedAppResult = clickedApp(pageNumber,x,y)
    local clickedOtherResult = clickedOther(pageNumber,x,y)
    -- Getting the result of each of the click detection functions

    if button == 1 then
      if clickedAppResult and clickedAppResult[8] == "file" then

        local toRun = fs.open(runFile,"w")
        toRun.write(decompress(appFolder .. "/" .. clickedAppResult[7]))
        toRun.close()
        -- Making a temporary file with the decompressed version of the file's contents

        clearScreen()
        os.pullEvent = oldPullEvent
        os.run({}, runFile .. " " .. appFolder)
        os.pullEvent = os.pullEventRaw
        clearScreen()
        fs.delete(runFile)
        -- If the user has clicked an app, it will first clear the screen and then run the app and then clear the screen yet again

      elseif clickedAppResult and clickedAppResult[8] == "folder" then

        table.insert(appFolderNav,#appFolderNav+1,clickedAppResult[7])
        -- When the user clicks a folder it will add the folder name to the appFolderNav table

      elseif clickedAppResult and clickedAppResult[8] == "addNew" then

        dropMenu(loadDropMenu(dropMenuOpts,nil,x,y-1))
        -- Loading the create drop menu when the user left clicks the + icon

      elseif appFolderNav[2] and clickedOtherResult == "back" then

        table.remove(appFolderNav,#appFolderNav)
        -- when the user clicks the back button inside a folder it will remove the last folder name the user clicked

      elseif appPages[pageNumber-1] and clickedOtherResult == "minus" then

        pageNumber = pageNumber - 1
        -- If the user has clicked the left page icon and if the appPages page exists it will minus the current pageNumber

      elseif appPages[pageNumber+1] and clickedOtherResult == "plus" then

        pageNumber = pageNumber + 1
        -- If the user has clicked the right page icon and if the appPages page exists it will plus the current pageNumber

      elseif clickedOtherResult == "searchFilter" then

        dropMenu(loadDropMenu(dropMenuFilterTags,nil,x,y-1-numFilterTags,true))
        -- Loading the filter's drop menu

      elseif clickedOtherResult == "power" then

        dropMenu(loadDropMenu(dropMenuPower,nil,x,y))
        -- If the user has clicked the power icon, it will load the power drop menu

        if terminate then

          clearScreen()
        end
        -- Clearing the screen when the user terminates the OS to go back to the normal CC OS

      end

      if clickedOtherResult ~= "minus" and clickedOtherResult ~= "plus" then

        searchWord = ""
      end
      -- making the searchWord = nothing after you search

    elseif button == 2 and clickedAppResult and clickedAppResult[8] == "file" then

      dropMenu(loadDropMenu(dropMenuApps,clickedAppResult[7],x,y))
      -- First loading the drop menu for apps and then detecting if the user has clicked on it

    elseif button == 2 and clickedAppResult and clickedAppResult[8] == "folder" then

      dropMenu(loadDropMenu(dropMenuFolders,clickedAppResult[7],x,y))
      -- First loading the drop menu for folders and then detecting if the user has clicked on it

    elseif button == 2 then

      dropMenu(loadDropMenu(dropMenuOpts,"Create",x,y,false,true))
      -- If the user hasn't right clicked on an app they get this drop down menu
    end
  elseif event == "key" and currentFolder[1] then
    -- Seeing if the event is a key press for searching

    pageNumber = 1
    -- Resetting the page number so that the program doesn't error

    local pressedKey = button
    local held = x
    -- Redefining button and x to make sense for the key event

    if pressedKey == 14 then
      -- Checking if the user has pressed backspace

      if #searchWord > 0 then
        -- Checking if theres any more characters to delete in the searchWord

        searchWord = searchWord:sub(1,#searchWord-1)
        -- Removing the last character from the searchWord string
      end

    elseif pressedKey <= 10 and pressedKey >= 2 then
      -- Catching if the user has entered 1-9

      searchWord = searchWord .. pressedKey - 1
      -- Adding the correct number to the searchWord

    elseif pressedKey == 11 then
      -- Catching if the user has pressed 0

      searchWord = searchWord .. 0
      -- Adding 0 to the searchWord

    elseif pressedKey == 203 and appPages[pageNumber-1] then

      pageNumber = pageNumber - 1
      -- If you press the left arrow key it will try to minus 1 from pageNumber

    elseif pressedKey == 205 and appPages[pageNumber+1] then

      pageNumber = pageNumber + 1
      -- If you press the right arrow key it will try to add 1 to pageNumber

    else
      for key,val in pairs(keys) do
        -- Iterating for the amount of keys and values the keys api has

        if val == pressedKey then
          -- Checking if what the user entered matched the current val

          if #key == 1 then
            -- Seeing if the val is a single character, essentially making this only pick up a-z

            searchWord = searchWord .. key
            -- Adding the key to the searchWord string
          end

          break
          -- Breaking the for loop to prevent further unecessary iteration
        end
      end
    end
  end
end
