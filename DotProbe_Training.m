function DotProbe_Training(varargin)
%NEEDS UPDATE: Real pics, real trial & block number (which is dependent on
%pics).


global KEY COLORS w wRect XCENTER YCENTER PICS STIM DPT trial pahandle

prompt={'SUBJECT ID' 'Session (1, 2, or 3)' 'Practice? 0 or 1'};
defAns={'4444' '' ''};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
% COND = str2double(answer{2});
SESS = str2double(answer{2});
prac = str2double(answer{3});

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
STIM.blocks = 8;
STIM.trials = 10;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 1.250;


%% Find & load in pics
%find the image directory by figuring out where the .m is kept

[imgdir,~,~] = fileparts(which('DotProbe_Training.m'));

try
    cd([imgdir filesep 'IMAGES'])
catch
    error('Could not find and/or open the IMAGES folder.');
end

PICS =struct;
% if COND == 1;                   %Condtion = 1 is food. 
    PICS.in.lo = dir('good*.jpg');
    PICS.in.hi = dir('*bad*.jpg');
%     PICS.in.neut = dir('*water*.jpg');
% elseif COND == 2;               %Condition = 2 is not food (birds/flowers)
%     PICS.in.hi = dir('*bird*.jpg');
%     PICS.in.hi = dir('*flowers*.jpg');
%     PICS.in.neut = dir('*mam*.jpg');
% end
% picsfields = fieldnames(PICS.in);

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.lo) || isempty(PICS.in.hi) %|| isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
DPT = struct;

l_r = BalanceTrials(STIM.totes,1,[1 2]);    %Location for probe: 1 = Left, 2 = Right; 1 = stop signal, 0 = no stop signal
tenper = fix(.1*STIM.totes);
counterprobe = [ones(tenper,1); zeros((STIM.totes - tenper),1)];   %Ten percent of trials, have probe appear on opposite side of 
signal = [ones((tenper/2),1); zeros((STIM.totes - tenper/2),1)];   %Five percent of trials, when probe appears on opposite side, give stop signal.


%Make long list of randomized #s to represent each pic
% piclist = [randperm(length(PICS.in.lo)); randperm(length(PICS.in.hi))]';
piclist = [randperm((STIM.totes)); randperm((STIM.totes))]';    %For testing purposes.

%Concatenate these into a long list of trial types.
trial_types = [l_r counterprobe signal piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    DPT.var.lr(1:STIM.trials,g) = shuffled(row:rend,1);
    DPT.var.picnum_hi(1:STIM.trials,g) = shuffled(row:rend,4);
    DPT.var.picnum_lo(1:STIM.trials,g) = shuffled(row:rend,5);
    DPT.var.cprobe(1:STIM.trials,g) = shuffled(row:rend,2);
    DPT.var.signal(1:STIM.trials,g) = shuffled(row:rend,3);
end

    DPT.data.rt = zeros(STIM.trials, STIM.blocks);
    DPT.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    DPT.data.avg_rt = zeros(STIM.blocks,1);
    DPT.data.info.ID = ID;
%     DPT.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
    DPT.data.info.session = SESS;
    DPT.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


commandwindow;

%% Sound stuff.
wave=sin(1:0.25:1000);
freq=22254;  % change this to change freq of tone
nrchannels = size(wave,1);
% Default to auto-selected default output device:
deviceid = -1;
% Request latency mode 2, which used to be the best one in our measurement:
reqlatencyclass = 2; % class 2 empirically the best, 3 & 4 == 2
% Initialize driver, request low-latency preinit:
InitializePsychSound(1);
% Open audio device for low-latency output:
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, nrchannels);

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

%% Set frame size;
%border = 20;
dpr = 10; %radius of dot probe

% STIM.framerect = [border; border; wRect(3)-border; wRect(4)-border];

% This sets 'DrawLine' to draw dashed line.
% Screen('LineStipple',w,1,5);

%This sets location for L & R image display. Basically chooses a square
%whose side=1/2 the vertical size of the screen & is vertically centered.
%The square is then placed 1/10th the width of the screen from the L & R
%edge.
STIM.img(1,1:4) = [wRect(3)/15,wRect(4)/4,wRect(3)/15+wRect(4)/2,wRect(4)*(3/4)];               %L - image rect
STIM.img(2,1:4) = [(wRect(3)*(14/15))-wRect(4)/2,wRect(4)/4,wRect(3)*(14/15),wRect(4)*(3/4)];     %R - image rect
STIM.probe(1,1:4) = [wRect(3)/4 - dpr,wRect(4)/2 - dpr, wRect(3)/4 + dpr, wRect(4)/2 + dpr];    %L probe rect
STIM.probe(2,1:4) = [wRect(3)*(3/4) - dpr,wRect(4)/2 - dpr, wRect(3)*(3/4) + dpr, wRect(4)/2 + dpr];    %R probe rect

%% Initial screen
DrawFormattedText(w,'Welcome to the Dot-Probe Task.\nPress any key to continue.','center','center',COLORS.WHITE,[],[],[],1.5);
Screen('Flip',w);
KbWait();
Screen('Flip',w);
WaitSecs(1);

%% Instructions
instruct = sprintf('You will see pictures on the left & right side of the screen, followed by a dot on the left or right side of the screen.\n\nPress the "%s" if the dot is on the left side of the screen or "%s" if the dot is on right side of the screen\n\nBUT if you hear a tone when the dot appears, DO NOT PRESS the button.\n\nPress any key to continue.',KbName(KEY.left),KbName(KEY.right));
DrawFormattedText(w,instruct,'center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait();


%% Practice

if prac == 1;
    DrawFormattedText(w,' Let''s practice.\n\nPress any key to continue.','center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],2);
    
    
    %Load random hi cal & low cal pic
    rand_prac_pic = randi(length(PICS.in.lo));
    practpic_lo = imread(getfield(PICS,'in','lo',{rand_prac_pic},'name'));
    practpic_hi = imread(getfield(PICS,'in','hi',{rand_prac_pic},'name'));
    practpic_lo = Screen('MakeTexture',w,practpic_lo);
    practpic_hi = Screen('MakeTexture',w,practpic_hi);
    
    %Display pic on left to show go signal and "left" key.
%     Screen('FrameRect',w,COLORS.rect,STIM.framerect,6);
%     Screen('DrawTexture',w,practpic,[],STIM.img(1,:));
% Basic Instructions:
    DrawFormattedText(w,'You will first see two images on the left & right side of the screen, followed by a dot under one of the images.\n\n Press any key to continue.','center','center',COLORS.WHITE,60,[],[],1.5);
    Screen('Flip',w);
    WaitSecs(.5);
    KbWait();
        
    %Do this practice trial
    Screen('DrawTexture',w,practpic_lo,[],STIM.img(1,:));
    Screen('DrawTexture',w,practpic_hi,[],STIM.img(2,:));
    Screen('Flip',w);
    WaitSecs(.5);
    
    Screen('FillOval',w,COLORS.WHITE,STIM.probe(1,:));
    pract_text = sprintf('In this trial you would press "%s" because the dot is on the left side.',KbName(KEY.left));
    DrawFormattedText(w,pract_text,'center','center',COLORS.WHITE,25,[],[],1.2,[],STIM.img(2,:));
    pract_textc = sprintf('Press "%s" now.',KbName(KEY.left));
    DrawFormattedText(w,pract_textc,'center',wRect(4)-200,COLORS.WHITE);
    Screen('Flip',w);
    
    commandwindow;
    WaitSecs(2);
    while 1
        FlushEvents();
        [d, ~, c] = KbCheck();            %wait for left key to be pressed
        if d == 1 && find(c) == KEY.left
            break;
        else
            FlushEvents();
        end
    end
    
    %Display probe on Right to show use of "right" key.
    Screen('DrawTexture',w,practpic_lo,[],STIM.img(1,:));
    Screen('DrawTexture',w,practpic_hi,[],STIM.img(2,:));
    Screen('Flip',w);
    WaitSecs(.5);
    Screen('FillOval',w,COLORS.WHITE,STIM.probe(2,:));   
    pract_text = sprintf('And in this trial you would press "%s" because the dot is on the right.',KbName(KEY.right));
    DrawFormattedText(w,pract_text,'center','center',COLORS.WHITE,25,[],[],1.2,[],STIM.img(1,:));
    pract_textc = sprintf('Press "%s" now.',KbName(KEY.right));
    DrawFormattedText(w,pract_textc,'center',wRect(4)-200,COLORS.WHITE);
    Screen('Flip',w);
    while 1
        FlushEvents();
        [dd, ~, cc] = KbCheck();            %wait for "right" key to be pressed
        if dd == 1 && find(cc) == KEY.right
            break;
        else
            FlushEvents();
        end
    end
    Screen('Flip',w);
    WaitSecs(1);
    
    %Now do "no go" signal trial. 
    PsychPortAudio('FillBuffer', pahandle, wave);
    DrawFormattedText(w,'In some trials you will hear a short tone (a beep).','center','center',COLORS.WHITE,[],[],[],1.2);
    DrawFormattedText(w,'Press any key to hear the tone.','center',wRect(4)-200,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    Screen('DrawTexture',w,practpic_lo,[],STIM.img(1,:));
    Screen('DrawTexture',w,practpic_hi,[],STIM.img(2,:));
    Screen('Flip',w);
    WaitSecs(.5);
    Screen('FillOval',w,COLORS.WHITE,STIM.probe(1,:));
    
    PsychPortAudio('Start', pahandle, 1);
    %WaitSecs(.25);
    %PsychPortAudio('Stop', pahandle);
    pract_text = sprintf('If you hear a tone like this, do not press either key! Just wait & the next round will begin.');
    DrawFormattedText(w,pract_text,'center','center',COLORS.WHITE,35,[],[],1.2,[],STIM.img(2,:));
    Screen('Flip',w,[],1);
    WaitSecs(2);
    DrawFormattedText(w,'Press any key to continue.','center',wRect(4)-200,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    WaitSecs(2);
end 
  
%% Task
DrawFormattedText(w,'The Dot Probe Task is about to begin.\n\n\nPress any key to begin the task.','center','center',COLORS.WHITE);
Screen('Flip',w);
KbWait([],3);
Screen('Flip',w);
WaitSecs(1.5);

for block = 1:STIM.blocks;
    %Load pics block by block.
    DrawPics4Block(block);
    ibt = sprintf('Prepare for Block %d. \n\n\nPress any key when you are ready to begin.',block);
    DrawFormattedText(w,ibt,'center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
    old = Screen('TextSize',w,80);
    PsychPortAudio('FillBuffer', pahandle, wave);
    for trial = 1:STIM.trials;
        [DPT.data.rt(trial,block), DPT.data.correct(trial,block)] = DoDotProbeTraining(trial,block);
        %Wait 500 ms
        Screen('Flip',w);
        WaitSecs(.5);
    end
    Screen('TextSize',w,old);
    %Inter-block info here, re: Display RT, accuracy, etc.
    %Calculate block RT
    Screen('Flip',w);   %clear screen first.
    
    block_text = sprintf('Block %d Results',block);
    
    c = (DPT.data.correct(:,block) == 1);                                 %Find correct trials
    s = (DPT.var.signal(:,block) ==0);                                    %Find "go" trials
    corr_count = sprintf('Number Correct:\t%d of %d',length(find(c)),STIM.trials);  %Number correct = length of find(c)
    corr_per = length(find(c))*100/length(c);                           %Percent correct = length find(c) / total trials
    corr_pert = sprintf('Percent Correct:\t%4.1f%%',corr_per);          %sprintf that data to string.
    
    if isempty(c(c==1))
        %Don't try to calculate avg RT, they got them all wrong (WTF?)
        %Display "N/A" for this block's RT.
        ibt_rt = sprintf('Average RT:\tUnable to calculate RT due to 0 correct trials.');
    else
        blockrts = DPT.data.rt(:,block);                                %Pull all RT data
        blockrts = blockrts(c & s);                                     %Resample RT only if correct & not a no-go trial.
        avg_rt_block = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
        ibt_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_block);
    end
    
    ibt_xdim = wRect(3)/10;
    ibt_ydim = wRect(4)/4;
    
    %Next lines display all the data.
    DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);
    DrawFormattedText(w,corr_count,ibt_xdim,ibt_ydim,COLORS.WHITE);
    DrawFormattedText(w,corr_pert,ibt_xdim,ibt_ydim+30,COLORS.WHITE);    
    DrawFormattedText(w,ibt_rt,ibt_xdim,ibt_ydim+60,COLORS.WHITE);
    
    if block > 1
        % Also display rest of block data summary
        tot_trial = block * STIM.trials;
        totes_c = DPT.data.correct == 1;
        corr_count_totes = sprintf('Number Correct: \t%d of %d',length(find(totes_c)),tot_trial);
        corr_per_totes = length(find(totes_c))*100/tot_trial;
        corr_pert_totes = sprintf('Percent Correct:\t%4.1f%%',corr_per_totes);
        
        if isempty(totes_c(totes_c ==1))
            %Don't try to calculate RT, they have missed EVERY SINGLE GO
            %TRIAL! 
            %Stop task & alert experimenter?
            tot_rt = sprintf('Block %d Average RT:\tUnable to calculate RT due to 0 correct trials.',block);
        else
            totrts = DPT.data.rt;
            totrts = totrts(totes_c);
            avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
            tot_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_tote);
        end
        
        DrawFormattedText(w,'Total Results','center',ibt_ydim+120,COLORS.WHITE);
        DrawFormattedText(w,corr_count_totes,ibt_xdim,ibt_ydim+150,COLORS.WHITE);
        DrawFormattedText(w,corr_pert_totes,ibt_xdim,ibt_ydim+180,COLORS.WHITE);
        DrawFormattedText(w,tot_rt,ibt_xdim,ibt_ydim+210,COLORS.WHITE);
        
        %Test if getting better or worse; display feedback?
    end
    
    DrawFormattedText(w,'Press any key to continue','center',wRect(4)-100,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
end

%% Save all the data

%Export GNG to text and save with subject number.
%find the mfilesdir by figuring out where show_faces.m is kept
[mfilesdir,~,~] = fileparts(which('DotProbe_Training.m'));

%get the parent directory, which is one level up from mfilesdir
savedir = [mfilesdir filesep 'Results' filesep];

if exist(savedir,'dir') == 0;
    % If savedir (the directory to save files in) does not exist, make it.
    mkdir(savedir);
end

try

save([savedir 'GNG_' num2str(ID) '_' num2str(SESS) '.mat'],'GNG');

catch
    error('Although data was (most likely) collected, file was not properly saved. 1. Right click on variable in right-hand side of screen. 2. Save as SST_#_#.mat where first # is participant ID and second is session #. If you are still unsure what to do, contact your boss, Kim Martin, or Erik Knight (elk@uoregon.edu).')
end

DrawFormattedText(w,'Thank you for participating\n in the Dot Probe Task!','center','center',COLORS.WHITE);
Screen('Flip', w);
WaitSecs(10);

%Clear everything except data structure
clearvar -except DPT

sca

end

%%
function [trial_rt, correct] = DoDotProbeTraining(trial,block,varargin)

global w STIM PICS COLORS DPT KEY pahandle

correct = -999;                         %Set/reset "correct" to -999 at start of every trial
lr = DPT.var.lr(trial,block);           %Bring in L/R location for probe; 1 = L, 2 = R

if lr == 1;                             %set up response keys for probe (& not picture)
    corr_respkey = KEY.left;
    incorr_respkey = KEY.right;
    notlr = 2;
else
    corr_respkey = KEY.right;
    incorr_respkey = KEY.left;
    notlr = 1;
end

%Display fixation for 500 ms
DrawFormattedText(w,'+','center','center',COLORS.WHITE);
Screen('Flip',w);
WaitSecs(.5);                              %Jitter this for fMRI purposes.

if DPT.var.cprobe(trial,block)== 1;
    %If this is a counter-probe trial, draw hi cal food where probe will appear.
    Screen('DrawTexture',w,PICS.out(trial).texture_lo,[],STIM.img(notlr,:));    
    Screen('DrawTexture',w,PICS.out(trial).texture_hi,[],STIM.img(lr,:));
else
    %Otherwise, draw lo cal food where probe will appear.
    Screen('DrawTexture',w,PICS.out(trial).texture_lo,[],STIM.img(lr,:));
    Screen('DrawTexture',w,PICS.out(trial).texture_hi,[],STIM.img(notlr,:));
end

    Screen('Flip',w);
    WaitSecs(.5);                   %Display pics for 500 ms before dot probe 
    
    Screen('FillOval',w,COLORS.WHITE,STIM.probe(lr,:));
    RT_start = Screen('Flip',w);
    if DPT.var.signal(trial, block) == 1;
        PsychPortAudio('Start', pahandle, 1);
        % XXX: Delay between probe & signal onset?
    end
    telap = GetSecs() - RT_start;


    while telap <= (STIM.trialdur - .500); %XXX: What is full trial duration?
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck();            %wait for key to be pressed
        if Down == 1 
            if find(Code) == corr_respkey;
                trial_rt = GetSecs() - RT_start;
            
                if DPT.var.signal(trial,block) == 1;        %This is a no-go signal round. Throw incorrect X.
                    DrawFormattedText(w,'X','center','center',COLORS.RED);
                    Screen('Flip',w);
                    correct = 0;
                    WaitSecs(.5);

                else                                        %If no signal + Press, move on to next round.
                    Screen('Flip',w);                        %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
                    correct = 1;
                
                end
            break    
            
            elseif find(Code) == incorr_respkey %The wrong key was pressed. Throw X regardless of Go/No Go
                trial_rt = GetSecs() - RT_start;
                
                DrawFormattedText(w,'X','center','center',COLORS.RED);
                Screen('Flip',w);
                correct = 0;
                WaitSecs(.5);
                break
            else
                FlushEvents();
            end
        end
        
        
    end
    
    if correct == -999;
%     Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.img(lr,:));
        
        if DPT.var.signal(trial,block) == 1;    %NoGo Trial + Correct no press. Do nothing, move to inter-trial
            Screen('Flip',w);                   %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
            correct = 1;
        else                                    %Incorrect no press. Show "X" for .5 sec.
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
            WaitSecs(.5);
        end
        trial_rt = -999;                        %No press = no RT
    end
    

FlushEvents();
end

%%
function DrawPics4Block(block,varargin)

global PICS DPT w STIM

    for j = 1:STIM.trials;
        %Get pic # for given trial's hi & low cal food
        pic_hi = DPT.var.picnum_hi(j,block);
        pic_lo = DPT.var.picnum_lo(j,block);
        PICS.out(j).raw_hi = imread(getfield(PICS,'in','hi',{pic_hi},'name'));
        PICS.out(j).raw_lo = imread(getfield(PICS,'in','lo',{pic_lo},'name'));
        PICS.out(j).texture_hi = Screen('MakeTexture',w,PICS.out(j).raw_hi);
        PICS.out(j).texture_lo = Screen('MakeTexture',w,PICS.out(j).raw_lo);
        
%         switch DPT.var.trial_type(j,block)
%             case {1}
%                 PICS.out(j).raw = imread(getfield(PICS,'in','go',{pic},'name'));
% %                 %I think this is is covered outside of switch/case
% %                 PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
%             case {2}
%                 PICS.out(j).raw = imread(getfield(PICS,'in','no',{pic},'name'));
%             case {3}
%                 PICS.out(j).raw = imread(getfield(PICS,'in','neut',{pic},'name'));
%         end
    end
%end
end

%%
% function DrawDashRect(varargin)
% 
% global STIM w COLORS 
% 
% xl = STIM.framerect(1);
% xr = STIM.framerect(3)+10;
% yt = STIM.framerect(2);
% yb = STIM.framerect(4)+10;
% 
% Screen('DrawLine',w,COLORS.WHITE,xl,yt,xl,yb,6);
% Screen('DrawLine',w,COLORS.WHITE,xl,yb,xr,yb,6);
% Screen('DrawLine',w,COLORS.WHITE,xr,yt,xr,yb,6);
% Screen('DrawLine',w,COLORS.WHITE,xl,yt,xr,yt,6);
% %Screen('Flip',w);
% 
% end

