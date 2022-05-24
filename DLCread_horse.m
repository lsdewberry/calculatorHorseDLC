%choose path
%clear variables;
%clearvars -except output
%scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\Fatigue Data Set';
scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\2.3.22 files rerun\Old Files - Re-Run\hand select';

%%
files = dir(scipath);
files = files(3:end);%should be 3

 %pixeltocm=15; %this is a rough value used to calculate a rough velocity. The real pixtocm varied for each day.
%framestosecs = 500/1; %frames/sec - I ended up just getting pixels/frame
%in this code and converting it later, except for the rough velocity
%calculation at the end. (this is not the velocity I actually analyze for
%final graphs. It's just there to give me an idea which trials have
%issues).

L=0.8; %tolerance cutoff for DLC's likelyhood metric

%define colors for graphing
colorsP = cbrewer('qual', 'Paired', 8+4);
colorsS = cbrewer('qual','Set2',4+1);
colors = [colorsP(1:8,:);colorsS(1:4,:);colorsP(9:12,:);colorsS(5,:)];

%filters to smooth jitter from the line for finding FSTO.
d1 = designfilt('lowpassiir','FilterOrder',3,'HalfPowerFrequency',0.05,'DesignMethod','butter');
d2 = designfilt('lowpassiir','FilterOrder',3,'HalfPowerFrequency',0.04,'DesignMethod','butter'); %this is the stricter one lol

%counter, should be same as filenum.
i=1;
for filenum = 2:size(files, 1)
    try
    i=filenum;
    close all
    spotcheck = 1; %round(rand(1)*rand(1)); %Loud or quiet - do you want it to graph stuff.
    pausevalue = 0; %if I want to pause after graphing each few lines. Otherwise it graphs all quick.
    %% import excel files
    myfile = files(filenum).name
    output(i).filname = myfile; %I will have a massive 'output' structure at the end of this. I really need to initialize output tbh.
    scifile = [scipath, '\', myfile];
     [frame, RightForex, RightForey,   RightForel,RightHindToex,RightHindToey,RightHindToel,RightHindHeelx,RightHindHeely,RightHindHeell,rightFfetlockx,rightFfetlocky,rightFfetlockl,RightHindMidx, RightHindMidy, RightHindMidl, rightkneex,rightkneey,rightkneel,  handlerRfootx,handlerRfooty,handlerRfootl,handlerRkneex, handlerRkneey, handlerRkneel, nosex, nosey,      nosel,pollx,polly, polll,    Backx,    Backy,    Backl,shoulderx,shouldery,  shoulderl,elbowx,elbowy,elbowl,croupx, croupy, croupl,hipx, hipy, hipl, stiflex,stifley,stiflel, TailBasex,      TailBasey,        TailBasel,       LeftForex,LeftForey,   LeftForel,LeftHindToex,LeftHindToey,LeftHindToel,LeftHindHeelx,LeftHindHeely,LeftHindHeell, leftFfetlockx, leftFfetlocky, leftFfetlockl,LeftHindMidx, LeftHindMidy, LeftHindMidl, leftkneex,leftkneey,leftkneel, handlerLfootx,handlerLfooty,handlerLfootl, handlerLkneex,handlerLkneey,handlerLkneel] = import_horse(scifile);

    %% find direction of travel using nose
    Nx= nosex(nosel>L); %filter by likelyhood
    if Nx(end)>Nx(1)
        direction = 'right'; %if the animal is going to the right, I trust its right paw
        directionfactor=-1; %used so I don't have a bimodal back angle distribution because of direction of travel
    elseif Nx(end)<Nx(1)
        direction = 'left '; %if the animal is going to the left, I trust its left paw
        directionfactor=1; %used so I don't have a bimodal back angle distribution because of direction of travel
    else
        error('direction?')
    end
    output(i).direction = direction;
    
    %% level of floor - could improve this by making it a line off of two points -  min in 1st half and min in 2nd half of data
    floor = [min(-LeftForey(LeftForel>L)), min(-RightForey(RightForel>L))]; %in pixels. It's inverted because origin is top left for DLC data
    if abs(floor(1)-floor(2))>5 
        fprintf('floors too different :(')
        floor = [floor, min(-RightHindToey(RightHindToel>L)), min(-LeftHindToey(LeftHindToel>L))]; %add more data points
        floor = rmoutliers(floor); %remove any freak data points
        floor = mean(floor); %take an average and try it (double check the ones that print floors to different')
    else 
        floor = mean(floor);
    end
    
    %% setup figure
    if spotcheck == 1
        fig1=figure(1); hold on; %figure for entire trial
        xlabel('frames in video');
        legend('Location','eastoutside');
        fig1.Position=[0,40,1000,1000-40];
        set(gca,'LooseInset',get(gca,'TightInset'));
        % the force plate points (below) don't work very well so I commented them
        % out, still hoping I can add them back one day.
        %  plot(min(frame(ABforcePlateCenterl>(L-0.1))),mean(ABforcePlateCenterx(ABforcePlateCenterl>(L-0.1))),'o','DisplayName','ABforcePlateCenter');
        %  plot(min(frame(CDforcePlateCenterl>(L-0.1))),mean(CDforcePlateCenterx(CDforcePlateCenterl>(L-0.1))),'o','DisplayName','CDforcePlateCenter');
        fig2 = figure(2); hold on; % figure for average stride
        xlabel('% stride from frame with toe off to next frame with toe off');
        legend('Location','eastoutside');
        fig2.Position=[1000,40,1000-40,1000-40];
        set(gca,'LooseInset',get(gca,'TightInset'));
    end

    %% Rename variables to make things easy   
    %make it so it only counts the one in front. (one of my main outcomes
    %is toe height, and I don't trust the toe height of the back foot
    %because the body is in the way.)
    if direction=='left ' 
        %im just going to rename variables
        ForeX = LeftForex;        ForeY = LeftForey;        ForeL = LeftForel;
        HindToeX = LeftHindToex;  HindToeY = LeftHindToey;  HindToeL = LeftHindToel;
        HindMidX = LeftHindMidx;  HindMidY = LeftHindMidy;  HindMidL = LeftHindMidl;
        HindHeelX = LeftHindHeelx;HindHeelY = LeftHindHeely;HindHeelL = LeftHindHeell;
    elseif direction=='right'
        ForeX = RightForex;        ForeY = RightForey;        ForeL = RightForel;
        HindToeX = RightHindToex;  HindToeY = RightHindToey;  HindToeL = RightHindToel;
        HindMidX = RightHindMidx;  HindMidY = RightHindMidy;  HindMidL = RightHindMidl;
        HindHeelX = RightHindHeelx;HindHeelY = RightHindHeely;HindHeelL = RightHindHeell;
    else
        error('direction?')
    end
    
    %% analysis of sided data
    %Hind heel
    HHx = HindHeelX(HindHeelL>L); HHf=frame(HindHeelL>L); color=colors(1,:); %hind heel x
    HHy = (-HindHeelY(HindHeelL>L))-floor; %y is inverted because origin is top left
        [sHHx,sHHy,sHHf] = basiccmooth(HHx, HHy, HHf, d2);%using slightly more strict filter
      [output(i).Hdutyfactor.avg, output(i).Hstridelength.avg, output(i).numcycles, ...
          output(i).stridestance.y.avg, output(i).stridestance.f.avg, strides, ...
          output(i).Hdutyfactor.std,output(i).Hstridelength.std,...
          output(i).stridestance.y.std,output(i).stridestance.f.std] = pulloutXstuff(sHHx,sHHf,directionfactor,spotcheck,1,color,'HindHeelX');
      if size(strides,1)<1 || sum(sum((isnan(strides))))
          horseReqOut(i).fileName = output(i).filname;
          horseReqOut(i).Direction = output(i).direction;
          horseReqOut(i).numberofcycles = output(i).numcycles;
          if spotcheck
            saveas(fig1,[myfile,'_fulltrial.png']);
          end
          continue %go to next iteration of for loop because there aren't enough strides in this trial
      end
        output(i).Hstridelength.avg = output(i).Hstridelength.avg*-directionfactor;
      [output(i).HH.x.avg, output(i).HH.f.avg, output(i).HH.x.std,output(i).HH.f.std] = avgforstride (sHHx,sHHf, strides, 'x',spotcheck,color,'HindHeelX'); 
        if spotcheck & pausevalue
            pause
        end
       color=colors(2,:);%rand(1,3);
      [~,output(i).HeelProminance.avg,~,output(i).HeelProminance.std] = pulloutYstuff(sHHy,sHHf,spotcheck,color,'HindHeelY');%mean 1/2 peak width and mean prominance
      [output(i).HH.y.avg, ~,output(i).HH.y.std,~] =   avgforstride(sHHy,sHHf, strides, 'z',spotcheck,color,'HindHeelY'); 
        if spotcheck & pausevalue
            pause
        end
    %Hind midfoot    
    HMx= HindMidX(HindMidL>L); HMf=frame(HindMidL>L);color=colors(3,:);%rand(1,3);
    HMy= -HindMidY(HindMidL>L)-floor;
    [sHMx,sHMy,sHMf] = basiccmooth(HMx, HMy, HMf, d1);%using og filter 
      [output(i).HM.x.avg, output(i).HM.f.avg,output(i).HM.x.std,output(i).HM.f.std] = avgforstride (sHMx,sHMf, strides, 'x',spotcheck,color,'HindMidX');
        if spotcheck
            figure(1);hold on;
            plot(sHMf,sHMx/10,'Color',color,'DisplayName','HindMidX/10')
            if pausevalue
            pause
            end
        end
     color=colors(4,:);%rand(1,3);%height of midfoot relative to floor 
      [output(i).HM.y.avg, ~,output(i).HM.y.std] = avgforstride (sHMy,sHMf, strides, 'y',spotcheck,color,'HindMidY'); 
        if spotcheck
            figure(1);hold on;
            plot(sHMf,sHMy,'Color',color,'DisplayName','HindMidY')
            if pausevalue
            pause
            end
        end
    %Hind Toe    
    HTx= HindToeX(HindToeL>L); HTf=frame(HindToeL>L);color=colors(5,:);%rand(1,3);
    HTy = -HindToeY(HindToeL>L)-floor;
    [sHTx,sHTy,sHTf] = basiccmooth(HTx, HTy, HTf, d1);%using og filter 
      [output(i).HT.x.avg, output(i).HT.f.avg,output(i).HT.x.std,output(i).HT.f.std] = avgforstride (sHTx,sHTf, strides, 'x',spotcheck,color,'HindToeX');
        if spotcheck
            figure(1);
            %plot(frame(HindHeelL>L),HHx,'DisplayName','HindHeelX')
            plot(sHTf,sHTx/10,'Color',color,'DisplayName','HindToeX/10')
        end
        color=colors(6,:);%rand(1,3);%y is inverted because origin is top left
      [~,output(i).ToeProminance.avg,~,output(i).ToeProminance.std] = pulloutYstuff(sHTy,sHTf,spotcheck,color,'HindToeY');%mean 1/2 peak width and mean prominance
      [output(i).HT.y.avg, ~,output(i).HT.y.std] = avgforstride (sHTy,sHTf, strides, 'y',spotcheck,color,'HindToeY');
        if spotcheck & pausevalue
            pause
        end
        
    %fore    
    Fx = ForeX(ForeL>L);Ff=frame(ForeL>L);color=colors(7,:);%rand(1,3);
    Fy= -ForeY(ForeL>L)-floor;
    [sFx,sFy,sFf] = basiccmooth(Fx, Fy, Ff, d2);%using d2 filter    
      [output(i).Fdutyfactor.avg, output(i).Fstridelength.avg, ~, ~, ~, ~, output(i).Fdutyfactor.std,output(i).Fstridelength.std,~,~] = pulloutXstuff(sFx,sFf,directionfactor,spotcheck,0, color,'ForeX');
        output(i).Fstridelength.avg = output(i).Fstridelength.avg*directionfactor;
      [output(i).F.x.avg, output(i).F.f.avg,output(i).F.x.std,output(i).F.f.std] = avgforstride(sFx,sFf, strides, 'x',spotcheck,color,'ForeX');
     color=colors(8,:);%rand(1,3);
      [output(i).F.y.avg, ~,output(i).F.y.std] = avgforstride(sFy,sFf, strides, 'z',spotcheck,color,'ForeY'); 
        if spotcheck
            figure(1);hold on; 
            plot(sFf,sFy,'Color',color,'DisplayName','ForeY');
            if pausevalue
            pause
            end
        end
        
    TBMF = sqrt( ((HindMidY-TailBasey).^2)+((HindMidX-TailBasex).^2) ); color=colors(9,:);%rand(1,3);%Tailbase to midfoot length
        TBMF =  TBMF(HindMidL>L & TailBasel>L);        TBMFf =frame(HindMidL>L & TailBasel>L);
        [sTBMF,~,sTBMFf] = basiccmooth(TBMF, TBMF,TBMFf, d1);%using og filter   
      [output(i).TBMF.y.avg, output(i).TBMF.f.avg,output(i).TBMF.y.std,output(i).TBMF.f.std] = avgforstride(sTBMF,sTBMFf, strides, 'y', spotcheck,color,'TailBaseMidFootLength');
        if spotcheck
            figure(1);hold on;
            %plot(TBMFf,TBMF,'DisplayName','TailBasetoMidFootLength');
            plot(sTBMFf,sTBMF/10,'Color',color,'DisplayName','TailBasetoMidFootLength/10')
            if pausevalue
            pause
            end
        end
        
     shankLength = sqrt( ((HindMidY-HindHeelY).^2)+((HindMidX-HindHeelX).^2) ); color=colors(9,:);%rand(1,3);%shank length for normalizing
        shankLength =  shankLength(HindMidL>L & HindHeelL>L);        shankLengthf =frame(HindMidL>L & HindHeelL>L);
        [sshankLength,~,sshankLengthf] = basiccmooth(shankLength, shankLength,shankLengthf, d1);%using og filter   
      [output(i).shankLength.y.avg, output(i).shankLength.f.avg,output(i).shankLength.y.std,output(i).shankLengthF.f.std] = avgforstride(sshankLength,sshankLengthf, strides, 'y', spotcheck,color,'TailBaseMidFootLength');
        output(i).shankLength.avg = mean(output(i).shankLength.y.avg);
      if spotcheck
            figure(1);hold on;
            %plot(TBMFf,TBMF,'DisplayName','TailBasetoMidFootLength');
            plot(sshankLengthf,sshankLength/10,'Color',color,'DisplayName','shankLength/10')
            if pausevalue
            pause
            end
      end
          
             headLength = sqrt( ((polly-nosey).^2)+((pollx-nosex).^2) ); color=colors(9,:);%rand(1,3);%headLength for normalizing
        headLength =  headLength(polll>L & nosel>L);        headLengthf =frame(polll>L & nosel>L);
        [sheadLength,~,sheadLengthf] = basiccmooth(headLength, headLength,headLengthf, d1);%using og filter   
      [output(i).headLength.y.avg, output(i).headLength.f.avg,output(i).headLength.y.std,output(i).headLengthF.f.std] = avgforstride(sheadLength,sheadLengthf, strides, 'y', spotcheck,color,'headLength');
        output(i).headLength.avg = mean(output(i).headLength.y.avg);
      if spotcheck
            figure(1);hold on;
            %plot(TBMFf,TBMF,'DisplayName','TailBasetoMidFootLength');
            plot(sheadLengthf,sheadLength/10,'Color',color,'DisplayName','headLength/10')
            if pausevalue
            pause
            end
      end  
      
    %HT-HM-HH    
        color=colors(10,:);%rand(1,3);
      [angle, goodframes] = findangle(HindToeX,HindToeY,HindToeL,HindMidX,HindMidY,HindMidL, HindHeelX,HindHeelY,HindHeelL,frame,L,spotcheck,color,'toe-midfoot-heel angle'); %2nd is where the angle is
        [output(i).HT_HM_HH.y.avg, output(i).HT_HM_HH.f.avg,output(i).HT_HM_HH.y.std,output(i).HT_HM_HH.f.std] = avgforstride(angle',goodframes, strides, 'y',spotcheck,color,'toe-midfoot-heel angle');
        if spotcheck & pausevalue
            pause
        end
    %HT-HM-TB
        color=colors(11,:);%rand(1,3);
      [angle, goodframes] = findangle(HindToeX,HindToeY,HindToeL,HindMidX,HindMidY,HindMidL, TailBasex,TailBasey,TailBasel,frame,L,spotcheck,color,'toe-midfoot-tailbase angle'); %2nd is where the angle is
        [output(i).HT_HM_TB.y.avg, output(i).HT_HM_TB.f.avg,output(i).HT_HM_TB.y.std,output(i).HT_HM_TB.f.std] = avgforstride(angle',goodframes, strides, 'y',spotcheck,color,'toe-midfoot-tailbase angle');
        if spotcheck & pausevalue
            pause
        end
    %HT-TB-B
        color=colors(12,:);%rand(1,3);
      [angle, goodframes] = findangle(HindMidX,HindMidY,HindMidL, TailBasex,TailBasey,TailBasel,Backx, Backy, Backl, frame,L,spotcheck,color,'toe-tailbase-back angle'); %2nd is where the angle is
        [output(i).HT_TB_B.y.avg, output(i).HT_TB_B.f.avg,output(i).HT_TB_B.y.std,output(i).HT_TB_B.f.std] = avgforstride(angle',goodframes, strides, 'y',spotcheck,color,'toe-tailbase-back angle');
        if spotcheck & pausevalue
            pause
        end
    %% nonsided
    %nose x 
    Nf = frame(nosel>L);color=colors(13,:);%rand(1,3);%Nx was defined earlier
    Ny= -nosey(nosel>L)-floor;
       [sNx,sNy, sNf] = basiccmooth(Nx, Ny,Nf, d1);%using og filter
     [output(i).N.x.avg, output(i).N.f.avg,output(i).N.x.std,output(i).N.f.std] = avgforstride(sNx,sNf, strides, 'x',spotcheck,color,'NoseX');
       if spotcheck
            figure(1);hold on;
            plot(sNf,sNx/10,'Color',color,'DisplayName','NoseX/10')
       end
     color=colors(14,:);%rand(1,3);%height of nose relative to floor
      [output(i).N.y.avg, ~,output(i).N.y.std,~] = avgforstride(sNy,sNf, strides, 'y',spotcheck,color,'NoseY'); 
        if spotcheck
            figure(1);hold on;
            plot(sNf,sNy,'Color',color,'DisplayName','NoseY')
            if pausevalue
            pause
            end
        end
        
    %back x
    Bx= Backx(Backl>L); Bf=frame(Backl>L); color=colors(15,:);%rand(1,3);
    By= -Backy(Backl>L)-floor; 
        [sBx,sBy, sBf] = basiccmooth(Bx, By,Bf, d1);%using og filter
       [output(i).B.x.avg, output(i).B.f.avg,output(i).B.x.std,output(i).B.f.std] = avgforstride(sBx,sBf, strides, 'x',spotcheck,color,'BackX');
        if spotcheck
            figure(1);hold on;
            plot(sBf,sBx/10, 'Color',color,'DisplayName','BackX/10')
        end
    color=colors(16,:);%rand(1,3);%height of back relative to floor already defined
       [output(i).B.y.avg, ~,output(i).B.y.std,~] = avgforstride(sBy,sBf, strides, 'y',spotcheck,color,'BackY'); 
        if spotcheck
            figure(1);hold on;
            plot(sBf,sBy/2, 'Color',color,'DisplayName','BackY/2')
            if pausevalue
            pause
            end
        end
        
    backslope = (-(Backy-TailBasey)./(Backx-TailBasex));  color=colors(17,:);%rand(1,3);%(y-y/x-x) %y is negative because the origin is in the top left
        backslope = backslope(Backl>L & TailBasel>L); bsf =frame(Backl>L & TailBasel>L);
        [sbackslope,~,sbsf] = basiccmooth(backslope,backslope, bsf, d1);
        backslope = -directionfactor*(sbackslope);% needed.
        backangle = atand(sbackslope);
      [nBackA, nBAf,nBAstd] = avgforstride(backangle,sbsf, strides, 'y',spotcheck,color,'BackAngle'); 
        if spotcheck == 1
            figure(1); hold on;
            %plot(bsf,-directionfactor*backslope*10,'DisplayName','backslope*10');
            plot(sbsf,backangle,'Color',color,'DisplayName','backangle');
            if pausevalue
            pause
            end
        end
        
    %velocity
        velocity =  abs(gradient(output(i).B.x.avg)) ./ (gradient(output(i).B.f.avg));
        output(i).velocity.avg = abs(mean(velocity));%in pixels per frame
        output(i).velocity.std = std(velocity);%in pixels per frame


    
    
    %pause(3) 
    if spotcheck
     saveas(fig1,[myfile,'_fulltrial.png']);
     saveas(fig2,[myfile,'_avgstride.png']);
    end
    
    horseReqOut(i).fileName = output(i).filname;
    horseReqOut(i).Direction = output(i).direction;
    horseReqOut(i).numberofcycles = output(i).numcycles;
    horseReqOut(i).shanklength = output(i).shankLength.avg;
    horseReqOut(i).headlength = output(i).headLength.avg;
    
    horseReqOut(i).DutyFactorAvg = output(i).Hdutyfactor.avg;
    horseReqOut(i).DutyFactorStd = output(i).Hdutyfactor.std;
    horseReqOut(i).stridelengthAvg = output(i).Hstridelength.avg;
    horseReqOut(i).stridelengthStd = output(i).Hstridelength.std;
    horseReqOut(i).speedAvg = output(i).velocity.avg;
    horseReqOut(i).speedStd = output(i).velocity.std;
    horseReqOut(i).AngleAvg = mean(output(i).HT_HM_HH.y.avg);
    horseReqOut(i).AngleStd = std(output(i).HT_HM_HH.y.avg);
    end

end
allDone = 'Yay!'

%%
function [angle3, goodframes] = findangle(x1,y1,l1, x2, y2, l2, x3, y3, l3,frame, L,spotcheck,color,name)
     d1 = designfilt('lowpassiir','FilterOrder',12, ...
     'HalfPowerFrequency',0.05,'DesignMethod','butter');
     angle3 = [];
     angle = [x1,y1, x2, y2, x3, y3];
     angle = angle((l1>L & l2>L & l3>L),:);
     goodframes = frame((l1>L & l2>L & l3>L),:);
     P0 = angle(:,3:4);
     P1 = angle(:,1:2);
     P2 = angle(:,5:6);

     for i=1:length(goodframes)
        n1 = (P2(i,:) - P0(i,:)) / norm(P2(i,:) - P0(i,:));  % Normalized vectors
        n2 = (P1(i,:) - P0(i,:)) / norm(P1(i,:) - P0(i,:));
        angle3(i) = atan2(norm(det([n2; n1])), dot(n1, n2));  % Stable
     end
     try
        angle3=filtfilt(d1, angle3);
     end
     if spotcheck==1
         figure(1); hold on;
         plot(goodframes,angle3*10,'Color',color,'DisplayName',[name,' *10']);
     end
end
function [mw,mp,stdw,stdp] = pulloutYstuff(data,frames,spotcheck,color,name)
sdata=data;
[pks,locs,w,p] = findpeaks(sdata,frames, 'MinPeakProminence',4,'MinPeakDistance',25,'Annotate','extents');

if length(locs)<3
    %error('Less than 3 footstrikes measured')
end
%Getting rid of ouliers
[~,TFp] = rmoutliers(p,'mean', 'ThresholdFactor',2); %gets rid of anything more than 2 SDs from mean prominance
[~,TFw] = rmoutliers(w,'mean', 'ThresholdFactor',2); %gets rid of anything more than 2 SDs from mean 1/2 peak width
TF = TFp+TFw;
 if spotcheck == 1
    figure(1)
    hold on
    %plot(frames,data,'DisplayName',name);
    plot(frames,sdata,'Color',color,'DisplayName',[name,' smooth']);
    plot(locs(TF==0),pks(TF==0),'r*','DisplayName',[name,' peaks']);
    %refline(0, 0);
 end
mp = mean(p(TF==0));stdp=std(p(TF==0));
mw = mean(w(TF==0));stdw=std(w(TF==0));
end
function [dutyfactor, stridelength, numcycles, datasnew, percentfsnew, strides, dutyfactorStd,stridelengthStd,datasnewstd,percentfsnewstd] = pulloutXstuff(xdata,f,directionfactor,spotcheck,graphfactor, color,name)
% main priority is finding fsto
sxdata=xdata; %remanant from earlier versions
%pivot data so i get more pronounced slope changes
fitobject = fitlm(f,xdata,'linear');
psxdata = sxdata-fitobject.Fitted;
%find derivative
dxdf = gradient(-psxdata(:)) ./ gradient(f(:));
%filter derivative - may not be needed!
d1 = designfilt('lowpassiir','FilterOrder',3, ...
'HalfPowerFrequency',0.015,'DesignMethod','butter');
sdxdf = dxdf; %filtfilt(d1, dxdf);
% %inflection pt is toeoff - decided I didn't like this, too sensitive
% sddxdf = gradient(sdxdf(:)) ./ gradient(f(:));
% [pks,toeoff] = findpeaks(sddxdf,f, 'MinPeakWidth',25,'MinPeakDistance',75); %used to find temporal measures   
%when derivative is higher than 0, it's in swing
stance=(-directionfactor*sdxdf)>1;
[sstance,TF] = rmoutliers(double(stance),'movmedian',5); %remove outliers in sliding window
f2=f(~TF);
sstance(end)=0;%  I make it go back down to 0 so that counts as a stride because then it's easy to just never count the last stride.
offsetforgraphing=rand(1);%I offset the stride/stance so that I can look at multiple stride/stance at once and they don't overlap

[pks,toestrike] = findpeaks(double(sstance),f2, 'MinPeakWidth',5,'MinPeakDistance',50); %used to find temporal measures %toestrike is frame
if spotcheck == 1
    figure(1)
    hold on
    plot(f,sxdata/10,'Color',color,'DisplayName',[name,' /10']);
    if graphfactor==1
        plot(f,sdxdf,'Color',color*(2/3),'DisplayName',[name,' Derivative']);
        plot(f2, (sstance-.1)*100+offsetforgraphing,'.','Color',color*(2.5/3),'DisplayName',[name,' stance']);
        plot([toestrike,toestrike]',[(pks-1.1)*100-offsetforgraphing,(pks-.1)+100+offsetforgraphing]','Color',color*(2.2/3),'HandleVisibility','off');%toeoff 
            plot(0,0,'Color',color,'DisplayName',[name,' toestrike']); %just for the legend info
    end
end
if length(toestrike)<=1
    dutyfactor=nan; stridelength=nan;strides=nan;
    numcycles=0; datasnew=nan;percentfsnew=nan;
    dutyfactorStd=nan;stridelengthStd=nan;datasnewstd=nan;percentfsnewstd=nan;
    return
end
strides = [toestrike(1:end-1),toestrike(2:end)];
stridelengthF= strides(:,2)-strides(:,1);
%[stridelengthF,stridelengthTF] = rmoutliers(stridelengthF,'median'); %remove outliers in sliding window
%strides=strides(~stridelengthTF,:);

 if spotcheck == 1
    figure(1)
    hold on
    if graphfactor==1
       plot(strides',[(ones(size(stridelengthF))-1.1)*100-offsetforgraphing,ones(size(stridelengthF))*100+offsetforgraphing]','Color',color*(2.2/3),'HandleVisibility','off');%toeoff 
    end
 end
 
dutyfactor=[];
stridelength=[];
for j=1:size(strides,1)
    stridestart=strides(j,1);
    strideend  =strides(j,2);
    %temporal
    timestance =sum(stance(f2>=stridestart & f2<strideend));
    dutyfactor(j) = timestance/(strideend-stridestart); %duty factor in frames
    %spatial
    stridelength(j) = -(sxdata(f2==stridestart)-sxdata(f2==strideend));
end

 [datasnew, percentfsnew, datasnewstd,percentfsnewstd] = avgforstride(sstance*100,f2,strides, 'y', spotcheck,color*(1/3),[name,'Stance1 Swing0']);
numcycles = size(strides,1);
dutyfactorStd   = std(dutyfactor);    dutyfactor=mean(dutyfactor);    
stridelengthStd = std(stridelength);stridelength=mean(stridelength);
end
function [avnwinstrides, avnwinfs, avwinstridesSTDEV,avwinfsSTDEV] = avgforstride(data,f2, strides, xz, spotcheck,color,name)
    %minlength = inf;
    datas={};
    winsize = 5;%size in percentage of stride
    %% plot as percent of stride
    for j=1:size(strides,1)
        stridestartf=strides(j,1);
        strideendf  =strides(j,2);
        stridef = f2(f2>=stridestartf & f2<strideendf);
        if length(stridef)<1
            percentf=NaN; winfs{j}=nan;
            mystride=NaN; winstrides{j} =nan;
            break
        end        
        stridef = stridef - stridef(1);%need frames from begining of stride
        percentf = stridef/max(stridef)*100;%convert frames to % of all frames
        mystride = data(f2>=stridestartf& f2<strideendf);%data for stride j

        if xz == 'x'
            mystride = mystride-mystride(1);%if this is x data, i want to normalize to the begining of the stride so that's the minimum
        elseif xz =='z'
            mystride = mystride-min(mystride); %helps to normalize against tilted stage, so min value is always 0
        end

        if spotcheck
            figure(2); hold on;
            %plot(percentf, mystride,':','Color',color/j,'DisplayName',[name,' stride ',num2str(j)])
            plot(percentf, mystride,':','Color',color,'HandleVisibility','off') %plot individual strides
        end
        winnum=1;%index for which window bin we are on
        for k = 0:winsize:100-winsize %window moving over data to get only minnumpoints for each winsize % of stride
            %winstride = mystride(percentf>=k & percentf<k+winsize);
            %winf = percentf(percentf>=k & percentf<k+winsize);
            
            winstrides{j,winnum} = mystride(percentf>=k & percentf<k+winsize);%save strides
            winfs{j,winnum} = percentf(percentf>=k & percentf<k+winsize);%save f values for strides
            winnum=winnum+1;
        end
    end
    %j
    if exist('winstrides', 'var')==0
        pause
    end
    % msg=['testing sizes line 420, should be true: ',num2str(size(winstrides,2)==100/winsize)] %troubleshooting
    %initialize some things
    nwinstrides=cell(size(winstrides,1),1);
    nwinfs=cell(size(winstrides,1),1);
    weights=cell(size(winstrides,1),1);
    for m=1:size(winstrides,2) %loop thru the number of bins that exist. should = 100/winsize
        wins=winstrides(:,m);%select only bin m for all strides
        minps = min(cellfun('size',wins,1));
        if minps<=0
            %msg=['need to increase winsize? winsize=',num2str(winsize)]
            %or maybe exclude the stride missing the data?
            %could decide based on stride length outliers?
            minps=1;
        end
        for n=1:size(winstrides,1) %loop thru the strides (n) for each bin (m).
            winnm=winstrides{n,m}; %select the bin in question
            winfnm=winfs{n,m}; %select fs for the bin in question
            if length(winnm)>minps
                newis = round(linspace(1,length(winnm),minps));
                nwinnm = winnm (newis);
                nwinfnm = winfnm(newis);
                nwinstrides{n} = [nwinstrides{n}, nwinnm'];%
                nwinfs{n}      = [     nwinfs{n},nwinfnm'];%
                weights{n}     = [    weights{n},ones(size(nwinnm'))];
            elseif length(winnm)==minps
                nwinstrides{n} = [nwinstrides{n}, winnm'];%
                nwinfs{n}      = [     nwinfs{n},winfnm'];%
                weights{n}     = [    weights{n},ones(size(winnm'))];
            else %if i don't have enough data i'm interpolating.
                msg2{n,m} = ['no data for ',name,' Toeoff ',num2str(n),', percentf ',num2str(m)];
                winmminus1 = nan; winmplus1  = nan; winfnminus1 = nan; winfnplus1  = nan;winnminus1=nan;winfallns=nan;
                try    winmminus1 = winstrides{n,m-1};  end %same stride bin previous
                try    winmplus1  = winstrides{n,m+1};  end %same stride bin next
                try    winnminus1 = nwinstrides{n}(end);  end %the avg bin we just appended (this works, i just think it's better to nan these)
                for smalln=1:size(winfs,1) %all stride f for bin
                    winfallns = [winfallns;(winfs{smalln,m})];      
                end 
                nwinnm = nanmean([ winmminus1; winmplus1;winnminus1]);%what if mminus one and plus 1 are both empty??
                nwinfnm= nanmean([winfallns]);
                
                if isnan(mean([nwinnm,nwinfnm])) %catch error
                    % error('we do not got any data breh')
                end
                nwinstrides{n} = [nwinstrides{n}, nwinnm];%
                nwinfs{n}      = [     nwinfs{n},nwinfnm];%
                wei  ghts{n}     = [    weights{n},0.5*ones(size(nwinnm))];%don't care abt these points
                %alternative - make winsize higher? or include 2 bins for this point?
            end
            if sum([size(nwinstrides{n})==size(nwinfs{n}),size(nwinstrides{n})==size(weights{n}),-4])
            error('yo our stuff is not lining up right')
            end
        end
    end
    nwinstrides = cell2mat(nwinstrides); nwinfs = cell2mat(nwinfs); weights = cell2mat(weights); 
    % nanmean with weights for data
    avnwinstrides = nansum(nwinstrides.*weights,1)./nansum(weights,1);
    avwinstridesSTDEV = sqrt(nansum(weights.*((nwinstrides-avnwinstrides).^2))./(nansum(weights,1)-(nansum(weights.^2,1)/nansum(weights))));
    % nanmean with weights for percentf
    avnwinfs = nansum(nwinfs.*weights,1)./nansum(weights,1);
    avwinfsSTDEV =sqrt(nansum(weights.*((nwinfs-avnwinfs).^2))./(nansum(weights,1)-(nansum(weights.^2,1)/nansum(weights))));

    if spotcheck
        figure(2);hold on;
        plot(avnwinfs', avnwinstrides','Color',color,'LineWidth',2,'DisplayName',[name,' avg'])
    end

end
function [sdatax,sdatay,sdataf] = basiccmooth(datax,datay,dataf, d1)
    if exist('d1','var')
        %do nothing
    else
        d1 = designfilt('lowpassiir','FilterOrder',3, ...
        'HalfPowerFrequency',0.1,'DesignMethod','butter');
    end
    [sdata,TFdata] = rmoutliers([datax,datay],'movmedian',20);
    sdatax=sdata(:,1);
    sdatay=sdata(:,2);
    sdataf=  dataf(sum(TFdata,2)==0);
    try
    sdatax = filtfilt(d1, sdatax); %rmoutliers isn't a 0 shift filter
    sdatay = filtfilt(d1, sdatay); %rmoutliers isn't a 0 shift filter
    end
end