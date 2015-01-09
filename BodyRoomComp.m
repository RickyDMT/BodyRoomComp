

function BodyRoomComp(varargin)


global KEY COLORS w wRect XCENTER YCENTER PICS STIM BRC pahandle

prompt={'SUBJECT ID' 'Condition' 'Session (1, 2, or 3)' 'Practice? 0 or 1'};
defAns={'4444' '1' '1' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
prac = str2double(answer{4});


rng(ID); %Seed random number generator with subject ID
d = clock;

KEY = struct;
KEY.rt = KbName('SPACE');
KEY.left = KbName('c');
KEY.right = KbName('m');


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
STIM.trialdur = 3;
STIM.jit = [.5 1 1.5];


%% Find & load in pics
[imgdir,~,~] = fileparts(which('MasterPics_PlaceHolder.m'));
% picratefolder = fullfile(imgdir,'SavingsRatings');

% try
%     cd(picratefolder)
% catch
%     error('Could not find and/or open the image directory.');
% end
% 
% filen = sprintf('PicRate_%03d.mat',ID);
% try
%     p = open(filen);
% catch
%     warning('Could not find and/or open the rating file.');
%     commandwindow;
%     randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
%     if randopics == 1
%         p = struct;
%         p.PicRating.go = dir('Healthy*');
%         p.PicRating.no = dir('Unhealthy*');
%         %XXX: ADD RANDOMIZATION SO THAT SAME 80 IMAGES AREN'T CHOSEN
%         %EVERYTIME
%     else
%         error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
%     end
%     
% end

cd(imgdir);
 


    % Update for appropriate pictures.
     PICS.in.B = dir('*_T*');
     PICS.in.R = dir('room*');

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

%Determine if Body or Rooms go first (randomly).
order = CoinFlip(1,.5);
if order == 1;
    BRC.var.order = repmat([1;0],3,1);
else
    BRC.var.order = repmat([0;1],3,1);
end

    BRC.var.jit = BalanceTrials(STIM.totes,1,[STIM.jit]);

    BRC.data.rt = zeros(STIM.blocks,1);
    BRC.data.anx_rate = zeros(STIM.blocks,1);
    BRC.data.info.ID = ID;
%     BRC.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
%     BRC.data.info.session = SESS;
    BRC.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    
commandwindow;

%%
%change this to 0 to fill whole screen
DEBUG=0;

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

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');
%% Do that intro stuff.
DrawFormattedText(w,'Instructions go here','center','center',COLORS.WHITE);
Screen('Flip',w);
KbWait();

%% Do That trial stuff.
for block = 1:STIM.blocks;
    DrawPics4Block(block,BRC.var.order(block));
    for trial = 1:STIM.trials;
        %display pic
        trialcount = (block-1)*10+trial;
        BRC.data(trialcount).block = block;
        BRC.data(trialcount).trial = trial;
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        Screen('Flip',w);
        Waitsecs(BRC.var.jit);
        
        Screen('DrawTexture',w,PICS.out(trial).raw);
        Screen('Flip',w);
        WaitSecs(STIM.trialdur);
    end
    
    %Ask anxiety questions
    DrawFormattedText(w,'How anxious are you?','center','center',COLORS.WHITE);
    
end


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
    trialcount = (block-1)*10+j;
    BRC.data(trialcount).picname = blocpics(j);
  
    PICS.out(j).raw = imread(char(blocpics(j)));
    PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
end

end
