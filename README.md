                                                                                               
   **pdf-split**                                                                                 
       
     State:       early ALPHA                                                                     
     Language:    BASH                                                                            
     Author:      Hannah Lea Moeckel                                                              
                                                                                               




_A simple but very purpose-build bash script for splitting a big PDF at a reapeating pattern_

  Usage:
  
    pdf-split -I <InputFile> -O <OutputFile> -r
    
  
  Notes and advice:
  
    - It is really important to install all the dependecies first and make sure the system
      access them via the PATH variable.
    - As an Input you can supply one big pdf of unlimited page count. If text format is not 
      available ocr ist performed automatically.
    - As the Output you also define a file for reference for the filenames used to output 
      the final split documents.
    - r triggers final text recognition on output file for further use.
      
  Known Bugs and issuse:
  
    - Existance checks for files and directories used not yet implemented.
    - Output file structuring system still work in progress.
    - No installer script.
    - Some unfinished functions in current version
