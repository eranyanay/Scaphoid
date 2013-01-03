# Amira-Script-Object V3.0
#todo add doucomentation for each function
proc getLineNum {} {
	return 4
}
# returns Names of Lines, where each line has an identification number
proc getLineName {i} {
	set linesNames [list "Pre" "PCA" "SEC" "Post"]
	return [lindex $linesNames $i]
}
# returns the color of each line, where each line has an identification number
proc getLineColor {i} {
	# "Pre" "PCA" "SmallestEnclosingCylinder" "Post"
	set linesColors [list "0 0 255" "0 255 0" "165 42 42" "0 255 255"]
	return [lindex $linesColors $i]
}
proc getLegendColor {i} {
	# "Pre" "PCA" "SmallestEnclosingCylinder" "Post"
	set legendColors [list "0 255 0" "255 0 0" "50 0 0" "255 255 255"]
	return [lindex $legendColors $i]
}

$this proc constructor {} {
	
	$this newPortConnection scaphoid HxUniformLabelField3
	$this newPortConnection fracture HxUniformLabelField3
	$this newPortConnection preMarkers HxLandmarkSet
	$this newPortConnection palmDirMarkers HxLandmarkSet
	$this newPortConnection ArticularPlaneMarkers HxLandmarkSet
	$this newPortInfo info
	$this info setValue "data is irrelevant, PreMarkers is optional,
ArticularPlaneMarkers is needed only for Articular plane,
fracture is needed only for Fracture plane,
if palmDirMarkers are not given the diraction of the palm according to the axis of the C.T,
there shouldn't be more then one $this in the pool, each $this object can be used only once."
	
	$this newPortRadioBox CalculateAnglesOnplane 2
	$this CalculateAnglesOnplane setLabel 0 "Fracture"
	$this CalculateAnglesOnplane setLabel 1 "Articular"
	$this CalculateAnglesOnplane setValue 0
	
	$this newPortRadioBox PalmDirIfNoPalmDirMarkersAreGiven 3
	$this PalmDirIfNoPalmDirMarkersAreGiven setLabel 0 "X"
	$this PalmDirIfNoPalmDirMarkersAreGiven setLabel 1 "Y"
	$this PalmDirIfNoPalmDirMarkersAreGiven setLabel 2 "Z"
	$this PalmDirIfNoPalmDirMarkersAreGiven setValue 1
	
	$this newPortButtonList PointsCoordinates 1
	$this PointsCoordinates setLabel 0 "Show"
	$this PointsCoordinates setSensitivity 0 0
	
	$this newPortButtonList DistanceMesurements 1
	$this DistanceMesurements setLabel 0 "Show"
	$this DistanceMesurements setSensitivity 0 0
	
	$this newPortButtonList AnglesMesurements 1
	$this AnglesMesurements setLabel 0 "Show"
	$this AnglesMesurements setSensitivity 0 0
	
	$this newPortToggleList SmallestEnclosingCylinderLine 1
	$this SmallestEnclosingCylinderLine setLabel 0 "calc line" 
	$this SmallestEnclosingCylinderLine setValue 0 0
	
	$this newPortButtonList SmallestEnclosingCylinder 1
	$this SmallestEnclosingCylinder setLabel 0 "advanced options"
	
	$this newPortToggleList SecOpt 2
	$this SecOpt setLabel 0 "use surface optimization"
	$this SecOpt setLabel 1 "use PCA optimization"
	$this SecOpt setValue 0 1
	$this SecOpt setValue 1 1
	$this SecOpt hide
	
	$this newPortFloatSlider SecAngleScan 
	$this SecAngleScan setMinMax 0.00001 10
	$this SecAngleScan setValue 1
	$this SecAngleScan setTracking 0
	$this SecAngleScan hide
	
	$this setVar wasActevated 0 
	$this setVar isLines [list 0 0 0 0]
	$this setVar plane_origin 0
	$this setVar plane_normal 0
	$this setVar projectionMatrix 0
	$this setVar palmDir 0
	$this setVar linesProjections [lrepeat [getLineNum] 0]
	$this setVar palmDirVectorInplane 0
	$this setVar pcaLength 0
	$this setVar pcaDir 0
	
	$this newPortDoIt action
}

$this proc show_sec_advanced {} {
	if {[$this SecOpt isVisible] == 0} { 
		$this SecOpt show
		$this SecAngleScan show
	} else { 
		$this SecOpt hide
		$this SecAngleScan hide
	}
}

$this proc destructor {} { 
	remove my.scaphoid.SpreadSheet.am my.scaphoid.SpreadSheet.Cluster my.fracture.SpreadSheet my.fracture.Cluster
	remove my.ShapeAnalysis my.SpreadSheetToCluster planeFract my.plane_cluster my.PlaneObliqueSlice
	remove my.Annotation0 my.Annotation1 my.Annotation2  
	remove my.lineSet0 my.lineSet1 my.lineSet2 
	remove my.dispLine0 my.dispLine1 my.dispLine2 
	remove MesurementsSheet PointsSheet AnglesSheet
	remove Palm-Dir-in-plian Palm-Dir-in-plian.view
	for  {set  i 0} {$i < 3} {incr  i} {
		remove "[getLineName $i]-in-plane"
		remove "[getLineName $i]-in-plane.view"
	}
	remove my.scaphoid.surf my.surfacegen my.cylinderSurf my.cylinderSurfView
}

$this proc compute {} {
	if {[$this PointsCoordinates wasHit 0]} { $this pointxyz_table }
	if {[$this DistanceMesurements wasHit 0]} { $this distmes_table }
	if {[$this AnglesMesurements wasHit 0]} { $this angles_table }
	if {[$this SmallestEnclosingCylinder wasHit 0]} { $this show_sec_advanced }
	
	# Proceed only when 'apply' button was hit
  	if {![$this action wasHit]} {return}

	if {[exists [$this scaphoid source]] == 0} {
		echo "Object: scaphoid not found"
		return
	}
	if {[$this getVar wasActevated] == 1} {
		$this destructor
		$this setVar isLines [list 0 0 0 0]
		$this DistanceMesurements setSensitivity 0 0
		$this AnglesMesurements setSensitivity 0 0
		$this PointsCoordinates setSensitivity 0 0
	} 
	# 1 is Articular plane, 0 is fracture plane
	if {[$this CalculateAnglesOnplane getValue] == 1} {
		set planeLabel "Articular"
		if {[exists [$this ArticularPlaneMarkers source]] == 0} {
			echo "Object: ArticularPlaneMarkers not found"
			return
		}
	} else {
		set planeLabel "Fracture"
		if {[exists [$this fracture source]] == 0} {
			echo "Object: fracture not found"
			return
		}
	}

	$this createTables $planeLabel

	$this calcPCALine 
	$this calcSmallestEnclosingCylinderLine
	if {[exists [$this preMarkers source]] == 0} {
		echo "no calculating for pre-markers will be made (no preMarkers connected)"
	} else {
		$this calcPreLine
	}
		
	#get Palm diraction
	if {[exists [$this palmDirMarkers source]] == 0} {
		if { [$this PalmDirIfNoPalmDirMarkersAreGiven getValue] == 0 } { set palmDir [list 1 0 0] }
		if { [$this PalmDirIfNoPalmDirMarkersAreGiven getValue] == 1 } { set palmDir [list 0 1 0] }
		if { [$this PalmDirIfNoPalmDirMarkersAreGiven getValue] == 2 } { set palmDir [list 0 0 1] }
	} else {
		set palmDir [vectorFromDots [[$this palmDirMarkers source] getPoint 0] [[$this palmDirMarkers source] getPoint 1]]
		set palmDir [normalizeVector3 $palmDir]
	}
	$this setVar palmDir $palmDir
	echo "palm Dir is [$this getVar palmDir]"
	
	# 1 is Fract Plane
	if { [$this CalculateAnglesOnplane getValue] == 0 } {
		$this calcFractAngels
	} else {
		$this calcArctAngels
	}
	$this distanceMesurementsFunc 0
	$this calcAngelsInPlane 0
	$this setVar wasActevated 1 
	
	#enable bottons
	$this PointsCoordinates setSensitivity 0 1
	$this DistanceMesurements setSensitivity 0 1
	$this AnglesMesurements setSensitivity 0 1
}

$this proc calcArctAngels {} { 
	echo "Articular-Plane-Measurements"
	#-------------------------------------------Articular-Plane----------------------------------
	set x 0;	set y 0;	set z 0;
	set matrixA [list]
	set pointsNum [[$this ArticularPlaneMarkers source] getNumPoints]
	for {set i 0} {$i < $pointsNum} {set i [expr $i + 1]} {
		set point [[$this ArticularPlaneMarkers source] getPoint $i]
		lappend matrixA $point
		set x [expr $x + [lindex $point 0]]
		set y [expr $y + [lindex $point 1]]
		set z [expr $z + [lindex $point 2]]
	}
	#center's dot calculation.
	$this setVar plane_origin [list [expr $x / $pointsNum] [expr $y / $pointsNum] [expr $z / $pointsNum]]

	# fined plane normal accurding to lessed min squer (x = (AT*A)^-1 * AT * B)
	set vectorB [lrepeat $pointsNum 1]
	set AT [transpose $matrixA]
	set ATA [matrix_multiply $AT $matrixA]
	#todo deal with no inverse (maybe move a dot by 0.000001 will be easyest
	set ATAI [Inverse3 $ATA]
	set ATB [matrix_multiply $AT $vectorB]
	set plane_normal [matrix_multiply $ATAI $ATB]
	$this setVar plane_normal $plane_normal
	
	#v1 and v2 will be two normelized vector in the plane
	set DirNotNormal [list 1 0 0]
	if {[getMagnitude {*}[vector_cross $DirNotNormal $plane_normal]] < 0.00001} {
		set DirNotNormal [list 0 1 0]
	}
	set v1 [normalizeVector3 [vector_cross $DirNotNormal $plane_normal]]
	set v2 [normalizeVector3 [vector_cross $v1 $plane_normal]]
	$this setVar projectionMatrix [projection_to_plane_matrix $v1 $v2]
}

$this proc calcFractAngels {} {
	echo "Fracture-Plane-Measurements"
	#-------------------------------------------Fracture-Plane----------------------------------
	set hideNewModules 1
	create HxShapeAnalysis {planeFract}
	planeFract data connect [$this fracture source]
	planeFract fire
	planeFract fire
	planeFract hideIcon
	
	[ {planeFract} action hit ; {planeFract} fire ; {planeFract} getResult 
			 ] setLabel {my.fracture.SpreadSheet}
	my.fracture.SpreadSheet master connect planeFract 0
	my.fracture.SpreadSheet fire
	my.fracture.SpreadSheet fire
	
	create HxSpreadSheetToCluster {my.plane_cluster}
	my.plane_cluster data connect my.fracture.SpreadSheet
	my.plane_cluster fire
	
	{my.plane_cluster} action hit setLabel {my.fracture.Cluster}
	{my.plane_cluster} fire setLabel {my.fracture.Cluster}
	my.fracture.Cluster master connect my.plane_cluster
	my.fracture.Cluster fire
	$this setVar plane_origin [ my.fracture.Cluster getCenter ]
	$this setVar plane_normal [list [my.fracture.Cluster getDataValue 14 0] [my.fracture.Cluster getDataValue 15 0] [my.fracture.Cluster getDataValue 16 0]]
	set hideNewModules 0
	
	#E-vector 1,2 of fract
	set Ev1 [list [my.fracture.Cluster getDataValue 8 0] [my.fracture.Cluster getDataValue 9 0] [my.fracture.Cluster getDataValue 10 0]]
	set Ev2 [list [my.fracture.Cluster getDataValue 11 0] [my.fracture.Cluster getDataValue 12 0] [my.fracture.Cluster getDataValue 13 0]]
	$this setVar projectionMatrix [projection_to_plane_matrix $Ev1 $Ev2]
	
	my.fracture.SpreadSheet hideIcon
	my.plane_cluster hideIcon
	my.fracture.Cluster hideIcon
}

#this func should always be called with 0 first
$this proc calcAngelsInPlane {startingLine} {
	set plane_origin [$this getVar plane_origin]
	set plane_normal [$this getVar plane_normal]
	set projectionMatrix [$this getVar projectionMatrix]
	set palmDir [$this getVar palmDir]
	
	 if { $startingLine == 0 } {
		create HxObliqueSlice {my.PlaneObliqueSlice}
		set iconPos [$this getIconPosition]
		my.PlaneObliqueSlice setIconPosition [expr [lindex $iconPos 0] + 110] [lindex $iconPos 1]
		my.PlaneObliqueSlice data connect [$this scaphoid source]
		my.PlaneObliqueSlice fire
		my.PlaneObliqueSlice linearRange setValue 0 1
		my.PlaneObliqueSlice origin setValue 0 [lindex $plane_origin 0]  [lindex $plane_origin 1] [lindex $plane_origin 2] 
		my.PlaneObliqueSlice fire
		my.PlaneObliqueSlice normal setValue 0 [lindex $plane_normal 0]  [lindex $plane_normal 1] [lindex $plane_normal 2] 
		my.PlaneObliqueSlice fire
	
	#-------------------------------------------calculte-palm-Dir-Projection-------------------------------
		set palmDirVector [list]
		for  {set  i 0} {$i < 3} {incr  i} {
			lappend  palmDirVector [expr [lindex  $palmDir $i] * [[$this getVar spDist] getValue [expr [getLineNum] + 1 ] 1 ]]
		}
		set palmDirDot0 [addVector  $plane_origin $palmDirVector 1]
		set palmDirDot1 [addVector  $plane_origin $palmDirVector -1] 
	 
		set color [list 255 255 255]
		$this setVar palmDirVectorInplane [$this projectLine $palmDirDot0 $palmDirDot1 $plane_origin $plane_normal $projectionMatrix 280 "Palm-Dir-in-plian" $color]
		echo "palm Dir vector in plane is [$this getVar palmDirVectorInplane]"
	}
	
	#-------------------------------------------calculte-Projections-and-angels--------------------------
	set linesProjections [$this getVar linesProjections]
	
	for {set j $startingLine} {$j < [getLineNum]} {incr j} {
		if {[lindex [$this getVar isLines] $j] == 0} {
			continue
		}
		set point00 [getPointFromPointSP $j 0 [$this getVar spPoints]]
		set point01 [getPointFromPointSP $j 1 [$this getVar spPoints]]
		
		set color [getLineColor $j] 
		set lineName "[getLineName $j]-in-plane" 
		lset linesProjections $j [$this projectLine $point00 $point01 $plane_origin $plane_normal $projectionMatrix 300 $lineName $color]	
		
		#add angel with palm-Dir
		[$this getVar spAngle] setValue [expr 2 + [getLineNum]] $j [calcAngle [$this getVar palmDirVectorInplane] [lindex $linesProjections $j]]
		
		#add angel with plane
		[$this getVar spAngle] setValue [expr 1 + [getLineNum]] $j [expr 90 -[calcAngle $plane_normal [vectorFromDots $point00 $point01]]]
		
		if {$j == 0} {
			continue
		}
        for {set i 0} {$i < $j} {incr i} {
			if {[lindex [$this getVar isLines] $i] == 0} {
				continue
			}
			set angle [calcAngle [lindex $linesProjections $i] [lindex $linesProjections $j]]
			[$this getVar spAngle] setValue [expr $j + 1] $i $angle
			[$this getVar spAngle] setValue [expr $i + 1] $j $angle
        }

    }
	
	#save for next use
	$this setVar linesProjections $linesProjections
}
$this proc calcPreLine {} {
	echo "getting pre-markers"
	
	set prepoint0 [list {*}[[$this preMarkers source] getPoint 0]]
	set prepoint1 [list {*}[[$this preMarkers source] getPoint 1]]
	
	addLineToScreenAndPointSP $prepoint0 $prepoint1 [$this getVar spPoints] 0
	
	$this setVar isLines [lreplace [$this getVar isLines] 0 0 1]
}
$this proc pointxyz_table {} {
	if {[exists PointsSheet]} { 
		[$this getVar spPoints] show setValue 1
		set temp [[$this getVar spPoints] getValue 0 0]
		[$this getVar spPoints] setValue 0 0 $temp
	} else { 
		echo "Press apply to begin calculations." 
	}
}
$this proc distmes_table {} {
	if {[exists MesurementsSheet]} { 
		[$this getVar spDist] show setValue 1
		[$this getVar spDist] setValue 0 0 [getLineName 0]
	} else { 
		echo "Press apply to begin calculations." 
	}
}
$this proc angles_table {} {
	if {[exists AnglesSheet]} { 
		[$this getVar spAngle] show setValue 1
		[$this getVar spAngle] setValue 0 0 [getLineName 0]
	} else { 
		echo "Press apply to begin calculations." 
	}
}
$this proc createTables { planeLabel } {
	#---- SpreadSheet creation: spDist is for distances/lengths, spAngle is for fracture/articular measurements
	$this setVar spDist [create HxSpreadSheet {MesurementsSheet}]
	[$this getVar spDist] setIconPosition 500 30
	[$this getVar spDist] hideIcon
	$this setVar spAngle [create HxSpreadSheet {AnglesSheet}]
	[$this getVar spAngle] setIconPosition 500 70
	[$this getVar spAngle] hideIcon
	[$this getVar spDist] addColumn line string
	[$this getVar spAngle] addColumn line string
	for {set j 0} {$j < [getLineNum]} {incr j} {
        [$this getVar spDist] addColumn [getLineName $j] float
		[$this getVar spDist] setValue 0 $j "[getLineName $j]"
		[$this getVar spAngle] addColumn [getLineName $j] float
		[$this getVar spAngle] setValue 0 $j "[getLineName $j]"
    }
	[$this getVar spDist] addColumn "line Length" float
	[$this getVar spDist] addColumn "dist from farthest point" float
	[$this getVar spAngle] addColumn "angle with plane" float
	[$this getVar spAngle] addColumn "angle with palm direction" float
	for {set i 1} {$i < [expr 3 + [getLineNum]]} {incr i} {
		#j is row 
        for {set j 0} {$j < [getLineNum]} {incr j} {
            [$this getVar spDist] setValue $i $j 0
			[$this getVar spAngle] setValue $i $j 0
        }
    }

	
	$this setVar spPoints [create HxSpreadSheet {PointsSheet}]
	[$this getVar spPoints] setIconPosition 500 50
	[$this getVar spPoints] hideIcon
	[$this getVar spPoints] addColumn "Axis" string
	[$this getVar spPoints] addColumn "X" string
	[$this getVar spPoints] addColumn "Y" string
	[$this getVar spPoints] addColumn "Z" string
	for {set i 0} {$i < [getLineNum]} {incr i} {
		[$this getVar spPoints] setValue 0 [expr $i * 2] "[getLineName $i] Point (0)"
		[$this getVar spPoints] setValue 0 [expr $i * 2 + 1] "[getLineName $i] Point (1)"
	}
	for {set i 1} {$i < [getLineNum]} {incr i} {
		#j is row 
        for {set j 0} {$j < 8} {incr j} {
            [$this getVar spPoints] setValue $i $j 0
        }
    }
	
}

proc getPointFromPointSP {index pointNum spPoint } {
	set r [list]
	for {set i 1} {$i < 4} {incr i} {
		lappend r [$spPoint getValue $i [expr $index * 2 + $pointNum]]
	}
	return $r
}

#adds the line to the screen and points spread Sheet
#creats the objects: "my.lineSet$lineIndex" "my.dispLine$lineIndex" "my.Annotation$lineIndex"
proc addLineToScreenAndPointSP {point0 point1 spPoint lineIndex} {
	set preOL [create HxLineSet "my.lineSet$lineIndex"]
	$preOL setIconPosition 20 [expr 60 + 20 * $lineIndex]
	
	set p1 [$preOL addPoint {*}$point0]
	set p2 [$preOL addPoint {*}$point1]

	$spPoint setValue 1 [expr $lineIndex * 2] [lindex $point0 0]
	$spPoint setValue 2 [expr $lineIndex * 2] [lindex $point0 1]
	$spPoint setValue 3 [expr $lineIndex * 2] [lindex $point0 2]
	$spPoint setValue 1 [expr $lineIndex * 2 + 1] [lindex $point1 0]
	$spPoint setValue 2 [expr $lineIndex * 2 + 1] [lindex $point1 1]
	$spPoint setValue 3 [expr $lineIndex * 2 + 1] [lindex $point1 2]
	
	$preOL addLine $p1 $p2
	set line [create HxDisplayLineSet "my.dispLine$lineIndex"]
	$line setIconPosition 130 [expr 60 + 20 * $lineIndex]
	$line data connect $preOL
	#----Set line properties
	$line shape setIndex 0 6
	$line circleComplexity setValue 30
	$line scaleFactor setValue 0.5
	$line setLineColor {*}[getLineColor $lineIndex]
	$line hideIcon
	#---Set Legend properties
	set legend [create HxAnnotation "my.Annotation$lineIndex]"]
	$legend setIconPosition 232 [expr 61 + 20 * $lineIndex]
	set labelName "- [getLineName $lineIndex]"
	$legend text setState $labelName
	$legend font setState name: {Helvetica} size: 14 bold: 1 italic: 0 color: {*}[getLegendColor $lineIndex]
	$legend position setValue 1 [expr -5 - 15 * $lineIndex]
	$legend fire
	$legend hideIcon
	
	$preOL hideIcon
	$line fire
}

$this proc calcSmallestEnclosingCylinderLine {} {
	if { [$this SmallestEnclosingCylinderLine getValue 0] == 0 } {return}
	echo " ---------- calculating smallest enclosing cylinder line this will take a few minuts ------"
	set dir [string range [$this script getValue] 0 [string last / [$this script getValue]]]
	append dir "src/"
	set cFileName $dir
	append cFileName "sec.exe"
	set dllFileName $dir
	append dllFileName "CGAL-vc100-mt-gd-4.1.dll"
	if { [file exists $cFileName] == 0 || [file exists $dllFileName] == 0} { 
		echo "ERROR: No src dir with sec.exe executable and CGAL-vc100-mt-gd-4.1.dll found"
        return
    }
	set dll2FileName $dir
	append dll2FileName "msvcp100.dll"
	set dll3FileName $dir
	append dll3FileName "msvcr100.dll"
	if { [file exists $dll2FileName] == 0 || [file exists $dll3FileName] == 0} { 
		echo "ERROR: No src dir with msvcr100.dll and msvcp100.dll found"
        return
    }
	set prevLoc [pwd]
	cd $dir
	
	# create SurfaceGen for scaphoid, which is [$this scaphoid source]]
	set surfacegen [create HxGMC {my.surfacegen}]
	$surfacegen hideIcon
	$surfacegen data connect [$this scaphoid source]
	if { [$this SecOpt getValue 0] == 0 } {
		echo "no surface optimization"
		$surfacegen minEdgeLength setValue 0 0
	} else {
		echo "using surface optimization"
		#0.8 is the maximum for minEdgeLength
		$surfacegen minEdgeLength setValue 0 0.8
	}
	$surfacegen fire
	set sca_surf [$surfacegen create]
	$sca_surf hideIcon
	$sca_surf master connect $surfacegen
	$sca_surf setLabel my.scaphoid.surf
	
	set precision [$this SecAngleScan getValue]
	set  estematedTime [expr round(([my.scaphoid.surf getNumPoints]/1000) * (1/$precision)**2)]
	if { [$this SecOpt getValue 1] == 1 } {
		set  estematedTime [expr $estematedTime/4.0]
		if { $estematedTime == 0} {
			set $estematedTime 1
		}
	}
	if { [theMsg warning "Calculating Smallest Enclosing Cylinder.
Please note that Amira will seem not responding.
This will last for approximately $estematedTime minutes" "OK" "don't calculate SEC"] == 1 } { 
		$this SmallestEnclosingCylinderLine setValue 0 0
		return 
	}
	
	# write surfacegen points into file tmp_io.txt
	set ioFileName $dir
	append ioFileName "tmp_io.txt"
	
	# open the filename for writing
	set fileId [open $ioFileName "w"]
	#the first number is the number of point in surf
	puts -nonewline $fileId [my.scaphoid.surf getNumPoints]
	puts -nonewline $fileId "\n"
	for {set i 0} {$i < [my.scaphoid.surf getNumPoints]} {incr i} {
		puts -nonewline $fileId [my.scaphoid.surf getPoint $i]
		puts -nonewline $fileId " \n"
	}
	
	set pcaOptFlag "--pca_opt=false"
	if { [$this SecOpt getValue 1] == 1 } {
		set pcaOptFlag "--pca_opt=true"
		puts -nonewline $fileId [$this getVar pcaDir]
		puts -nonewline $fileId " \n"
	}
	close $fileId
	
	echo "executing: $cFileName $precision $pcaOptFlag"
	set startTime [clock seconds]
	exec $cFileName $precision $pcaOptFlag
	echo "$cFileName runtime: [expr [clock seconds] - $startTime] secounds"
	
	#get results from file
	set oFileName $dir
	append oFileName "tmp_io_res.txt"
	set fp [open $oFileName r]
    set file_data [read $fp]
    close $fp
	set res_data [split $file_data]
	set secBasePoint [list [lindex $res_data 2] [lindex $res_data 3] [lindex $res_data 4]]
	set secDir [list [lindex $res_data 6] [lindex $res_data 7] [lindex $res_data 8]]
	set secBasePoint [$this findScaph $secBasePoint $secDir]

	set SEC_point0 [$this computeDot $secBasePoint $secDir 1 8]
	set SEC_point1 [$this computeDot $secBasePoint $secDir -1 8]

	addLineToScreenAndPointSP $SEC_point0 $SEC_point1 [$this getVar spPoints] 2	
	$this setVar isLines [lreplace [$this getVar isLines] 2 2 1]
	file delete $oFileName
	file delete $ioFileName
	cd $prevLoc
}
$this proc calcPCALine {} {
	echo "calculating PCA line"
	
	create HxShapeAnalysis {my.ShapeAnalysis}
	my.ShapeAnalysis hideIcon
	my.ShapeAnalysis setIconPosition 160 204
	my.ShapeAnalysis data connect [$this scaphoid source]
	my.ShapeAnalysis fire
	my.ShapeAnalysis fire
	[ {my.ShapeAnalysis} action hit ; {my.ShapeAnalysis} fire ; {my.ShapeAnalysis} getResult 
	 ] setLabel {my.scaphoid.SpreadSheet.am}
	my.scaphoid.SpreadSheet.am setIconPosition 20 234
	my.scaphoid.SpreadSheet.am master connect my.ShapeAnalysis 0
	my.scaphoid.SpreadSheet.am hideIcon
	my.scaphoid.SpreadSheet.am fire
	my.scaphoid.SpreadSheet.am fire

	create HxSpreadSheetToCluster {my.SpreadSheetToCluster}
	my.SpreadSheetToCluster hideIcon
	my.SpreadSheetToCluster setIconPosition 160 264
	my.SpreadSheetToCluster data connect my.scaphoid.SpreadSheet.am
	my.SpreadSheetToCluster fire
	my.SpreadSheetToCluster table setIndex 0 0
	my.SpreadSheetToCluster fire

	{my.SpreadSheetToCluster} action hit setLabel {my.scaphoid.Cluster.am}
	{my.SpreadSheetToCluster} fire setLabel {my.scaphoid.Cluster.am}
	my.scaphoid.SpreadSheet.Cluster setIconPosition 20 294
	my.SpreadSheetToCluster hideIcon
	my.scaphoid.SpreadSheet.Cluster master connect my.SpreadSheetToCluster
	my.scaphoid.SpreadSheet.Cluster fire
	
	set centerS [ my.scaphoid.SpreadSheet.Cluster getCenter ]
	set EVector1S [list [my.scaphoid.SpreadSheet.Cluster getDataValue 8 0] [my.scaphoid.SpreadSheet.Cluster getDataValue 9 0] [my.scaphoid.SpreadSheet.Cluster getDataValue 10 0]]
	my.scaphoid.SpreadSheet.Cluster hideIcon
	set pcaPoint1 [$this computeDot $centerS $EVector1S 1 8]
	set pcaPoint2 [$this computeDot $centerS $EVector1S -1 8]
	$this setVar pcaLength [getMagnitude {*}[vectorFromDots $pcaPoint1 $pcaPoint2]]
	$this setVar pcaDir [vectorFromDots $pcaPoint1 $pcaPoint2]
	
	addLineToScreenAndPointSP $pcaPoint1 $pcaPoint2 [$this getVar spPoints] 1
	
	$this setVar isLines [lreplace [$this getVar isLines] 1 1 1]
}

# puts the point's distance, sides is accurding to the reffPoint
$this proc putPointInReffOrderSP {i j point00 point01 point10 point11 reffPoint} {	
	if {[getDistance {*}$reffPoint {*}$point00] < [getDistance {*}$reffPoint {*}$point01]} {
		if {[getDistance {*}$reffPoint {*}$point10] < [getDistance {*}$reffPoint {*}$point11]} {
			#put in place and in mirror place
			[$this getVar spDist] setValue [expr $j + 1] $i [getDistance {*}$point00 {*}$point10]
			[$this getVar spDist] setValue [expr $i + 1] $j [getDistance {*}$point01 {*}$point11]
		} else {
			[$this getVar spDist] setValue [expr $j + 1] $i [getDistance {*}$point00 {*}$point11]
			[$this getVar spDist] setValue [expr $i + 1] $j [getDistance {*}$point01 {*}$point10]
		}
	} else {
		if {[getDistance {*}$reffPoint {*}$point10] < [getDistance {*}$reffPoint {*}$point11]} {
			#put in place and in mirror place
			[$this getVar spDist] setValue [expr $j + 1] $i [getDistance {*}$point01 {*}$point10]
			[$this getVar spDist] setValue [expr $i + 1] $j [getDistance {*}$point00 {*}$point11]
		} else {
			[$this getVar spDist] setValue [expr $j + 1] $i [getDistance {*}$point01 {*}$point11]
			[$this getVar spDist] setValue [expr $i + 1] $j [getDistance {*}$point00 {*}$point10]
		}
	}
}

$this proc distanceMesurementsFunc {startingLine} {
	set reffPcaPoint [getPointFromPointSP 1 0 [$this getVar spPoints]]
	for {set j $startingLine} {$j < [getLineNum]} {incr j} {
		if {[lindex [$this getVar isLines] $j] == 0} {
			continue
		}
		set point00 [getPointFromPointSP $j 0 [$this getVar spPoints]]
		set point01 [getPointFromPointSP $j 1 [$this getVar spPoints]]
		[$this getVar spDist] setValue 5 $j [getDistance {*}$point00 {*}$point01]
		if {$j == 0} {
			continue
		}
        for {set i 0} {$i < $j} {incr i} {
			if {[lindex [$this getVar isLines] $i] == 0} {
				continue
			}
			set point10 [getPointFromPointSP $i 0 [$this getVar spPoints]]
			set point11 [getPointFromPointSP $i 1 [$this getVar spPoints]]
			$this putPointInReffOrderSP $i $j $point00 $point01 $point10 $point11 $reffPcaPoint	
        }

    }
	
	if { [$this SmallestEnclosingCylinderLine getValue 0] == 0} {return}
	set startTime [clock seconds]
	for {set j $startingLine} {$j < [getLineNum]} {incr j} {
		if {[lindex [$this getVar isLines] $j] == 0} {
			continue
		}
		set point0 [getPointFromPointSP $j 0 [$this getVar spPoints]]
		set point1 [getPointFromPointSP $j 1 [$this getVar spPoints]]
		set maxDist -1
		for {set i 0} {$i < [my.scaphoid.surf getNumPoints]} {incr i} {
			set surfP [my.scaphoid.surf getPoint $i]
			set dist [distanceLinePoint $point0 $point1 $surfP]
			if { $dist > $maxDist } {
				set maxDist $dist
			}
		}
		[$this getVar spDist] setValue [expr 2 + [getLineNum]] $j $maxDist
	}
	echo "find farthest dist runtime: [expr [clock seconds] - $startTime] secounds"
	
	#todo sss
	if { [exists my.cylinderSurfView]} {return}
	set sec0 [getPointFromPointSP 2 0 [$this getVar spPoints]] 
	set sec1 [getPointFromPointSP 2 1 [$this getVar spPoints]]
	set hight [getDistance {*}$sec0 {*}$sec1]
	set radius [[$this getVar spDist] getValue [expr 2 + [getLineNum]] 2]
	
	set surface [create HxSurface]
	for {set theta 0} {$theta < [expr 3.14159 * 2]} {set theta [expr $theta + (3.14159 / 180)]} {
		$surface add -point [expr cos($theta)] [expr sin($theta)] 0
		$surface add -point [expr cos($theta)] [expr sin($theta)] 1
	}
	set p0down [$surface add -point 0 0 0]
	set p0up [$surface add -point 0 0 1]
	set circlePoints [expr [$surface getNumPoints] - 2]
	for {set i 0} {$i < $circlePoints} {set i [expr $i + 2]} {
		#dots are of sets of down1 up1 down2 up2 
		$surface add -triangle $p0down $i [expr ($i + 2) % $circlePoints]
		$surface add -triangle $p0up [expr $i + 1] [expr ($i + 3) % $circlePoints]
		#down1 up1 down2
		$surface add -triangle [expr $i + 1] $i [expr ($i + 2) % $circlePoints]
		#up1 down2 up2
		$surface add -triangle [expr $i + 1] [expr ($i + 2) % $circlePoints] [expr ($i + 3) % $circlePoints]
	}
	set surfView [create HxDisplaySurface]
	$surfView data connect $surface 
	$surfView fire
	
	#move to pos
	$surface setTransform $radius 0 0 0 0 $radius 0 0 0 0 $hight 0 0 0 0 1
	$surface applyTransform
	#add turn
	set secDir [vectorFromDots $sec0 $sec1]
	set curCylinderDir [list 0 0 1]
	set rotationVec [vector_cross $curCylinderDir $secDir]
	if {[getMagnitude {*}$rotationVec] < 0.00001} {
		#they are in the same dir or - dir
		if { [lindex $secDir 2] < 0 } {
			#180 turn
			set phi 3.14159
			$surface setTransform 1 0 0 0 0 [expr cos($phi)] [expr -sin($phi)] 0 0 [expr sin($phi)] [expr cos($phi)] 0 0 0 0 1
			$surface applyTransform
		}
	} else {
		set rotationVec [normalizeVector3 $rotationVec]
		set angel [calcTrueAngle $secDir $curCylinderDir]
		set cosA [expr cos($angel)]
		set sinA [expr -sin($angel)]
		set ux [lindex $rotationVec 0]
		set uy [lindex $rotationVec 1]
		set uz [lindex $rotationVec 2]
		$surface setTransform [expr $cosA + $ux*$ux*(1-$cosA)] [expr $ux*$uy*(1-$cosA) - $uz*$sinA] [expr $ux*$uz*(1-$cosA) + $uy*$sinA] 0 [expr $uy*$ux*(1-$cosA) + $uz*$sinA] [expr $cosA + $uy*$uy*(1-$cosA)] [expr $uy*$uz*(1-$cosA) - $ux*$sinA] 0 [expr $uz*$ux*(1-$cosA) - $uy*$sinA] [expr $uz*$uy*(1-$cosA) + $ux*$sinA] [expr $cosA + $uz*$uz*(1-$cosA)] 0 0 0 0 1
		#the mat:
		#[expr $cosA + $ux*$ux*(1-$cosA)] [expr $ux*$uy*(1-$cosA) - $uz*$sinA] [expr $ux*$uz*(1-$cosA) + $uy*$sinA] 0
		#[expr $uy*$ux*(1-$cosA) + $uz*$sinA] [expr $cosA + $uy*$uy*(1-$cosA)] [expr $uy*$uz*(1-$cosA) - $ux*$sinA] 0
		#[expr $uz*$ux*(1-$cosA) - $uy*$sinA] [expr $uz*$uy*(1-$cosA) + $ux*$sinA] [expr $cosA + $uz*$uz*(1-$cosA)] 0 
		#0 0 0 1
		$surface applyTransform
	}
	$surface setTransform 1 0 0 0 0 1 0 0 0 0 1 0 [lindex $sec0 0] [lindex $sec0 1] [lindex $sec0 2] 1
	$surface applyTransform

	$surface hideIcon
	set iconPos [$this getIconPosition]
	$surfView setIconPosition [lindex $iconPos 0] [expr [lindex $iconPos 1] + 20]
	$surfView drawStyle setValue 4
	$surfView fire
	$surface setLabel "my.cylinderSurf"
	$surfView setLabel "my.cylinderSurfView"

	
}

#this function creates HxLineSet:$label  HxDisplayLineSet:$label.view
$this proc projectLine {point0 point1 plane_origin plane_normal projectionMatrix placeInPool label color} {
	set v [vectorFromDots $point0 $point1]
	#this should be the vector between 2 points (needs to be done for each line)
	set vectorInplane [mul_matrix_vector $projectionMatrix $v]	
	set dotInplane [intersectionplaneLine $plane_origin $plane_normal $point0 $v]
		
	set line_in_fratc [create HxLineSet]
	$line_in_fratc hideIcon
	$line_in_fratc setIconPosition 20 $placeInPool
	set p1 [$line_in_fratc addPoint {*}[addVector $dotInplane $vectorInplane -1]]
	set p2 [$line_in_fratc addPoint {*}[addVector $dotInplane $vectorInplane 1]]
	$line_in_fratc addLine $p1 $p2
	set v_line_in_fract [create HxDisplayLineSet]
	$v_line_in_fract hideIcon
	$v_line_in_fract setIconPosition 130 $placeInPool
	$v_line_in_fract data connect $line_in_fratc
	#----Set line properties
	$v_line_in_fract shape setIndex 0 1
	$v_line_in_fract setLineColor {*}$color
	$v_line_in_fract fire
	$line_in_fratc setLabel $label
	$v_line_in_fract setLabel "$label.view"
	
	return $vectorInplane
}


#returns the 3-dimensional distance between two points
proc getDistance {x0 y0 z0 x1 y1 z1} {
	set sum [expr ($x0 - $x1)**2 + ($y0 - $y1)**2 + ($z0 - $z1)**2]
	set sum [expr sqrt($sum)]
	return $sum
}
#finds the fartest point from c inside the scaphoid
#in the diraction of v.
#if dir is -1 then it's the direction of -v
#precision + 1 = number of digits after the dots that the multiplier of v will have
$this proc computeDot {c v dir precision} {
	#if out is 1 then we are outside the scaphoid
	set out 0 
	set outL [list]
	if {$dir != -1} {
		set dir 1
	}
	set mult 0
	for {set i 0} {$i < $precision} {set i [expr $i + 1]} {
		set factor {0.1 ** $i}
		set out 0 
		while {$out == 0} {
			set outL [list]
			foreach j {0 1 2} {
				lappend outL [expr [lindex $c $j] + [expr [lindex $v $j] * [expr $dir * $mult]]]
			}
			if {[[$this scaphoid source] eval [lindex $outL 0]  [lindex $outL 1]  [lindex $outL 2]] == 0} {
				set out 1
			} else {
				set mult [expr $mult + $factor]
			}
		}
		set mult [expr $mult - $factor]
	}
	set outL [list]
	foreach j {0 1 2} {
		lappend outL [expr [lindex $c $j] + [expr [lindex $v $j] * [expr $dir * $mult]]]
	}
	return [list [lindex $outL 0]  [lindex $outL 1]  [lindex $outL 2]]
}
#finds a point from base in dir diraction inside the scaphoid
#jumps accurding to 0.1*length(dir)*pcaLength up to 100 in each diraction
$this proc findScaph {base dir} {
	#if out is 1 then we are outside the scaphoid
	set mult 0
	set outL [list]
	set jump [expr [$this getVar pcaLength] * 0.1 ]
	
	for {set i 0} {$i < 200} {incr i}  {
		set outL [list]
		foreach j {0 1 2} {
			lappend outL [expr [lindex $base $j] + [expr [lindex $dir $j] * $mult * $jump]]
		}
		if {[[$this scaphoid source] eval [lindex $outL 0]  [lindex $outL 1]  [lindex $outL 2]] == 1} {
			break
		}
		if {$mult > 0 } {
			set mult [expr $mult * -1]
		} else {
			set mult [expr $mult * -1]
			set mult [expr $mult + 1]
		}
	}
	return [list [lindex $outL 0]  [lindex $outL 1]  [lindex $outL 2]]
}



# --------===========MatrixLibrary==========---------------


proc intersectionplaneLine {plane_origin plane_normal line_point line_vector} {
	#d of the plane
	set d [getProduct {*}$plane_normal {*}$plane_origin]
	set numerator [expr $d - [lindex $plane_normal 0] * [lindex $line_point 0] - [lindex $plane_normal 1] * [lindex $line_point 1] - [lindex $plane_normal 2] * [lindex $line_point 2]]
	set denominator [expr [lindex $plane_normal 0] * [lindex $line_vector 0] + [lindex $plane_normal 1] * [lindex $line_vector 1] + [lindex $plane_normal 2] * [lindex $line_vector 2]]
	set t [expr $numerator / $denominator]
	set p [list]
	foreach j {0 1 2} {
		lappend p [expr [lindex $line_point $j] + $t * [lindex $line_vector $j]]
	}
	return $p
}

#does b - a
proc vectorFromDots {a b} {
	set v [list]
	foreach j {0 1 2} {
		lappend v [expr [lindex $b $j] - [lindex $a $j]]
	}
	return $v
}

#does a + b * dir
proc addVector {a b dir} {
	set v [list]
	foreach j {0 1 2} {
		lappend v [expr [lindex $a $j] + $dir * [lindex $b $j]]
	}
	return $v
}

#calc angle between vectors a,b in radians
proc calcTrueAngle {a b} {
	set product [getProduct {*}$a {*}$b]
	set a_magnitude [getMagnitude {*}$a]
	set b_magnitude [getMagnitude {*}$b]
	set ab_angle [expr acos($product / ($a_magnitude * $b_magnitude))]
	return $ab_angle
}

#calc smaller angle between vectors a,b in degrees
proc calcAngle {a b} {
	set product [getProduct {*}$a {*}$b]
	set a_magnitude [getMagnitude {*}$a]
	set b_magnitude [getMagnitude {*}$b]
	set ab_angle [getAngle $product $a_magnitude $b_magnitude]
	if { $ab_angle > 90 } {
		set ab_angle [expr 180 - $ab_angle] 
	}
	return $ab_angle
}
proc getProduct {x0 y0 z0 x1 y1 z1} {
	set sum [expr ($x0 * $x1) + ($y0 * $y1) + ($z0 * $z1)]
	return $sum
}

proc getMagnitude {x y z} {
	set sum [expr $x ** 2 + $y ** 2 + $z ** 2]
	set sum [expr sqrt($sum)]
	return $sum
}

proc getAngle {numerator a_mag b_mag} {
	set denominator [expr $a_mag * $b_mag]
	set res [expr $numerator / $denominator]
	set res [expr acos($res)]
	#1 rad = 57.2957795 degrees
	return [expr $res * 57.2957795]
}
#vectors a and b are teh diraction of the plane, and should be vertical and nurmlized
#this is acurding to "Gramian matrix".
proc projection_to_plane_matrix {a b} {
    set res [lrepeat 3 [lrepeat 3 0]]
    for {set i 0} {$i < 3} {incr i} {
        for {set j 0} {$j < 3} {incr j} {
            lset res $i $j [expr [expr [lindex $a $i] * [lindex $a $j]] + [expr [lindex $b $i] * [lindex $b $j]]]
        }
    }
    return $res
}


#all are lists M is 3x3
proc mul_matrix_vector {M v} {
    set res [lrepeat 3 0]
    for {set i 0} {$i < 3} {incr i} {
		set sum 0
        for {set j 0} {$j < 3} {incr j} {
            set sum [expr $sum + [expr [lindex $M $i $j] * [lindex $v $j]]]
        }
		lset res $i $sum
    }
    return $res
}





# asume lines inside a matrix has the same size.
# taken from the internet but modufied to work in Amira's TCL
proc matrix_multiply {a b} {
	set a_rows [llength  $a]
	set a_cols [llength  [lindex  $a 0]]
	set b_rows [llength  $b]
	set b_cols [llength  [lindex  $b 0]]
    if {$a_cols != $b_rows} {
        error "incompatible sizes: a($a_rows, $a_cols), b($b_rows, $b_cols)"
    }
    set temp [lrepeat $a_rows [lrepeat $b_cols 0]]
    for {set i 0} {$i < $a_rows} {incr i} {
        for {set j 0} {$j < $b_cols} {incr j} {
            set sum 0
            for {set k 0} {$k < $a_cols} {incr k} {
                set sum [expr $sum + [expr [lindex $a $i $k] * [lindex $b $k $j]]]
            }
            lset temp $i $j $sum
        }
    }
    return $temp
}

# taken from the internet checked by us
 proc  Inverse3 {matrix} {
    if  {[llength  $matrix] != 3 ||
        [llength  [lindex  $matrix 0]] != 3 || 
        [llength  [lindex  $matrix 1]] != 3 || 
        [llength  [lindex  $matrix 2]] != 3} {
        error  "wrong sized matrix"
    }
    set  inv {{? ? ?} {? ? ?} {? ? ?}}
 
    # Get adjoint matrix : transpose of cofactor matrix
    for  {set  i 0} {$i < 3} {incr  i} {
        for  {set  j 0} {$j < 3} {incr  j} {
            lset  inv $i $j [_Cofactor3 $matrix $i $j]
        }
    }
    # Now divide by the determinant
    set  det [expr  {double([lindex  $matrix 0 0]   * [lindex  $inv 0 0]
                   + [lindex  $matrix 0 1] * [lindex  $inv 1 0]
                   + [lindex  $matrix 0 2] * [lindex  $inv 2 0])}]
    if  {$det == 0} {
        error  "non-invertable matrix"
    }
    
    for  {set  i 0} {$i < 3} {incr  i} {
        for  {set  j 0} {$j < 3} {incr  j} {
            lset  inv $i $j [expr  {[lindex  $inv $i $j] / $det}]
        }
    }
    return  $inv
 }
 # taken from the internet checked by us
 proc  _Cofactor3 {matrix i j} {
    array set  COLS {0 {1 2} 1 {0 2} 2 {0 1}}
    foreach  {row1 row2} $COLS($j) break 
    foreach  {col1 col2} $COLS($i) break 
    
    set  a [lindex  $matrix $row1 $col1]
    set  b [lindex  $matrix $row1 $col2]
    set  c [lindex  $matrix $row2 $col1]
    set  d [lindex  $matrix $row2 $col2]
 
    set  det [expr  {$a*$d - $b*$c}]
    if  {($i+$j) & 1} { set  det [expr  {-$det}]}
    return  $det
 }
 
 # asume lines inside a matrix has the same size.
# taken from the internet but modufied to work in Amira's TCL
proc transpose {m} {
	set rows [llength  $m]
	set cols [llength  [lindex  $m 0]]
    set new [lrepeat $cols [lrepeat $rows ""]]
    for {set i 0} {$i < $rows} {incr i} {
        for {set j 0} {$j < $cols} {incr j} {
            lset new $j $i [lindex $m $i $j]
        }
    }
    return $new
}

proc normalizeVector3 {v} {
	set nurm [getMagnitude {*}$v]
	set nurmV [list]
	for {set i 0} {$i < 3} {incr i} {
		lappend nurmV [expr [lindex $v $i] / $nurm]
	}
	return $nurmV
}

# taken from the internet
proc vector_cross {A B} {
    lassign $A a1 a2 a3
    lassign $B b1 b2 b3
    list [expr {$a2*$b3 - $a3*$b2}] \
	 [expr {$a3*$b1 - $a1*$b3}] \
	 [expr {$a1*$b2 - $a2*$b1}]
}


# t - Transform (4x4 matrix in list 1x16 form, column by column)
#     the last row should be 0,0,0,1
# p - point (list x,y,z)
# calculates the transformed point. 
proc Transform44 {t p} {
	#create 4x4 matrix 
	set  m {{? ? ? ?} {? ? ? ?} {? ? ? ?} {? ? ? ?}}
	set tIndex 0
    for  {set  i 0} {$i < 4} {incr  i} {
        for  {set  j 0} {$j < 4} {incr  j} {
            lset  m $j $i [lindex $t $tIndex]
			incr tIndex
        }
    }
	
	# the fourth coordinate should be 1 when using 4x4 Transform
	set v [list [lindex $p 0] [lindex $p 1] [lindex $p 2] 1]
	
	set tempR [matrix_multiply $m $v]
	
	#dropping the fourth coordinate
	set r [list]
	for  {set  j 0} {$j < 3} {incr  j} {
       lappend r [lindex $tempR $j]
    }
	return $r
}

proc distanceLinePoint { lp0 lp1 p } {
	set v [vectorFromDots $lp1 $lp0]
	set w [vectorFromDots $lp0 $p]
	set c1 [getProduct {*}$w {*}$v]
	set c2 [getProduct {*}$v {*}$v]
	#pb is dot on line
	set t [expr (1.0 * $c1)/$c2]
	set pb [addVector $lp0 $v $t]
	return [getMagnitude {*}[vectorFromDots $pb $p]]
}

proc getPhi { p1 p2 } {
	set v [vectorFromDots $p1 $p2]
	set mag [getMagnitude {*}$v]
	return [expr acos([lindex $v 2]/$mag)]
}
proc getTheta { p1 p2 } {
	set v [vectorFromDots $p1 $p2]
	if {[lindex $v 0] == 0} { 
		return [expr 3.14159265 / 4]
	}
	return [expr atan([lindex $v 1]/[lindex $v 0])]
}