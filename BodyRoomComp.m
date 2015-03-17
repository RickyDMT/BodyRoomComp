function BodyRoomComp(varargin)

global KEYS COLORS w wRect XCENTER YCENTER PICS STIM BRC rects mids scan_sec block

prompt={'SUBJECT ID' 'fMRI (1 or 0)'};
defAns={'4444' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
fmri =str2double(answer{2});
% COND = str2double(answer{2});
% SESS = str2double(answer{3});
% prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KbName('UnifyKeyNames');

KEYS = struct;
if fmri == 1;
    KEYS.ONE= KbName('0)');
    KEYS.TWO= KbName('1!');
    KEYS.THREE= KbName('2@');
    KEYS.FOUR= KbName('3#');
    KEYS.FIVE= KbName('4$');
    KEYS.SIX= KbName('5%');
    KEYS.SEVEN= KbName('6^');
    KEYS.EIGHT= KbName('7&');
    KEYS.NINE= KbName('8*');
else
    KEYS.ONE= KbName('1!');
    KEYS.TWO= KbName('2@');
    KEYS.THREE= KbName('3#');
    KEYS.FOUR= KbName('4$');
    KEYS.FIVE= KbName('5%');
    KEYS.SIX= KbName('6^');
    KEYS.SEVEN= KbName('7&');
    KEYS.EIGHT= KbName('8*');
    KEYS.NINE= KbName('9(');
end

rangetest = cell2mat(struct2cell(KEYS));
% KEYS.all = min(rangetest):max(rangetest);
KEYS.all = rangetest;
KEYS.trigger = KbName('''"');

COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 6;
STIM.trials = 10;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 1;
STIM.jit = [2 3 4];

%% Keyboard stuff for fMRI...

%list devices
[keyboardIndices, productNames] = GetKeyboardIndices;

isxkeys=strcmp(productNames,'Xkeys');

xkeys=keyboardIndices(isxkeys);
macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));

%in case something goes wrong or the keyboard name isn?t exactly right
if isempty(macbook)
    macbook=-1;
end

%in case you?re not hooked up to the scanner, then just work off the keyboard
if isempty(xkeys)
    xkeys=macbook;
end


%% Find & load in pics
[mdir,~,~] = fileparts(which('BodyRoomComp.m'));
imgdir = [mdir filesep 'Pics'];
cd(imgdir);

    % Update for appropriate pictures.
     PICS.in.B = dir('Model*');
     PICS.in.R = dir('Home*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.B) || isempty(PICS.in.R) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end


%% Fill in rest of pertinent info
BRC = struct;


picdiff = (STIM.totes/2) - length(PICS.in.B);
if picdiff > 0;
    piclist_B = [randperm(length(PICS.in.B))'; randi(length(PICS.in.B),picdiff,1)];
elseif picdiff <= 0;
    piclist_B = randperm(length(PICS.in.B),(STIM.totes/2))';
end
piclist_B = reshape(piclist_B,STIM.trials,STIM.blocks/2);


picdiff = (STIM.totes/2) - length(PICS.in.R);
if picdiff > 0;
    piclist_R = [randperm(length(PICS.in.R))'; randi(length(PICS.in.R),picdiff,1)];
elseif picdiff <= 0;
    piclist_R = randperm(length(PICS.in.R),(STIM.totes/2))';
end
piclist_R = reshape(piclist_R,STIM.trials,STIM.blocks/2);

BRC.var.picname_B = cell(10,3);
BRC.var.picname_R = cell(10,3);

for blox = 1:STIM.blocks/2;
    for tt = 1:STIM.trials;
        BRC.var.picname_B{tt,blox} = PICS.in.B(piclist_B(tt,blox)).name;
        BRC.var.picname_R{tt,blox} = PICS.in.R(piclist_R(tt,blox)).name;
    end
end

%Determine if Body (1) or Rooms (0) go first (randomly).
order = CoinFlip(1,.5);
if order == 1;
    BRC.var.order = repmat([1;0],3,1);
else
    BRC.var.order = repmat([0;1],3,1);
end

    BRC.var.jit = reshape(BalanceTrials(STIM.totes,1,[STIM.jit]),STIM.trials,STIM.blocks);

    BRC.data.rt = zeros(STIM.blocks,1);
    BRC.data.anx_rate = zeros(STIM.blocks,1);
    BRC.data.info.ID = ID;
%     BRC.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
%     BRC.data.info.session = SESS;
    BRC.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    
    BRC.onset.fix = [];
    BRC.onset.pic = [];
    BRC.onset.rate = [];
    
commandwindow;

%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
%Screen('Preference', 'SkipSyncTests', 1);

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

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);


%% Dat Grid
[rects,mids] = DrawRectsGrid();

%also, image position matters.
side = wRect(4)/3;

STIM.imgrect = [XCENTER-side; YCENTER-side; XCENTER+side; YCENTER+side];


%% fMRI Synch

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEYS.trigger,xkeys);
else
    scan_sec = GetSecs();
end

%% Do that intro stuff.
DrawFormattedText(w,'In this task, you will see a series of images.  Please focus carefully on each photo that is displayed.  You will be asked to rate your anxiety in between blocks of photos.\n\nPress any key to continue.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
% KbWait();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEYS.all))
        break
    end
end

Screen('Flip',w);
WaitSecs(1);


%% Do That trial stuff.
    %Ask initial anxiety question
    BRC.data.pre_anx_rate = AnxRate(wRect,fmri);

for block = 1:STIM.blocks;
    DrawPics4Block(block,BRC.var.order(block));
    for trial = 1:STIM.trials;
        %display pic       
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        WaitSecs(BRC.var.jit(trial,block));
        BRC.onset.fix(trial,block) = fixon - scan_sec;
        
        Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
        picon = Screen('Flip',w);
        WaitSecs(STIM.trialdur);
        BRC.onset.pic(trial,block) = picon - scan_sec;
    end
    
    %Ask anxiety questions
     
    BRC.data.anx_rate(block) = AnxRate(wRect,fmri);
end

%% Save

savedir = [mdir filesep 'Results' filesep];
cd(savedir)
savename = ['SocialComp_' num2str(ID) '.mat'];

if exist(savename,'file')==2;
    savename = ['SocialComp_' num2str(ID) '_' sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
end

try
save([savedir savename],'BRC');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mdir filesep savename],'BRC');
    catch
        warning('STILL problems saving....Try right-clicking on ''AAM'' and Save as...');
        BRC
    end
end



%% The End!

DrawFormattedText(w,'Thank you for your responses. This task is now complete. Please notify the assessor.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait();

sca


end

function [anxiety] = AnxRate(wRect,fmri,varargin)

global w COLORS KEYS BRC scan_sec block

anxtext = 'Please rate your current level of anxiety:';
 %Ask initial anxiety question
    DrawFormattedText(w,anxtext,'center','center',COLORS.WHITE);
    drawRatings();
    anxon = Screen('Flip',w);
    BRC.onset.rate(block) = anxon - scan_sec;
    
    while 1
        [keyisdown, ~, keycode] = KbCheck();
        if keyisdown==1 && any(keycode(KEYS.all))
            rating = KbName(find(keycode));           
            DrawFormattedText(w,anxtext,'center','center',COLORS.WHITE);
            drawRatings(rating);
            Screen('Flip',w);
            WaitSecs(.25);
            break;
        end
    end
    
    rating = str2double(rating(1));

    if fmri ==1;
        rating = rating + 1;
    end
    
    anxiety = rating;


end

function DrawPics4Block(block,order,varargin)

global PICS BRC w

switch block    %Gotta match "block" up with column 1 - 3 of the variable structure
    case {1,3,5}
        blk = block/2 + .5;
    case {2,4,6}
        blk = block/2;
end

if order == 1;  %Do Body pics
    blocpics = BRC.var.picname_B(:,blk);
elseif order == 0; %Do room pics
    blocpics = BRC.var.picname_R(:,blk);
end

for j = 1:length(blocpics);
    BRC.data.picname(j,block) = blocpics(j);
  
    PICS.out(j).raw = imread(char(blocpics(j)));
    PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
end

end


function [ rects,mids ] = DrawRectsGrid(varargin)
%DrawRectGrid:  Builds a grid of squares with gaps in between.

global wRect XCENTER

%Size of image will depend on screen size. First, an area approximately 80%
%of screen is determined. Then, images are 1/4th the side of that square
%(minus the 3 x the gap between images.

num_rects = 9;                 %How many rects?
xlen = wRect(3)*.8;           %Make area covering about 80% of vertical dimension of screen.
gap = 20;                       %Gap size between each rect
square_side = fix((xlen - (num_rects-1)*gap)/num_rects); %Size of rect depends on size of screen.

squart_x = XCENTER-(xlen/2);
squart_y = wRect(4)*.8;         %Rects start @~80% down screen.

rects = zeros(4,num_rects);

% for row = 1:DIMS.grid_row;
    for col = 1:num_rects;
%         currr = ((row-1)*DIMS.grid_col)+col;
        rects(1,col)= squart_x + (col-1)*(square_side+gap);
        rects(2,col)= squart_y;
        rects(3,col)= squart_x + (col-1)*(square_side+gap)+square_side;
        rects(4,col)= squart_y + square_side;
    end
% end
mids = [rects(1,:)+square_side/2; rects(2,:)+square_side/2+5];

end

%%
function drawRatings(varargin)

global w KEYS COLORS rects mids

colors=repmat(COLORS.WHITE',1,9);
% rects=horzcat(allRects.rate1rect',allRects.rate2rect',allRects.rate3rect',allRects.rate4rect');

%Needs to feed in "code" from KbCheck, to show which key was chosen.
if nargin >= 1 && ~isempty(varargin{1})
    response=varargin{1};
    
    key=find(response);
    if length(key)>1
        response=response(1);
    end;
    
    switch response
        
        case {KEYS.ONE}
            choice=1;
        case {KEYS.TWO}
            choice=2;
        case {KEYS.THREE}
            choice=3;
        case {KEYS.FOUR}
            choice=4;
        case {KEYS.FIVE}
            choice=5;
        case {KEYS.SIX}
            choice=6;
        case {KEYS.SEVEN}
            choice=7;
        case {KEYS.EIGHT}
            choice=8;
        case {KEYS.NINE}
            choice=9;
%         case {KEYS.TEN}
%             choice = 10;
    end
    
    if exist('choice','var')
        
        
        colors(:,choice)=COLORS.GREEN';
        
    end
end


%draw all the squares
Screen('FrameRect',w,colors,rects,1);

%draw the text (1-9)
for n = 1:9;
    numnum = sprintf('%d',n);
    CenterTextOnPoint(w,numnum,mids(1,n),mids(2,n),colors(:,n));
end

end


%%
function [nx, ny, textbounds] = CenterTextOnPoint(win, tstring, sx, sy,color)
% [nx, ny, textbounds] = DrawFormattedText(win, tstring [, sx][, sy][, color][, wrapat][, flipHorizontal][, flipVertical][, vSpacing][, righttoleft])
%
% 

numlines=1;

if nargin < 1 || isempty(win)
    error('CenterTextOnPoint: Windowhandle missing!');
end

if nargin < 2 || isempty(tstring)
    % Empty text string -> Nothing to do.
    return;
end

% Store data class of input string for later use in re-cast ops:
stringclass = class(tstring);

% Default x start position is left border of window:
if isempty(sx)
    sx=0;
end

% if ischar(sx) && strcmpi(sx, 'center')
%     xcenter=1;
%     sx=0;
% else
%     xcenter=0;
% end

xcenter=0;

% No text wrapping by default:
% if nargin < 6 || isempty(wrapat)
    wrapat = 0;
% end

% No horizontal mirroring by default:
% if nargin < 7 || isempty(flipHorizontal)
    flipHorizontal = 0;
% end

% No vertical mirroring by default:
% if nargin < 8 || isempty(flipVertical)
    flipVertical = 0;
% end

% No vertical mirroring by default:
% if nargin < 9 || isempty(vSpacing)
    vSpacing = 1.5;
% end

% if nargin < 10 || isempty(righttoleft)
    righttoleft = 0;
% end

% Convert all conventional linefeeds into C-style newlines:
newlinepos = strfind(char(tstring), '\n');

% If '\n' is already encoded as a char(10) as in Octave, then
% there's no need for replacemet.
if char(10) == '\n' %#ok<STCMP>
   newlinepos = [];
end

% Need different encoding for repchar that matches class of input tstring:
if isa(tstring, 'double')
    repchar = 10;
elseif isa(tstring, 'uint8')
    repchar = uint8(10);    
else
    repchar = char(10);
end

while ~isempty(newlinepos)
    % Replace first occurence of '\n' by ASCII or double code 10 aka 'repchar':
    tstring = [ tstring(1:min(newlinepos)-1) repchar tstring(min(newlinepos)+2:end)];
    % Search next occurence of linefeed (if any) in new expanded string:
    newlinepos = strfind(char(tstring), '\n');
end

% % Text wrapping requested?
% if wrapat > 0
%     % Call WrapString to create a broken up version of the input string
%     % that is wrapped around column 'wrapat'
%     tstring = WrapString(tstring, wrapat);
% end

% Query textsize for implementation of linefeeds:
theight = Screen('TextSize', win) * vSpacing;

% Default y start position is top of window:
if isempty(sy)
    sy=0;
end

winRect = Screen('Rect', win);
winHeight = RectHeight(winRect);

% if ischar(sy) && strcmpi(sy, 'center')
    % Compute vertical centering:
    
    % Compute height of text box:
%     numlines = length(strfind(char(tstring), char(10))) + 1;
    %bbox = SetRect(0,0,1,numlines * theight);
    bbox = SetRect(0,0,1,theight);
    
    
    textRect=CenterRectOnPoint(bbox,sx,sy);
    % Center box in window:
    [rect,dh,dv] = CenterRect(bbox, textRect);

    % Initialize vertical start position sy with vertical offset of
    % centered text box:
    sy = dv;
% end

% Keep current text color if noone provided:
if nargin < 5 || isempty(color)
    color = [];
end

% Init cursor position:
xp = sx;
yp = sy;

minx = inf;
miny = inf;
maxx = 0;
maxy = 0;

% Is the OpenGL userspace context for this 'windowPtr' active, as required?
[previouswin, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');

% OpenGL rendering for this window active?
if IsOpenGLRendering
    % Yes. We need to disable OpenGL mode for that other window and
    % switch to our window:
    Screen('EndOpenGL', win);
end

% Disable culling/clipping if bounding box is requested as 3rd return
% % argument, or if forcefully disabled. Unless clipping is forcefully
% % enabled.
% disableClip = (ptb_drawformattedtext_disableClipping ~= -1) && ...
%               ((ptb_drawformattedtext_disableClipping > 0) || (nargout >= 3));
% 

disableClip=1;

% Parse string, break it into substrings at line-feeds:
while ~isempty(tstring)
    % Find next substring to process:
    crpositions = strfind(char(tstring), char(10));
    if ~isempty(crpositions)
        curstring = tstring(1:min(crpositions)-1);
        tstring = tstring(min(crpositions)+1:end);
        dolinefeed = 1;
    else
        curstring = tstring;
        tstring =[];
        dolinefeed = 0;
    end

    if IsOSX
        % On OS/X, we enforce a line-break if the unwrapped/unbroken text
        % would exceed 250 characters. The ATSU text renderer of OS/X can't
        % handle more than 250 characters.
        if size(curstring, 2) > 250
            tstring = [curstring(251:end) tstring]; %#ok<AGROW>
            curstring = curstring(1:250);
            dolinefeed = 1;
        end
    end
    
    if IsWin
        % On Windows, a single ampersand & is translated into a control
        % character to enable underlined text. To avoid this and actually
        % draw & symbols in text as & symbols in text, we need to store
        % them as two && symbols. -> Replace all single & by &&.
        if isa(curstring, 'char')
            % Only works with char-acters, not doubles, so we can't do this
            % when string is represented as double-encoded Unicode:
            curstring = strrep(curstring, '&', '&&');
        end
    end
    
    % tstring contains the remainder of the input string to process in next
    % iteration, curstring is the string we need to draw now.

    % Perform crude clipping against upper and lower window borders for
    % this text snippet. If it is clearly outside the window and would get
    % clipped away by the renderer anyway, we can safe ourselves the
    % trouble of processing it:
    if disableClip || ((yp + theight >= 0) && (yp - theight <= winHeight))
        % Inside crude clipping area. Need to draw.
        noclip = 1;
    else
        % Skip this text line draw call, as it would be clipped away
        % anyway.
        noclip = 0;
        dolinefeed = 1;
    end
    
    % Any string to draw?
    if ~isempty(curstring) && noclip
        % Cast curstring back to the class of the original input string, to
        % make sure special unicode encoding (e.g., double()'s) does not
        % get lost for actual drawing:
        curstring = cast(curstring, stringclass);
        
        % Need bounding box?
%         if xcenter || flipHorizontal || flipVertical
            % Compute text bounding box for this substring:
            bbox=Screen('TextBounds', win, curstring, [], [], [], righttoleft);
%         end
        
        % Horizontally centered output required?
%         if xcenter
            % Yes. Compute dh, dv position offsets to center it in the center of window.
%             [rect,dh] = CenterRect(bbox, winRect);
            [rect,dh] = CenterRect(bbox, textRect);
            % Set drawing cursor to horizontal x offset:
            xp = dh;
%         end
            
%         if flipHorizontal || flipVertical
%             textbox = OffsetRect(bbox, xp, yp);
%             [xc, yc] = RectCenter(textbox);
% 
%             % Make a backup copy of the current transformation matrix for later
%             % use/restoration of default state:
%             Screen('glPushMatrix', win);
% 
%             % Translate origin into the geometric center of text:
%             Screen('glTranslate', win, xc, yc, 0);
% 
%             % Apple a scaling transform which flips the direction of x-Axis,
%             % thereby mirroring the drawn text horizontally:
%             if flipVertical
%                 Screen('glScale', win, 1, -1, 1);
%             end
%             
%             if flipHorizontal
%                 Screen('glScale', win, -1, 1, 1);
%             end
% 
%             % We need to undo the translations...
%             Screen('glTranslate', win, -xc, -yc, 0);
%             [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);
%             Screen('glPopMatrix', win);
%         else
            [nx ny] = Screen('DrawText', win, curstring, xp, yp, color, [], [], righttoleft);
%         end
    else
        % This is an empty substring (pure linefeed). Just update cursor
        % position:
        nx = xp;
        ny = yp;
    end

    % Update bounding box:
    minx = min([minx , xp, nx]);
    maxx = max([maxx , xp, nx]);
    miny = min([miny , yp, ny]);
    maxy = max([maxy , yp, ny]);

    % Linefeed to do?
    if dolinefeed
        % Update text drawing cursor to perform carriage return:
        if xcenter==0
            xp = sx;
        end
        yp = ny + theight;
    else
        % Keep drawing cursor where it is supposed to be:
        xp = nx;
        yp = ny;
    end
    % Done with substring, parse next substring.
end

% Add one line height:
maxy = maxy + theight;

% Create final bounding box:
textbounds = SetRect(minx, miny, maxx, maxy);

% Create new cursor position. The cursor is positioned to allow
% to continue to print text directly after the drawn text.
% Basically behaves like printf or fprintf formatting.
nx = xp;
ny = yp;

% Our work is done. If a different window than our target window was
% active, we'll switch back to that window and its state:
if previouswin > 0
    if previouswin ~= win
        % Different window was active before our invocation:

        % Was that window in 3D mode, i.e., OpenGL rendering for that window was active?
        if IsOpenGLRendering
            % Yes. We need to switch that window back into 3D OpenGL mode:
            Screen('BeginOpenGL', previouswin);
        else
            % No. We just perform a dummy call that will switch back to that
            % window:
            Screen('GetWindowInfo', previouswin);
        end
    else
        % Our window was active beforehand.
        if IsOpenGLRendering
            % Was in 3D mode. We need to switch back to 3D:
            Screen('BeginOpenGL', previouswin);
        end
    end
end

return;
end