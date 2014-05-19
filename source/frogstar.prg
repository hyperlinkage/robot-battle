Init {
// initialise robot

    name( "Frogstar Scout Robot" )
    version( "0.01" )

    // initialise robot state    
    blocking( false )
    lockgun( true )
    
    // register event handlers
    regcore( Core )    
    regdtcmine( FoundMine, 5 )
    regdtcrobot( FoundRobot, 4 )
    regdtccookie( FoundCookie, 3 )
}

Core {
// called whenever theres nothing better to do

    gosub( GetGameType )
    gosub( GetRobotState )
    
    scan()
    radarright( 7 )
}

FoundRobot {
// spotted a robot with the radar
    
    gosub( GetGameType )
    gosub( GetRobotState )

    stoprotate()

    if( doAttack ) 
        if( isDual || isFFA || _teamid != _dtcteamid )
        // if no teams exist, or target is an opposing team    
            
            gosub( ShootTarget )       
            gosub( FollowTarget )       
            scan()        
        else
            // spotted an ally
            // probably dont want to shoot them
        endif
    endif
}

FoundMine {
// spotted a mine with the radar

    if( _scandist < 150 )
    // if the mine is fairly close, destroy it
        fire( 1 )
    endif
}

FoundCookie {
// spotted a cookie with the radar
    
    if( _scandist < 200 )
    // if the cookie is fairly close, try to pick it up
        gosub( TurnTarget )
        ahead( moveDist )
        waitfor( _moving == false )            
    elseif( isTeamGame == false )
    // if im too far from the cookie, and its not a team game, destroy it
        fire( 1 )
    endif
}

TurnTarget {
// turns the robot to face the current target    

// a robot that can move forward or back need only turn 90 degrees 
// in order to move towards a target

    stoprotate()

    moveDist    = 0
    rotateDist  = 0

    // somethings not right here, but it will do for now    
    
    if( _dtcbearing < 90 )
    // turn right, move forward
        rotateDist = _dtcbearing           
        moveDist = _scandist + 5
    elseif( _dtcbearing < 180 )
    // turn left, move backwards
        rotateDist =  180 - _dtcbearing
        moveDist = -( _scandist + 5 )
    elseif( _dtcbearing < 270 )
    // turn right, move backwards
        rotateDist = _dtcbearing - 180
        moveDist = -( _scandist + 5 )
    else
    // turn left, move forwards
        rotateDist =  _dtcbearing - 360
        moveDist = _scandist + 5
    endif 

    bodyright( rotateDist )
    waitfor( _rotating == false )
}

ShootTarget {
// fires a single shot at the current target of the robots radar

    if( _scandist > 250 )
    // if the target is some distance away, fire a weak shot
        fire( 1 )
    elseif( _scandist > 150 )
        fire( 4 )
    else
    // otherwise fire with maximum power
        fire( 7 )
    endif
}

FollowTarget {
// moves closer to current target

    gosub( TurnTarget )
    
    moveDist = 0

    if( _scandist > 250 )
        moveDist = _scandist / 2
    elseif( _scandist > 150 )
        moveDist = _scandist / 3
    endif
    
    if( moveDist > 0 ) 
        round( moveDist, 0 )
        ahead( _result )
        waitfor( _moving == false )
    endif    
}

GetRobotState {
    
    doAttack    = true
}

GetGameType {
// store some info about the game
    
    isDual      = false
    isTeamGame  = false
    isFFA       = false
        
    if( _robotsalive == 2 )
        // only two robots alive, it must be me and a single opponent
        isDual = true
    else 
        if( _teammembersalive >= 2 )
            // two or more members alive in my team
            isTeamGame = true
        else
            // otherwise, assume its free for all
            isFFA = true
        endif
    endif
}