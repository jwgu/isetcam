!Image Systems Evaluation Toolkit (ISET) Zemax Macro (ZPL)
!
!Author: P. Maeda, B. Wandell, P. Catrysse
!Date:   March, 2005
!
! This macro is written to work with the ISET simulation technology.
! The macro calculates 
!
!    (a) the local pointspread functions 
!    (b) the geometric distortion, 
!    (c) relative illumination from a lens description file, and 
!    (d) the chief ray angle for each image height and wavelength.
!
! Several other lens parameters are also calculated and saved 
!(effective focal length, effective f-number, and so forth.
!
! The macro analyzes the data in the currently loaded lens.
!
! The data are written to a series .DAT files.  These files 
! are read from within the ISET-Optics window.
! The are stored as an ISET optics structure that can
! be used in the ray trace analysis of image formation.
!
! To run this macro place the file in the Zemax macro directory.
! Then, edit the parameters in the editable section of this file (see below).
! Then invoke this macro from within Zemax from the Macro pulldown.
!
! Instructions for editing setting up Zemax and editing the file can be found at
! <<<<WEB-SITE INFORMATION GOES HERE>>>>>
!
! The output files are stored in the format 
!     <basename>_PSF_<FieldHeightIndex>_<WavelengthIndex>.dat  (many files)
!     <basename>_RI_.dat
!     <basename>_DI_.dat
!     <basename>_CRA_.dat
!
!--------------------------------------------------------------------------------
!modified by D.Bakin to add <basename>_CRA_.dat file in the same format as the _DI_ file
!date: June 21, 2005
!
!This version will work with the current lens loaded in Zemax. User needs to create 
!a new directory, say  c:\ZEMAX\ISET\LENSNAME\, where LENSNAME - is the lens title defined 
!in Zemax's General system dialog box 
!--------------------------------------------------------------------------------
! Modifed/Updated by Travis Allen to reflect the latest keywords and conventions.
! Date:  12/12/2017
! Note: Script works with OpticStudio ZeMax 17.5 as of 12/12/2017
! The output file format for PSF's were changed in 2014 (and not properly documented).
! The new format is:
!	<basename>_2D_PSF_Fld<FieldHtIdx>_Wave<WavelengthIdx>.dat
!
! A few nuances to the code:
!   1) For some reason the macro will not create an ISETPARMS.txt file. It needs a blank
!      file in the correct directory in order to write to it. Make sure to do this before
!      running the program. (correct directory is the lens directory)
!   2) For both the PSF output and the grid distortion output, you need to save a .CFG
!      file in the correct directory in order to properly run these sections. The macro
!      modifies the .CFG files in order to ensure proper output and can't do that if the
!      files aren't there. You can simply save this file by going to the correct window
!      in Zemax and saving the settings. (correct directory is the lens directory)
! 
! Also added back in a section for outputing Grid Distortions. Since this does not appear
! to be used with any current ISET scripts, it has been commented out.  But it is there
! and it can output files in the format:
!	<basename>_GridDistortion_Fld<FieldHtIdx>_Wave<WavelengthIdx>.dat (many files)
! This portion will output as many Grid Distortion files as there are PSF files.
!--------------------------------------------------------------------------------
LENS_DIR$=$PATHNAME()
                      
LENS_FILE$=$FILENAME()

PARAMETERS_FILE$= LENS_DIR$ + "\" + $LENSNAME() + "\ISETPARMS.TXT"

BASENAME$= LENS_DIR$ + "\" + $LENSNAME() + "\" + $LENSNAME()

!$LENSNAME() - Returns the lens title defined in General system dialog box

! -------------------------------------------------
! The user should edit the 6 fields below.  These are
!
! PSF_SIZE:      The number of samples in the psf
! GRID_SPACING:  The spacing between PSF samples (mm)
! WL_NUM:        Number of wavelength samples
! WL_MIN,WL_MAX: Lowest and highest wavelength samples (in nanometers)
! IMGHT_NUM:     Number of samples of the image height from 0 to the max field of view
!--------------------------------------------------

!PSF DIMENSIONS MUST BE 64X64, 128X128, 256X256, 512X512, 1024X1024, 2048X2048, OR 4096X4096
!This parameter must match the value set in the Zemax FFT Settings window
PSF_SIZE=128 # Keep this 128 because I hard-coded ISET for this 

!PSF GRID SPACING IN MM
GRID_SPACING=0.00025 

!NUMBER OF WAVELENGTHS
WL_NUM=33

!MINIMUM WAVELENGTH IN NANOMETERS                          
WL_MIN=400

!MAXIMUM WAVELENGTH IN NANOMETERS
WL_MAX=720                      

!NUMBER OF PARAXIAL IMAGE HEIGHTS
IMGHT_NUM=21

!---------------------DO NOT EDIT BELOW THIS LINE ----------------------
!-----------------------------------------------------------------------

!MINIMUM PARAXIAL IMAGE HEIGHT IN MM                      
IMGHT_MIN=0

LENS_FULL_PATH$=$FILEPATH()

!Lens dimensions must be specified in millimeters (mm). 
SETUNITS 0

!Lens must have apertures defined on all surfaces, including the aperture stop
!to insure vignetting is properly accounted for. 

!SELECT LENS CONFIGURATION  1         
SETCONFIG 1

!SET STATE OF RAY AIMING FUNCTION:  0 FOR NO RAY AIMING
!                                   1 FOR PARAXIAL REFERENCE
!                                   2 FOR REAL REFERENCE               
SETAIM 2

!PLACE SYSTEM DATA IN VEC1
GETSYSTEMDATA 1                    

!LENS REFERENCE WAVELENGTH NUMBER (Equal to Current Primary Wavelength)
WL_REF_NUM = SYPR(200) 	#Edited by Travis Allen, 12/9/17 (was PWAV())

!LENS REFERENCE WAVELENGTH IN NM                     
WL_REF=1000*WAVL(WL_REF_NUM)

!OBJECT DISTANCE IN MM
OBJ_DIST=THIC(0) 
   
!OPTICAL SYSTEM MAGNIFICATION
MAG=VEC1(16)                       

!EFFECTIVE FOCAL LENGTH
EFL=VEC1(7)

!EFFECTIVE F-NUMBER (WORKING F-NUMBER)
EFNUM=VEC1(10)

!F-NUMBER (IMAGE SPACE F-NUMBER)
FNUM=VEC1(8)

!May be not neccesary.
!Adjust focus by moving the image surface to minimize parameter 
!around centroid (SECOND ARGUMENT=1): 
!0 - RMS spot radius; 1 - spot x; 2 - spot y; 3 - wavefront OPD
!QUICKFOCUS 0, 1

!------------------------------------------------------------
!----CALCULATE maximum diagonal half field of view
!------------------------------------------------------------
!! Added by Travis Allen, 12/9/17 (RAYTRACE wasn't working)
SYSP 202, 1, WAVL(SYPR(200))
SYSP 200, 1
!!

PI=3.14159265
RAYTRACE 0, 1, 0, 0

!MAXIMUM FIELD OF VIEW IN DEGREES 
FOV=ACOS(RAYN(0))*180/PI

!Calculate Max Paraxial Image Height
IMGHT_MAX=EFL*TANG(ACOS(RAYN(0)))

!----------------------------------
!----WRITE Parameters file
!----------------------------------

OUTPUT PARAMETERS_FILE$

TEMPSTR$="%   " + LENS_FULL_PATH$
PRINT TEMPSTR$

TEMPSTR$="lensFile='" + LENS_FILE$
TEMPSTR$=TEMPSTR$ + "';     %Lens file name"
PRINT TEMPSTR$

TEMPSTR$="psfSize="
FORMAT .0
PRINT TEMPSTR$, PSF_SIZE, ";                 % PSF ROW AND COL SIZE"

TEMPSTR$="psfSpacing="
FORMAT .7
PRINT TEMPSTR$, GRID_SPACING, ";   % PSF GRID SPACING IN MM"

dW=(WL_MAX-WL_MIN)/(WL_NUM-1)
TEMPSTR$="wave="
FORMAT .0
PRINT TEMPSTR$, WL_MIN, ":", dW, ":", WL_MAX, ";            % WAVELENGTH SAMPLES (NM)"

!Commented out for DB
!dH=(IMGHT_MAX-IMGHT_MIN)/(IMGHT_NUM-1)
!TEMPSTR$="imgHeight="
!FORMAT .3
!PRINT TEMPSTR$, IMGHT_MIN, ":", dH, ":", IMGHT_MAX, ";     % REAL IMAGE HEIGHTS (MM)"

TEMPSTR$="imgHeightNum="
FORMAT .0
PRINT TEMPSTR$, IMGHT_NUM, ";                % Number of IMAGE HEIGHTS "

TEMPSTR$="imgHeightMax="
FORMAT .7
PRINT TEMPSTR$, IMGHT_MAX, ";                % Maximum IMAGE HEIGHT (mm)"

TEMPSTR$="objDist="
FORMAT .3 
PRINT TEMPSTR$, OBJ_DIST, ";                 % OBJECT DISTANCE (MM)"

TEMPSTR$="mag="
FORMAT .6 
PRINT TEMPSTR$, MAG, ";          % OPTICAL SYSTEM MAGNIFICATION"

TEMPSTR$="baseLensFileName='" + BASENAME$
TEMPSTR$=TEMPSTR$ + "';"
PRINT TEMPSTR$

TEMPSTR$="refWave="
FORMAT .3
PRINT TEMPSTR$, WL_REF, ";          % REFERENCE WAVELENGTH (NM)"

TEMPSTR$="fov="
FORMAT .6
PRINT TEMPSTR$, FOV, ";          % MAXIMUM DIAGONAL HALF FOV (DEGREE)"

TEMPSTR$="efl="
FORMAT .6 
PRINT TEMPSTR$, EFL, ";          % EFFECTIVE FOCAL LENGTH"

TEMPSTR$="fnumber_eff="
FORMAT .6 
PRINT TEMPSTR$, EFNUM, ";          % EFFECTIVE F-NUMBER"

TEMPSTR$="fnumber="
FORMAT .6 
PRINT TEMPSTR$, FNUM, ";          % F-NUMBER"

OUTPUT SCREEN

!----------------------------------
!----END WRITE Parameters file
!----------------------------------


!---------------------------------------
!CALCULATE THE IMAGE DISTORTION 
!---------------------------------------

!SET TOTAL NUMBER OF FIELDS
NUMFIELD 1

!SELECT FIELD TYPE:  0 FOR ANGLE IN DEGREES
!                    1 FOR OBJECT HEIGHT IN LENS UNITS
!                    2 FOR PARAXIAL IMAGE HEIGHT IN LENS UNITS
!                    3 FOR REAL IMAGE HEIGHT IN LENS UNITS
SYSP 100, 2 #Edited by Travis Allen, 12/9/17 (was FTYP=2)

!SET TOTAL NUMBER OF WAVELENGTHS
NUMWAVE 1

IMG_SURF_NUM=NSUR()

!SET UP THE DISTORTED IMAGE HEIGHT DATA OUTPUT FILE NAME
OUTPUT SCREEN
OUTPUT_DI_FILE$=BASENAME$ + "_DI_" + ".dat" #commented by Ginni Grover 2014/01/03
!OUTPUT_DI_FILE$=BASENAME$ + "_DI_" + ".xls" #added by Ginni Grover 2014/01/03
PRINT "OUTPUT DISTORTED IMAGE HEIGHT FILENAME:  ", OUTPUT_DI_FILE$
OUTPUT OUTPUT_DI_FILE$


FOR J, 1, IMGHT_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR J = 1,...)
	IMGHT=IMGHT_MIN+(J-1)*(IMGHT_MAX-IMGHT_MIN)/(IMGHT_NUM-1)

	FOR I, 1, WL_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR I = 1,...)
		WLT=WL_MIN+(I-1)*(WL_MAX-WL_MIN)/(WL_NUM-1)

		!The following lines used obsolete terms
		!Replaced by the current terms (Travis, 12/9/17)
		SYSP 202, 1, WLT/1000 	#SYSP 202 = old WAVL (wavelength value)
		SYSP 200, 1 			#SYSP 200 = old PWAV (sets primary wavelength)
		SYSP 102, 1, 0.0 		#SYSP 102 = old FLDX (starting x value)
		SYSP 103, 1, IMGHT		#SYSP 103 = old FLDY (starting y value)
	  
		!SET VIGNETTING FACTORS FOR GIVEN IMAGE HEIGHT AND WAVELENGTH
		SETVIG
		UPDATE       
	  
		RAYTRACE 0, 1, 0, 0
		DISTIMGHT=RAYY(IMG_SURF_NUM)
		!WRITE DISTORTED IMAGE HEIGHT DATA TO DI OUTPUT FILE
		!Cleaned up by Travis Allen, 12/12/17
		FORMAT .6 EXP
		PRINT DISTIMGHT
   NEXT
NEXT

OUTPUT SCREEN

!------------------------------------------------------------------------
!CALCULATE THE CRA
!------------------------------------------------------------------------

!USE THE SAME PARAMETERS AS IN DISTORTION CALCULATIONS

!SET UP THE CRA DATA OUTPUT FILE NAME
OUTPUT SCREEN
OUTPUT_CRA_FILE$=BASENAME$ + "_CRA_" + ".dat" #commented by Ginni Grover 2014/01/03
!OUTPUT_CRA_FILE$=BASENAME$ + "_CRA_" + ".xls" #added by Ginni Grover 2014/01/03
PRINT "OUTPUT CRA FILENAME:  ", OUTPUT_CRA_FILE$
OUTPUT OUTPUT_CRA_FILE$

FOR J, 1, IMGHT_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR J = 1,...)
   IMGHT=IMGHT_MIN+(J-1)*(IMGHT_MAX-IMGHT_MIN)/(IMGHT_NUM-1)


	FOR I, 1, WL_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR I = 1,...)
		WLT=WL_MIN+(I-1)*(WL_MAX-WL_MIN)/(WL_NUM-1)

		!The following lines used obsolete terms
		!Replaced by the current terms (Travis, 12/9/17)
		SYSP 202, 1, WLT/1000 	#SYSP 202 = old WAVL (wavelength value)
		SYSP 200, 1 			#SYSP 200 = old PWAV (sets primary wavelength)
		SYSP 102, 1, 0.0 		#SYSP 102 = old FLDX (starting x value)
		SYSP 103, 1, IMGHT		#SYSP 103 = old FLDY (starting y value)
	  
		!SET VIGNETTING FACTORS FOR GIVEN IMAGE HEIGHT AND WAVELENGTH
		SETVIG
		UPDATE   
		RAYTRACE 0, 1, 0, 0
		!CALCULATE CRA FOR THE CURRENT FOV (MEASURED IN RADIANS)
		CRA=ACOS(RAYN(IMG_SURF_NUM))
   
		!WRITE CRA DATA TO CRA OUTPUT FILE
		!Cleaned up by Travis Allen, 12/12/17
		FORMAT .6 EXP
		PRINT CRA  
   NEXT
NEXT

OUTPUT SCREEN
!---------------------------------------
!CALCULATE THE RELATIVE ILLUMINATION
!---------------------------------------

!SET TOTAL NUMBER OF FIELDS
NUMFIELD 2

!SELECT FIELD TYPE:  0 FOR ANGLE IN DEGREES
!                    1 FOR OBJECT HEIGHT IN LENS UNITS
!                    2 FOR PARAXIAL IMAGE HEIGHT IN LENS UNITS
!                    3 FOR REAL IMAGE HEIGHT IN LENS UNITS
SYSP 100, 2 #Edited by Travis Allen, 12/9/17 (Was FTYP=2)

!SET TOTAL NUMBER OF WAVELENGTHS
NUMWAVE 1

!SET UP THE RELATIVE ILLUMINATION DATA OUTPUT FILE NAME
OUTPUT SCREEN
OUTPUT_RI_FILE$=BASENAME$ + "_RI_" + ".dat" #commented by Ginni Grover 2014/01/03
!OUTPUT_RI_FILE$=BASENAME$ + "_RI_" + ".xls" #added by Ginni Grover 2014/01/03
PRINT "OUTPUT RELATIVE ILLUMINATION FILENAME:  ", OUTPUT_RI_FILE$
OUTPUT OUTPUT_RI_FILE$

FOR J, 1, IMGHT_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR J = 1,...)
   IMGHT=IMGHT_MIN+(J-1)*(IMGHT_MAX-IMGHT_MIN)/(IMGHT_NUM-1)


	FOR I, 1, WL_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR I = 1,...)
		WLT=WL_MIN+(I-1)*(WL_MAX-WL_MIN)/(WL_NUM-1)

		!The following lines used obsolete terms
		!Replaced by the current terms (Travis, 12/9/17)
		SYSP 202, 1, WLT/1000 		#SYSP 202 = old WAVL
		SYSP 200, 1 				#SYSP 200 = old PWAV
		SYSP 102, 1, 0.0 			#SYSP 102 = old FLDX
		SYSP 103, 1, 0.0			#SYSP 103 = old FLDY
		SYSP 102, 2, 0.0			#SYSP 102 = old FLDX
		SYSP 103, 2, IMGHT			#SYSP 103 = old FLDY
	  
		!SET VIGNETTING FACTORS FOR GIVEN IMAGE HEIGHT AND WAVELENGTH
		SETVIG
		UPDATE
		RELILLUM=RELI(2)

		!WRITE RELATIVE ILLUMINATION DATA TO RI OUTPUT FILE
		!Cleaned up by Travis Allen, 12/12/17
		FORMAT .6 EXP
		PRINT RELILLUM
   NEXT
NEXT

OUTPUT SCREEN

!-------------------------------------------------------------------
! CALCULATE THE PSF
!-------------------------------------------------------------------

!SET TOTAL NUMBER OF FIELDS
NUMFIELD 1

!SELECT FIELD TYPE:  0 FOR ANGLE IN DEGREES
!                    1 FOR OBJECT HEIGHT IN LENS UNITS
!                    2 FOR PARAXIAL IMAGE HEIGHT IN LENS UNITS
!                    3 FOR REAL IMAGE HEIGHT IN LENS UNITS
SYSP 100, 2 #Edited by Travis Allen, 12/9/17 (Was FTYP=2)

!SET TOTAL NUMBER OF WAVELENGTHS
NUMWAVE 1

!SET THE MAXIMUM SIZE OF THE VECn ARRAYS FOR THE PSF OUTPUT
SETVECSIZE PSF_SIZE*PSF_SIZE+2

FOR I, 1, WL_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR I = 1,...)
   WLT=WL_MIN+(I-1)*(WL_MAX-WL_MIN)/(WL_NUM-1)

	FOR J, 1, IMGHT_NUM, 1		#Edited by Travis Allen, 12/9/17 (Was FOR J = 1,...)
      IMGHT=IMGHT_MIN+(J-1)*(IMGHT_MAX-IMGHT_MIN)/(IMGHT_NUM-1)

		!The following lines used obsolete terms
		!Replaced by the current terms (Travis, 12/9/17)
		SYSP 202, 1, WLT/1000		#SYSP 202 = old WAVL
		SYSP 200, 1					#SYSP 200 = old PWAV
		SYSP 102, 1, 0.0			#SYSP 102 = old FLDX
		SYSP 103, 1, -IMGHT 		#SYSP 103 = old FLDY

		!SET VIGNETTING FACTORS FOR GIVEN IMAGE HEIGHT AND WAVELENGTH
		SETVIG
		UPDATE              
      
		OUTPUT SCREEN

		!SET UP THE PSF OUTPUT FILE NAME
		FORMAT .0
		!OUTPUT_PSF_FILE$=BASENAME$ + "_PSF_" + $STR(J) + "_" + $STR(I) + ".dat" #commented by Ginni Grover 2014/01/02
		OUTPUT_PSF_FILE$=BASENAME$ + "_2D_PSF_Fld" + $STR(J) + "_Wave" + $STR(I) + ".dat" #added by Ginni Grover 2014/01/02
		PRINT "OUTPUT PSF FILENAME:  ", OUTPUT_PSF_FILE$

		!CREATE PSF TEXT DATA AND WRITE TO FFT PSF OUTPUT FILE
		!WE MODIFIED PSF.CFG WHICH IS A GLOBAL FILE IN THE ZEMAX DIR TO $LENSNAME().CFG WHICH IS A LOCAL FILE IN THE LENS DIR
		CFG_FILENAME$ = BASENAME$ + ".CFG" #Modified by Travis Allen, 12/11/17 (didn't have entire location before)

		MODIFYSETTINGS CFG_FILENAME$, PSF_IMAGEDELTA, GRID_SPACING * 1000 #Added by Travis Allen, 12/11/17 (sets the grid spacing)

		#GETTEXTFILE OUTPUT_PSF_FILE$, Hps, CFG_FILENAME$, 1  #Commented by Travis Allen, 12/11/17 (outputs Huygen PSF)
		GETTEXTFILE OUTPUT_PSF_FILE$, Fps, CFG_FILENAME$, 1	#Added by Travis Allen, 12/11/17 (outputs FFT PSF)
   NEXT
NEXT

OUTPUT SCREEN

#The following was added back in by Travis Allen, 12/11/17 (from ISET_RT_ZEMAX_b.ZPL)

!-------------------------------------------------------------------
! CALCULATE THE full Grid Distortion
! This was added back into the script by Travis Allen, 12/11/17
! Modified from its original version in ISET_RT_ZEMAX_b.ZPL,
! this portion creates as many Grid Distortion files as there are
! PSF files.  Currently, as far as I can tell, these aren't used
! in ISET.  So I've comment everything out.  Simply Uncomment each
! line with "!!!" in front of it to use the code.
!-------------------------------------------------------------------

!Grid size for GridDistortion.dat text file is negative double the first number in the first column
!Please set and save the lens setting for Grid Distortion in Zemax to Grid_Size=64
!!!NUMFIELD 1
!!!NUMWAVE 1

!!!SYSP 100, 2 #Paraxial Image Height the Correct one here? (Travis Allen)

!Set reference point for the grid at zero


!!!FOR I, 1, WL_NUM, 1
!!!   WLT=WL_MIN+(I-1)*(WL_MAX-WL_MIN)/(WL_NUM-1)
!!!   SYSP 202, 1, WLT/1000
!!!   SYSP 200, 1
   
!!!	FOR J, 1, IMGHT_NUM, 1
!!!		IMGHT=IMGHT_MIN+(J-1)*(IMGHT_MAX-IMGHT_MIN)/(IMGHT_NUM-1)
!!!		SYSP 102, 1, 0.0
!!!		SYSP 103, 1, -IMGHT #Should this be negative as with PSF? (Travis Allen)
	   
!!!		!SET VIGNETTING FACTORS FOR GIVEN IMAGE HEIGHT AND WAVELENGTH
!!!		! Actually I am not sure if it is required, but just in case ...
!!!		SETVIG
!!!		UPDATE
!!!		OUTPUT SCREEN

		!SET UP THE Grid Distortion OUTPUT FILE NAME
!!!		FORMAT .0
!!!		OUTPUT_GD_FILE$=BASENAME$ + "_GridDistortion_Fld" + $STR(J) + "_Wave" + $STR(I) + ".dat"
!!!		GD_SETTINGS_FILE$ = BASENAME$ + "_GRD.CFG"
!!!		PRINT "OUTPUT GRID DISTORTION FILENAME:  ", OUTPUT_GD_FILE$

		!CREATE Grid Distortion TEXT DATA AND WRITE TO GD OUTPUT FILE
!!!		GETTEXTFILE OUTPUT_GD_FILE$, Grd, GD_SETTINGS_FILE$, 1
!!!	NEXT
!!!NEXT

OUTPUT SCREEN

LABEL 1

!Load original lens file back in Zemax
LOADLENS LENS_FULL_PATH$

!Tell me if you heard the
BEEP
!because I didn't	#Edit by Travis Allen, 12/11/17:  I did! More of a "chime"...
PRINT "End Script"	#Added by Travis Allen, 12/9/17
!---------------------------END OF MACRO-------------------------------------

