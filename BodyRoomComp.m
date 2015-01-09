

function BodyRoomComp(varargin)


global KEY COLORS w wRect XCENTER YCENTER PICS STIM DPB trial pahandle

prompt={'SUBJECT ID' 'Condition' 'Session (1, 2, or 3)' 'Practice? 0 or 1'};
defAns={'4444' '1' '1' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
prac = str2double(answer{4});

%Make sure input data makes sense.
% try
%     if SESS > 1;
%         %Find subject data & make sure same condition.
%         
%     end
% catch
%     error('Subject ID & Condition code do not match.');
% end


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
STIM.trials = 20;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 1.250;


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
 


PICS =struct;
    % Update for appropriate pictures.
     PICS.in.avg = dir('Healthy*');
     PICS.in.thin = dir('Unhealthy*');

% picsfields = fieldnames(PICS.in);

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.avg) || isempty(PICS.in.thin) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

% img_mult = STIM.totes/length(PICS.in.avg); %FOR TESTING, UPDATE WHEN ACTUAL PICS PRESENT.


%% Fill in rest of pertinent info
DPT = struct;

% probe: Location of probe is left (1) or right (2);
% img: Whether Avg is on left (1) or right (2);
% exp: Experimental (1) or control (0) trial.  If control trial (0), then 'img'
%      dictates whether trial is avg (1) or thin (0);
[probe, img] = BalanceTrials(80,0,[1 2],[1 2]);
[probec, imgc] = BalanceTrials(40,0,[1 2],[1 2]);
probe = [probe; probec];
img = [img; imgc];
exp = [ones(80,1); zeros(40,1)];

%Make long list of randomized #s to represent each pic
% piclist = [repmat(randperm(length(PICS.in.avg))',img_mult,1) repmat(randperm(length(PICS.in.thin))',img_mult,1)];
piclist = [randperm(length(PICS.in.avg),120)' randperm(length(PICS.in.thin),120)'];

%Concatenate these into a long list of trial types.
% trial_types = [l_r counterprobe signal piclist];
trial_types = [probe img exp piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    DPB.var.probe(1:STIM.trials,g) = shuffled(row:rend,1);
    DPB.var.picnum_avg(1:STIM.trials,g) = shuffled(row:rend,4);
    DPB.var.picnum_thin(1:STIM.trials,g) = shuffled(row:rend,5);
    DPB.var.img(1:STIM.trials,g) = shuffled(row:rend,2);
    DPB.var.exp(1:STIM.trials,g) = shuffled(row:rend,3);
end

    DPB.data.rt = zeros(STIM.trials, STIM.blocks);
    DPB.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    DPB.data.avg_rt = zeros(STIM.blocks,1);
    DPB.data.info.ID = ID;
%     DPB.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
    DPB.data.info.session = SESS;
    DPB.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


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
%%
%% Initial screen
DrawFormattedText(w,'This is a task!\nPress any key to continue.','center','center',COLORS.WHITE,[],[],[],1.5);
Screen('Flip',w);
KbWait();
Screen('Flip',w);
WaitSecs(1);

%% Instructions
instruct = sprintf('This is where instructions will go.'); %sprintf('You will see pictures on the left & right side of the screen, followed by a dot on the left or right side of the screen.\n\nPress the "%s" if the dot is on the left side of the screen or "%s" if the dot is on right side of the screen\n\nPress any key to continue.',KbName(KEY.left),KbName(KEY.right));
DrawFormattedText(w,instruct,'center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait();


