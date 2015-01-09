%%
%change this to 0 to fill whole screen
DEBUG=1;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

wwwhite = [255 255 255];
Screen('DrawLine',w,wwwhite,100,300,400,300);
side = 10;
Screen('FrameRect',w,wwwhite,[195 275 205 325]);
Screen('Flip',w);

while 1
    [x,y,click] = GetMouse();
    x = roundn(x,1);
    if x < 100;
        x = 100;
    elseif x > 400;
        x = 400;
    end
    Screen('DrawLine',w,wwwhite,100,300,400,300);
    Screen('FrameRect',w,wwwhite,[x 275 x+side 325]);
    xxx = sprintf('%d',x);
    DrawFormattedText(w,xxx,'center',400,wwwhite);
    Screen('Flip',w);
end
    
    