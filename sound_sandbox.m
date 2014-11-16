
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

Screen('Preference','SkipSyncTests',1);

%change this to 0 to fill whole screen
DEBUG=1;
%set up the screen and dimensions

if DEBUG;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
    [w, wRect] = Screen('OpenWindow', 0, 0,winRect);
else
    
    screennumber = 1; %min(Screen('Screens')); %gets screen number
    screennumber2 = 2; %max(Screen('Screens'));
    %change screen resolution
    %Screen('Resolution',0,1600,900,[],32);
    
    
    [w, wrect] = Screen('OpenWindow', screennumber,0);
    %[xdim, ydim] = Screen('WindowSize', screennumber);
    
    
    Screen('TextFont', w, 'Arial');
    Screen('TextStyle', w, 1);
    Screen('TextSize',w,30);
    
    if screennumber~=screennumber2
        
        [w2, wrect2] = Screen('OpenWindow', screennumber2,0);
        Screen('TextFont', w2, 'Arial');
        Screen('TextStyle', w2, 1);
        Screen('TextSize',w2,30);
        
    end
    
    if screennumber==screennumber2
        
        w2=w;
        
    end
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screennumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    %winRect=[];
    %For running on two monitors
    %     [w, wRect]=Screen('OpenWindow', 1, 0,winRect,32,2);  %subj screen
    %     [w2, wRect2]=Screen('OpenWindow', 2, 0,winRect,32,2); %experimenter screen
end

wave=sin(1:0.25:1000);
%freq=Fy*1.5; % change this to change freq of tone
freq=22254;
nrchannels = size(wave,1);
% Default to auto-selected default output device:
deviceid = -1;
% Request latency mode 2, which used to be the best one in our measurement:
reqlatencyclass = 2; % class 2 empirically the best, 3 & 4 == 2
% Initialize driver, request low-latency preinit:
InitializePsychSound(1);
% Open audio device for low-latency output:
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, nrchannels);
%Play the sound
PsychPortAudio('FillBuffer', pahandle, wave);
PsychPortAudio('Start', pahandle, 1, 0, 0);
WaitSecs(1);
PsychPortAudio('Stop', pahandle);
    
    
lr_rect = [XCENTER-100, YCENTER-10, XCENTER-80, YCENTER+10; XCENTER+80, YCENTER-10, XCENTER+100, YCENTER+10];
% lr_rect = [XCENTER-10, YCENTER-10, XCENTER+10, YCENTER+10; XCENTER-20, YCENTER-20, XCENTER+20, YCENTER+20];

trials = 20;
correct = zeros(trials,1)-999;
trial_rt = zeros(trials,1)-999;

keykey = [KEY.left; KEY.right];

for trial = 1:trials;
    lr = randi(2);
    sound = randi(3);
    corr_respkey = keykey(lr);
    
    Screen('FillOval',w,[],lr_rect(lr,:));
    RT_start = Screen('Flip',w);
    if sound == 1;
        Beeper();
    else
    end
    telap = GetSecs() - RT_start;
     while telap <= (2); %XXX: What is full trial duration?
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck();            %wait for key to be pressed
        if Down == 1 && find(Code) == corr_respkey
            trial_rt(trial) = GetSecs() - RT_start;
            
            if sound == 1;        %This is a no-go signal round. Throw incorrect X.
                DrawFormattedText(w,'X','center','center',COLORS.RED);
                Screen('Flip',w);
                correct(trial) = 0;
                WaitSecs(.5);
            else                                        %If no signal + Press, move on to next round.
                Screen('Flip',w);                       %'Flip' in order to clear buffer; next flip (in main script) flips to black screen.
                correct(trial) = 1;
            end
            break
            
%         elseif Down == 1 && find(Code) == incorr_respkey %The wrong key was pressed. Throw X regardless of Go/No Go
%             trial_rt = GetSecs() - RT_start;
%             
%             DrawFormattedText(w,'X','center','center',COLORS.RED);
%             Screen('Flip',w);
%             correct = 0;
%             WaitSecs(.5);
%             break
        end
        
     end
     Screen('Flip',w);
     WaitSecs(.75);
end

