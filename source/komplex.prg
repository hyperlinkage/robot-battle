//  The Mighty Komplex
//  Version 0.0.1
//
//  Named after K.O.M.P.L.E.X, the menial Toad mainframe turned mighty
//  genocidal dictator, from the classic cartoon Bucky O'Hare and the 
//  Toad Wars.
//
//  See end of file for development history.


Init {
    name( "The Mighty Komplex" )
    version( "0.0.1" )

    print( _name + " v" + _version )
    
    blocking( false )
    regcore( Core )
}

Core {
//  the core subroutine, called whenever the robot isnt responding to
//  an event of higher priority
   
    print( "------------------------------------" )   
    
    gosub( SetBotState )

    if( isPatrolling )
        gosub( PatrollingCore )
    elseif( isEngaged )
        gosub( EngagedCore )
    elseif( isDefending )
        gosub( DefendingCore )
    endif
}

PatrollingCore {
        
    print( "Patrolling" )

//  need to add code here to intelligently move about the arena
//  seeking enemies

    scan()
    radarright( 10 )
}    

PatrollingDtcRobot {

    print( "Detected robot" )
    print( "_scandist: "  + _scandist )
    print( "_dtcteamid: " + _dtcteamid )

    if( isTeamGame == false || _teamid != _dtcteamid )
        //  if not a team game, or detected robot is not on my team
        //  break off the patrol and engage the enemy
        isPatrolling = false
        isEngaged    = true
    endif
}

PatrollingDtcCookie {

    print( "Detected cookie" )
    print( "_scandist: "  + _scandist )

    if( _scandist < 150 )
        //  if relatively close to the cookie, pick it up
        gosub( PickupCookie )
    elseif( isTeamGame == false )
        //  if its a fair distance away, and its not a team game,
        //  fire a weak shot to destroy the cookie
        print( "Firing on cookie" )
        fire( 1 )
    endif
}

PatrollingDtcMine {

    print( "Detected mine" )
    print( "_scandist: "  + _scandist )

    if( _scandist < 100 )
        //  if the mine is fairly close, fire a weak shot to destroy it
        print( "Firing on mine" )
        fire( 1 )
    endif
}

EngagedCore {

    print( "Engaged" )

    //  scan to make sure the enemy is still in sight
    scan()
    
    if( _dtcrobot ) 
    else
        isEngaged = false
    endif
}

EngagedDtcRobot {

    print( "Detected robot" )
    print( "_scandist: "  + _scandist )
    print( "_dtcteamid: " + _dtcteamid )
    print( "Firing on enemy" )
    fire( 7 )
    scan()
}

DefendingCore {

    print( "Defending" )

    scan()
    radarright( 5 )
}

DefendingDtcCookie {

    print( "Detected cookie" )
    print( "_scandist: "  + _scandist )

    gosub( PickupCookie )
}

PickupCookie {

    print( "Picking up cookie" )
    
    
    # To avoid overshooting the cookie, I'll set my target destination
    # to be the current location. Since rotation will start before I
    # stop moving, my position will be a little off.
    # A more powerful and complex solution would be to call stopmove() 
    # and to then figure out the angle to the cookie from my new position.
    ahead( 0 )
    
    # Turn my body so that I'm facing the cookie. I could use syncall(),
    # but that won't always get me the shortest distance to rotate, because
    # it doesn't account for my ability to move backwards.

    destAngle = _radaraim
    startAngle = _bodyaim
    gosub( MinDegreesRight )
    
    # The most I should ever have to rotate in order to be pointing at the
    # cookie is 90 degrees. If I supposedly have to rotate more than 90, I
    # can rotate in the other direction and then move backwards.
    
    if( rightDegrees > 90 )
        rightDegrees = rightDegrees - 180
        movedir = -1
    elseif( rightDegrees < -90 )
        rightDegrees = rightDegrees + 180
        movedir = -1
    else
        movedir = 1
    endif

    bodyright( rightdegrees )
    
    # I'll stop rotating my gun so I'll be able to fight off anyone else
    # who is attempting to take the cookie.
    
    ahead(( _scandist + 15 ) * movedir )
    movedist = _distrmn
    movedir = -movedir    
    
}


SetBotState {
//  registers event handlers and a few global properties, based upon 
//  the current state of the game and the robot

    gosub( GetGameState )
    gosub( GetBotState )

    if( isPatrolling )
        lockgun        ( true )
        //  set event handlers and priorities
        //  while patrolling, the robot will respond to all events
        regdtcrobot    ( PatrollingDtcRobot,  1 )
        regdtccookie   ( PatrollingDtcCookie, 2 )
        regdtcmine     ( PatrollingDtcMine,   3 )    
        dtcrobotevents ( true )
        dtccookieevents( true )
        dtcmineevents  ( true )
        
    elseif( isEngaged )
        lockgun        ( true ) 
        //  set robot detection to highest priority
        regdtcrobot    ( EngagedDtcRobot, 1 )
        dtcrobotevents ( true )
        dtccookieevents( false )
        dtcmineevents  ( false )
        
    elseif( isDefending )
        //  the robot is defending, which causes it to concentrate on 
        //  seeking out energy cookies and not attempt to fire on enemies
    
        //  unlock the gun to allow faster radar rotation
        lockgun        ( false )        
        //  set cookie detection to highest priority
        //  ignore robot or mine detection events
        regdtccookie   ( DefendingDtcCookie, 1 )
        dtccookieevents( true )            
        dtcrobotevents ( false )
        dtcmineevents  ( false )
    endif
}

GetBotState {
//  calculates the current state of the robot

    if( _energy <= 40 )
        isPatrolling = false
        isEngaged    = false
        isDefending  = true
    elseif( _energy >= 60 )
        if( isDefending )
            isPatrolling = true
            isDefending  = false   
        endif
    endif

    if( isPatrolling == false && isEngaged == false && isDefending == false )
        //  default to patrolling
        isPatrolling = true
    endif
}

GetGameState {
//  calculates the current state of the game, based upon the number 
//  of remaining participants 

    isDual      = false
    isTeamGame  = false
    isFFA       = false
        
    if( _robotsalive == 2 )
        // only two robots alive, it must be me and a single opponent
        isDual = true
        print( "isDual" )
    else 
        if( _teammembersalive >= 2 )
            // two or more members alive in my team
            isTeamGame = true
            print( "isTeamGame" )
        else
            // otherwise, assume its free for all
            isFFA = true
            print( "isFFA" )
        endif
    endif
}






# Useful subroutine that determines the minimum number of degrees 
# needed to reach 'destAngle' starting from 'startAngle'. Before being
# called, this section expects the following variables to be initialized
#   
#   startAngle - initial angle
#   destAngle - desired angle
#
# 'destAngle' and 'startAngle' can be any positive or negative value
#
# When complete, the section sets the 'rightDegrees' varable to the
# smallest number of degrees needed to reach 'destAngle' turning
# RIGHT. If the shortest distance is actually left, 'rightDegrees' will
# be negative.
#
MinDegreesRight
{
    # Use the modulus operator (%) to ensure the result is from -360 to 360
    difference = (destAngle - startAngle) % 360

    # Figure out how much would be needed to rotate right    
    rightDegrees = (difference + 360) % 360
    
    # If this is more than 180, left rotation would be better
    # so set rightDegrees to a negative value.
    if( rightDegrees > 180 )
        rightDegrees = rightDegrees - 360
    endif
}















//  Development History

//  Version 0.0.1 
//  09th October 2002
//  -----------------
//      - Development history started
//      - Robot development started with basic game type and 
//        situation detection
//      - Registration of event handlers and priorities depending on 
//        the robots current state