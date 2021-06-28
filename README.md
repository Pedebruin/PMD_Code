# PMD_Code
This repository is made to support the design project of group A3 for the course ME46015 - Precision Mechanism Design 2020/2021 at the Delft University of Technology. 
The code is entirely written and mainained by: 

  + Jos Boetzkes 
  + Pim de Bruin 
  + Thami Fischer  
  + Mansour Khaleqi  
  + Olivia Taal  

For questions or comments contact 'P.E.deBruin@student.tudelft.nl'

## Code
  The code is made to simulate a kinematic coupling of a 300mm wafer during cooldown from 300 to 0K and model its thermal contraction.
  The code consists of multiple .m files:
    
  + `Analysis.m`  
  This file contains the main analysis loop and depends on all other files. This file starts off with some usersettings and important settings that can be changed to     change the 
  output of the file, but for illustrative purposes, these settings are set to show the most generic plot. the Important pareters (section 2 of the code) are the parameter that
  are most interesting to change. Along with `userSettings.Amplification` 
  + `body.m`  
  This file contains the class defenition for the class `body` which is used for all objects in the simulation. 
  + `Force_analysis_f`  
  This file contains the force model that maps the input nesting force to a force on the three pins. 
  + materialModels  
   Folder containing the material models used in the simulation and development. These models are linear and nonlinear thermal expansion coefficient model functions with the temperature as input, and the instantanious thermal expansion coeeficient as output. 
  
  To see the simulation, it is sufficient to open `Analysis.m` and run it with default parameters. 
