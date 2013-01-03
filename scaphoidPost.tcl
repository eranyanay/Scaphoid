# Amira-Script-Object V3.0


$this proc constructor {} {
	
	$this newPortConnection scaphPre HxScriptObject
	$this newPortConnection postScaphoid HxUniformLabelField3
	$this newPortConnection postMarkers HxLandmarkSet
	
	$this setVar wasPostActevated 0 
	
	$this newPortDoIt action
}
$this proc destructor {} {
	remove my.affineReg
	remove my.lineSet3 my.Annotation3 my.dispLine3
	remove "[getLineName 3]-in-plane"
	remove "[getLineName 3]-in-plane.view"
}

$this proc compute {} {
  	# Proceed only when 'apply' button was hit
  	if {![$this action wasHit]} {return}
	if {[$this getVar wasPostActevated] == 1} {
		$this destructor
	} 
	if {[exists [$this scaphPre source]] == 0} {
		echo "Object: scaphoidPre not found"
		return
	}
	if {[[$this scaphPre source] getVar wasActevated] == 0} {
		echo "Object: scaphoidPre wasn't actevated"
		return
	}
	if {[exists [$this postMarkers source]] == 0} {
		echo "Object: post markers not found"
		return
	}
	if {[exists [$this postScaphoid source]] == 0} {
		echo "Object: post scaphoid not found"
		return
	}
	
	# move to common plane
	$this postScaphoidRegFunc
	
	set post_point0 [ Transform44 [[$this postScaphoid source] getTransform] [[$this postMarkers source] getPoint 0]]
	set post_point1 [ Transform44 [[$this postScaphoid source] getTransform] [[$this postMarkers source] getPoint 1]]
	
	addLineToScreenAndPointSP $post_point0 $post_point1 [[$this scaphPre source] getVar spPoints] 3
	
	[$this scaphPre source] setVar isLines [lreplace [[$this scaphPre source] getVar isLines] 3 3 1]
	[$this scaphPre source] distanceMesurementsFunc 3
	[$this scaphPre source] calcAngelsInPlane 3
	
	$this setVar wasPostActevated 1 
} 

$this proc postScaphoidRegFunc { } {
	set rgstr [create HxAffineRegistration {my.affineReg}]
	$rgstr reference connect [[$this scaphPre source] scaphoid source]
	$rgstr model connect [$this postScaphoid source]
	$rgstr action hit 0
	$rgstr fire
	$rgstr action hit 1
	$rgstr fire
	$rgstr action hit 2
	$rgstr fire
	$rgstr hideIcon
	
	# can't be in distractor because ot the this
	remove "[$this postScaphoid source].Resampled"
	remove "[[$this scaphPre source] scaphoid source].Resampled"
}

