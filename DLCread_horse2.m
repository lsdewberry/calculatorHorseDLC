%choose path
%clear variables;
%clearvars -except output

%scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\Fatigue_2.0\Fair_Hill2019';
%scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\Fatigue_2.0\FHP_Int2019';
%scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\Fatigue_2.0\FHP_Int2022';
%scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\Fatigue_2.0\Ocala_Int2019';
scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\Fatigue_2.0\Red_Hills2020';
%scipath = 'C:\Users\savan\OneDrive - University of Florida\LAB\horse\7.19.22\Genotype_Angles';

%%
files = dir(scipath);
files = files(3:end-1);%should be 3

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
for filenum = 1:size(files, 1)%select files to run
    i=filenum;
    close all
    spotcheck =1; %round(rand(1)*rand(1)); %Loud or quiet - do you want it to graph stuff.
    pausevalue = 0; %if I want to pause after graphing each few lines. Otherwise it graphs all quick.
    %% import excel files
    myfile = files(filenum).name
    disp(['filenum ',num2str(filenum), ': ',myfile]);
    output(i).filname = myfile; %I will have a massive 'output' structure at the end of this. I really need to initialize output tbh.
    scifile = [scipath, '\', myfile];
     [frame, RightForex, RightForey,   RightForel,RightHindHoofx,RightHindHoofy,RightHindHoofl,RightHindHockx,RightHindHocky,RightHindHockl,rightFfetlockx,rightFfetlocky,rightFfetlockl,RightHindFetlockx, RightHindFetlocky, RightHindFetlockl, rightkneex,rightkneey,rightkneel,  handlerRfootx,handlerRfooty,handlerRfootl,handlerRkneex, handlerRkneey, handlerRkneel, nosex, nosey,      nosel,pollx,polly, polll,    withersx,    withersy,    withersl,shoulderx,shouldery,  shoulderl,elbowx,elbowy,elbowl,croupx, croupy, croupl,hipx, hipy, hipl, stiflex,stifley,stiflel, TailBasex,      TailBasey,        TailBasel,       LeftForex,LeftForey,   LeftForel,LeftHindHoofx,LeftHindHoofy,LeftHindHoofl,LeftHindHockx,LeftHindHocky,LeftHindHockl, leftFfetlockx, leftFfetlocky, leftFfetlockl,LeftHindFetlockx, LeftHindFetlocky, LeftHindFetlockl, leftkneex,leftkneey,leftkneel, handlerLfootx,handlerLfooty,handlerLfootl, handlerLkneex,handlerLkneey,handlerLkneel] = import_horse(scifile);
    try
    %% find direction of travel using nose
    Nx= nosex(nosel>L); %filter by likelyhood
    if length(Nx)<1
        output(i).byEye= 'length(Nx)<1' ;
        continue %stop doing this trial if there are no nose points
    end
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
        HindHoofX = LeftHindHoofx;  HindHoofY = LeftHindHoofy;  HindHoofL = LeftHindHoofl;
        HindFetlockX = LeftHindFetlockx;  HindFetlockY = LeftHindFetlocky;  HindFetlockL = LeftHindFetlockl;
        HindHockX = LeftHindHockx;HindHockY = LeftHindHocky;HindHockL = LeftHindHockl;
    elseif direction=='right'
        ForeX = RightForex;        ForeY = RightForey;        ForeL = RightForel;
        HindHoofX = RightHindHoofx;  HindHoofY = RightHindHoofy;  HindHoofL = RightHindHoofl;
        HindFetlockX = RightHindFetlockx;  HindFetlockY = RightHindFetlocky;  HindFetlockL = RightHindFetlockl;
        HindHockX = RightHindHockx;HindHockY = RightHindHocky;HindHockL = RightHindHockl;
    else
        error('direction?')
    end
    %% smoothing the lowest value Y things to try to find the floor from them
    % Hind Toe smoothing
    HHoofx = HindHoofX(HindHoofL>L); HHooff=frame(HindHoofL>L); %hind toe x
    HHoofy = (-HindHoofY(HindHoofL>L)); %y is inverted because origin is top left
    [sHHoofx,sHHoofy,sHHooff] = basiccmooth(HHoofx, HHoofy, HHooff, d2);
    %Hind midfoot smoothing
    HFetlockx= HindFetlockX(HindFetlockL>L); HFetlockf=frame(HindFetlockL>L);
    HFetlocky= -HindFetlockY(HindFetlockL>L); 
    [sHFetlockx,sHFetlocky,sHFetlockf] = basiccmooth(HFetlockx, HFetlocky, HFetlockf, d1);
    %Hind Heel smoothing
    HHockx= HindHockX(HindHockL>L); HHf=frame(HindHockL>L);
    HHocky = -HindHockY(HindHockL>L);
    [sHHockx,sHHocky,sHHockf] = basiccmooth(HHockx, HHocky, HHf, d1);%using og filter 
    %fore foot smoothing
    Fx= ForeX(ForeL>L); Ff=frame(ForeL>L);
    Fy = -ForeY(ForeL>L);
    [sFx,sFy,sFf] = basiccmooth(Fx, Fy, Ff, d1);%using og filter 
    %% find floor
     [floorfit] = floorfind(sHHoofy,sFy,sHHoofy); %dots that hit the floor for horse 
    %% FSTO  
    [output(i).Hdutyfactor.avg, frameStrideLength, output(i).numcycles, strides, output(i).Hdutyfactor.std,output(i).Hstridelength.std, output(i).byEye]=fsto(sHHockx,sHHockf, directionfactor,spotcheck, 1,[0 0 0], 'HHockX FSTO'); 
    %% plot and abort if we didn't get any strides
    if sum(sum(strides))==0 || sum(sum((isnan(strides))))
          output(i).numcycles     = 0;
          horseReqOut(i).fileName = output(i).filname;
          horseReqOut(i).Direction = output(i).direction;
          horseReqOut(i).numberofcycles = output(i).numcycles;
          if spotcheck
              figure(1)
            plot(sHHooff, sHHoofx/10,'DisplayName','HindHoofX/10')
            plot(sHFetlockf,sHFetlockx/10,'DisplayName','HindFetlockX/10')
            plot(sHHockf,sHHockx/10,'DisplayName','HindHockX/10')
            saveas(fig1,[myfile,'_fulltrial.png']);
          end
          output(i).byEye='not enough strides';
          i=i+1;
          continue %go to next iteration of for loop because there aren't enough strides in this trial
    end
    %% stride x
    % need to find stridelength in the x data based on strides which was
    % found in f data
    strideIndex=[];
    for j=1:size(strides,1)
    [~,strideIndex(j,1)] = min(abs(sHHooff-strides(j,1)));
    [~,strideIndex(j,2)] = min(abs(sHHooff-strides(j,2)));
    end
    output(i).Hstridelength.avg = mean(abs(sHHoofx(strideIndex(:,1))-sHHoofx(strideIndex(:,2))));
    output(i).Hstridelength.std =  std(abs(sHHoofx(strideIndex(:,1))-sHHoofx(strideIndex(:,2))));
    stridesXstart=sHHoofx(unique(strideIndex));
    %% analysis of sided data
    %% Hind toe
     color=colors(1,:);
          [output(i).HHoof.x.avg, output(i).HHoof.f.avg, output(i).HHoof.x.std,output(i).HHoof.f.std] = avgforstride (sHHoofx,sHHooff, strides, stridesXstart,spotcheck,color,'HindHoofX'); 
        if spotcheck
            figure(1)
            plot(sHHooff, sHHoofx/10,'Color',color,'DisplayName','HindHoofX/10')
            if pausevalue
            pause
            end
        end
       color=colors(2,:);%rand(1,3);
       sHHoofy=sHHoofy- (floorfit(1)*(1:length(sHHoofy))+floorfit(2))'; 
      [~,output(i).HoofProminance.avg,~,output(i).HoofProminance.std] = pulloutYstuff(sHHoofy,sHHooff,spotcheck,color,'HindHoofY');%mean 1/2 peak width and mean prominance
      [output(i).HHoof.y.avg, ~,output(i).HHoof.y.std,~] =   avgforstride(sHHoofy,sHHooff, strides, [],spotcheck,color,'HindHoofY'); 
        if spotcheck & pausevalue
            pause
        end
        
    %% Hind midfoot    
    color=colors(3,:);%rand(1,3);
      [output(i).HFetlock.x.avg, output(i).HFetlock.f.avg,output(i).HFetlock.x.std,output(i).HFetlock.f.std] = avgforstride (sHFetlockx,sHFetlockf, strides, stridesXstart,spotcheck,color,'HindFetlockX');
        if spotcheck
            figure(1);hold on;
            plot(sHFetlockf,sHFetlockx/10,'Color',color,'DisplayName','HindFetlockX/10')
            if pausevalue
            pause
            end
        end
     color=colors(4,:);
     sHFetlocky=sHFetlocky-((floorfit(1)*(1:length(sHFetlocky))+floorfit(2)))';
      [output(i).HFetlock.y.avg, ~,output(i).HFetlock.y.std] = avgforstride (sHFetlocky,sHFetlockf, strides, [],spotcheck,color,'HindFetlockY'); 
        if spotcheck
            figure(1);hold on;
            plot(sHFetlockf,sHFetlocky,'Color',color,'DisplayName','HindFetlockY')
            if pausevalue
            pause
            end
        end
    %% Hind Hock    
    color=colors(5,:);%rand(1,3);
      [output(i).HHock.x.avg, output(i).HHock.f.avg,output(i).HHock.x.std,output(i).HHock.f.std] = avgforstride (sHHockx,sHHockf, strides, stridesXstart,spotcheck,color,'HindHockX');
        if spotcheck
            figure(1);
            %plot(frame(HindHeelL>L),HHx,'DisplayName','HindHeelX')
            plot(sHHockf,sHHockx/10,'Color',color,'DisplayName','HindHockX/10')
        end
        color=colors(6,:);%rand(1,3);%y is inverted because origin is top left
      sHHocky=sHHocky-((floorfit(1)*(1:length(sHHocky))+floorfit(2)))';
      [~,output(i).HockProminance.avg,~,output(i).HockProminance.std] = pulloutYstuff(sHHocky,sHHockf,spotcheck,color,'HindHockY');%mean 1/2 peak width and mean prominance
      [output(i).HHock.y.avg, ~,output(i).HHock.y.std] = avgforstride (sHHocky,sHHockf, strides, [],spotcheck,color,'HindHockY');
        if spotcheck & pausevalue
            pause
        end
        %% hind heel velocity at footstrike
        %strides is in frames. We want the borderline instantaneous
        %velocity, so let's do it over a second,i think it's like 24 fps
        %maybe lol
        %velocity in pixels/frame
        %distance in pixels for each frame lol
        vHHoofx=gradient(sHHoofx);
        vHHoofy=gradient(sHHoofy);
        HHoofdistance = sqrt( (vHHoofx).^2 + (vHHoofy).^2 );
        strikes = unique(strides);%strides is in frames, need to find HH index that matches
        for j=1:length(strikes)
            [~,strikes(j)] = min(abs(sHHooff-strikes(j)));
        end
        vHHoof=NaN(size(strikes));
        for k=1:length(strikes)
        winstart = strikes(k)-20;winstart(winstart<1)=1;
        winend   = strikes(k)+ 4;winend(winend>length(HHoofdistance))=length(HHoofdistance);           
        vHHoof(k) = median(HHoofdistance(winstart:winend));%in pixels per frame
        end
        vHHoofstd=std(vHHoof);
        vHHoof = mean(vHHoof);
        %% checking. Comment out if you don't want to do this rn.
%         if spotcheck
%             output(i).byEye = input('g for good, e for need to edit, n for bad','s');
%         else
%             output(i).byEye = 'unseen'; 
%         end
    %% fore    
    Fx = ForeX(ForeL>L);Ff=frame(ForeL>L);color=colors(7,:);%rand(1,3);
    Fy= -ForeY(ForeL>L);Fy=Fy-((floorfit(1)*(1:length(Fy))+floorfit(2)))';
    [sFx,sFy,sFf] = basiccmooth(Fx, Fy, Ff, d2);%using d2 filter    
      [output(i).FHoof.y.avg, ~,output(i).FHoof.y.std] = avgforstride (sFy,sFf, strides, [],spotcheck,color,'FHoofY');
      [output(i).FHoof.x.avg, output(i).FHoof.f.avg,output(i).FHoof.x.std,output(i).FHoof.f.std] = avgforstride(sFx,sFf, strides, stridesXstart,spotcheck,color,'FHoofX');
     color=colors(8,:);%rand(1,3);
      [output(i).FHoof.y.avg, ~,output(i).FHoof.y.std] = avgforstride(sFy,sFf, strides, [],spotcheck,color,'FHoofY'); 
        if spotcheck
            figure(1);hold on; 
            plot(sFf,sFy,'Color',color,'DisplayName','ForeY');
            if pausevalue
            pause
            end
        end
      %% forehoof velocity at footstrike
      try
      %find forehoof footstrikes
      [~, ~, ~, Fstrides, ~,~, ~]=fsto(sFx,sFf, directionfactor,0, 1,[0 0 0], 'F FSTO'); 
      
        %velocity in pixels/frame
        %distance in pixels for each frame lol
        vFx=gradient(sFx);
        vFy=gradient(sFy);
        Fdistance = sqrt( (vFx).^2 + (vFy).^2 );
        strikes = unique(Fstrides);%strides is in frames, need to find HH index that matches
        for j=1:length(strikes)
            [~,strikes(j)] = min(abs(sHHockf-strikes(j)));
        end
        vF=NaN(size(strikes));
        for k=1:length(strikes)
        winstart = strikes(k)-20;winstart(winstart<1)=1;
        winend   = strikes(k)+ 4;winend(winend>length(Fdistance))=length(Fdistance);           
        vF(k) = median(Fdistance(winstart:winend));%in pixels per frame
        end
        vFstd=std(vF);
        vF = mean(vF);
      catch 
          output(i).byEye=append(output(i).byEye,'issue with vF');
          vFstd=NaN;
          vF = NaN;
      end
    %% hip to hind toe/hoof distance          
        HipHoof = sqrt( ((HindHoofY-hipy).^2)+((HindHoofX-hipx).^2) ); color=colors(9,:);%rand(1,3);%hip to hind hoof length
        HipHoof =  HipHoof(HindHoofL>L & hipl>L);        HipHooff =frame(HindHoofL>L & hipl>L);
        [sHipHoof,~,sHipHooff] = basiccmooth(HipHoof, HipHoof,HipHooff, d1);%using og filter   
      [output(i).HipHoof.y.avg, output(i).HipHoof.f.avg,output(i).HipHoof.y.std,output(i).HipHoof.f.std] = avgforstride(sHipHoof,sHipHooff, strides, [], spotcheck,color,'hipHoofLength');
        if spotcheck
            figure(1);hold on;
            %plot(HipHooff,HipHoof,'DisplayName','TailBasetoMidFootLength');
            plot(sHipHooff,sHipHoof,'Color',color,'DisplayName','HipHoofLength')
            if pausevalue
            pause
            end
        end
    %% withers to fore toe/hoof distance          
        WithersFore = sqrt( ((ForeY-withersy).^2)+((ForeX-withersx).^2) ); color=colors(10,:);%rand(1,3);%hip to hind hoof length
        WithersFore =  WithersFore(ForeL>L & withersl>L);        WithersForef =frame(ForeL>L & withersl>L);
        [sWithersFore,~,sWithersForef] = basiccmooth(WithersFore, WithersFore,WithersForef, d1);%using og filter   
      [output(i).WithersFore.y.avg, output(i).WithersFore.f.avg,output(i).WithersFore.y.std,output(i).WithersFore.f.std] = avgforstride(sWithersFore,sWithersForef, strides, [], spotcheck,color,'WithersForeLength');
        if spotcheck
            figure(1);hold on;
            %plot(WithersForef,WithersFore,'DisplayName','TailBasetoMidFootLength');
            plot(sWithersForef,sWithersFore,'Color',color,'DisplayName','WithersForeLength')
            if pausevalue
            pause
            end
        end

     %% shank length (for normalizing)   
     shankLength = sqrt( ((HindFetlockY-HindHockY).^2)+((HindFetlockX-HindHockX).^2) ); color=colors(11,:);%rand(1,3);%shank length for normalizing
        shankLength =  shankLength(HindFetlockL>L & HindHockL>L);        shankLengthf =frame(HindFetlockL>L & HindHockL>L);
        [sshankLength,~,sshankLengthf] = basiccmooth(shankLength, shankLength,shankLengthf, d1);%using og filter   
      [output(i).shankLength.y.avg, output(i).shankLength.f.avg,output(i).shankLength.y.std,output(i).shankLength.f.std] = avgforstride(sshankLength,sshankLengthf, strides, 'y', spotcheck,color,'shankLengtLength');
        output(i).shankLength.avg = mean(output(i).shankLength.y.avg);
      if spotcheck
            figure(1);hold on;
            plot(sshankLengthf,sshankLength,'Color',color,'DisplayName','shankLength')
            if pausevalue
            pause
            end
      end
     %% head length (for normalizing)             
             headLength = sqrt( ((polly-nosey).^2)+((pollx-nosex).^2) ); color=colors(12,:);%rand(1,3);%headLength for normalizing
        headLength =  headLength(polll>L & nosel>L);        headLengthf =frame(polll>L & nosel>L);
        [sheadLength,~,sheadLengthf] = basiccmooth(headLength, headLength,headLengthf, d1);%using og filter   
      [output(i).headLength.y.avg, output(i).headLength.f.avg,output(i).headLength.y.std,output(i).headLength.f.std] = avgforstride(sheadLength,sheadLengthf, strides, 'y', spotcheck,color,'headLength');
        output(i).headLength.avg = mean(output(i).headLength.y.avg);
      if spotcheck
            figure(1);hold on;
            %plot(TBMFf,TBMF,'DisplayName','TailBasetoMidFootLength');
            plot(sheadLengthf,sheadLength,'Color',color,'DisplayName','headLength')
            if pausevalue
            pause
            end
      end  
      
    %% HHoof-HFetlock-HHock angle   
        color=colors(13,:);%rand(1,3);
      [HHoof_HFetlock_HHock, goodframes] = findangle(HindHoofX,HindHoofY,HindHoofL,HindFetlockX,HindFetlockY,HindFetlockL, HindHockX,HindHockY,HindHockL,frame,L,spotcheck,color,'HHoof-Hfetlock-HHock angle'); %2nd is where the angle is
        [output(i).HHoof_HFetlock_HHock.y.avg, output(i).HHoof_HFetlock_HHock.f.avg,output(i).HHoof_HFetlock_HHock.y.std,output(i).HHoof_HFetlock_HHock.f.std] = avgforstride(HHoof_HFetlock_HHock',goodframes, strides, 'y',spotcheck,color,'HHoof-HFetlock-HHock angle');
      if spotcheck
            figure(1);hold on;
            plot(goodframes,HHoof_HFetlock_HHock,'Color',color,'DisplayName','HHoof-HFetlock-HHock')
            if pausevalue
            pause
            end
      end  
%     %% HT-HM-TB angle
%         color=colors(11,:);%rand(1,3);
%       [angle, goodframes] = findangle(HindHoofX,HindHoofY,HindHoofL,HindFetlockX,HindFetlockY,HindFetlockL, TailBasex,TailBasey,TailBasel,frame,L,spotcheck,color,'toe-midfoot-tailbase angle'); %2nd is where the angle is
%         [output(i).HHoof_HFetlock_butt.y.avg, output(i).HHoof_HFetlock_butt.f.avg,output(i).HHoof_HFetlock_butt.y.std,output(i).HHoof_HFetlock_butt.f.std] = avgforstride(angle',goodframes, strides, 'y',spotcheck,color,'toe-midfoot-tailbase angle');
%         if spotcheck & pausevalue
%             pause
%         end
%     %% HT-TB-B angle
%         color=colors(12,:);%rand(1,3);
%       [angle, goodframes] = findangle(HindFetlockX,HindFetlockY,HindFetlockL, TailBasex,TailBasey,TailBasel,withersx, withersy, withersl, frame,L,spotcheck,color,'toe-tailbase-back angle'); %2nd is where the angle is
%         [output(i).HFetlock_butt_withers.y.avg, output(i).HFetlock_butt_withers.f.avg,output(i).HFetlock_butt_withers.y.std,output(i).HFetlock_butt_withers.f.std] = avgforstride(angle',goodframes, strides, 'y',spotcheck,color,'toe-tailbase-back angle');
%         if spotcheck & pausevalue
%             pause
%         end
    %% angle of hind virtual limb
        color=colors(14,:);%rand(1,3);
      [angle, goodframes] = findangle(HindHoofX,HindHoofY,HindHoofL, hipx,hipy,hipl,hipx, HindHoofY, HindHoofL, frame,L,spotcheck,color,'HHoof-hip angle'); %2nd is where the angle is
        [output(i).HHoof_hip.y.avg, output(i).HHoof_hip.f.avg,output(i).HHoof_hip.y.std,output(i).HHoof_hip.f.std] = avgforstride(angle',goodframes, strides, [],spotcheck,color,'HHoof-hip angle');
      if spotcheck
            figure(1);hold on;
            plot(goodframes,angle,'Color',color,'DisplayName','HHoof-hip')
            if pausevalue
            pause
            end
      end  
    %% angle of fore virtual limb
        color=colors(15,:);%rand(1,3);
      [angle, goodframes] = findangle(ForeX,ForeY,ForeL, withersx,withersy,withersl,withersx, ForeY, ForeL, frame,L,spotcheck,color,'FHoof-withers angle'); %2nd is where the angle is
        [output(i).FHoof_withers.y.avg, output(i).FHoof_withers.f.avg,output(i).FHoof_withers.y.std,output(i).FHoof_withers.f.std] = avgforstride(angle',goodframes, strides, [],spotcheck,color,'FHoof-withers angle');
      if spotcheck
            figure(1);hold on;
            plot(goodframes,angle,'Color',color,'DisplayName','FHoof-withers')
            if pausevalue
            pause
            end
      end  
          
    %% nonsided
    %% nose 
    Nf = frame(nosel>L);color=colors(16,:);%rand(1,3);%Nx was defined earlier
    Ny= -nosey(nosel>L);Ny=Ny-((floorfit(1)*(1:length(Ny))+floorfit(2)))';
       [sNx,sNy, sNf] = basiccmooth(Nx, Ny,Nf, d1);%using og filter
     [output(i).N.x.avg, output(i).N.f.avg,output(i).N.x.std,output(i).N.f.std] = avgforstride(sNx,sNf, strides, stridesXstart,spotcheck,color,'NoseX');
       if spotcheck
            figure(1);hold on;
            %plot(sNf,sNx/10,'Color',color,'DisplayName','NoseX/10')
       end
     color=colors(16,:)+.06;%rand(1,3);%height of nose relative to floor
      [output(i).N.y.avg, ~,output(i).N.y.std,~] = avgforstride(sNy,sNf, strides, [],spotcheck,color,'NoseY'); 
        if spotcheck
            figure(1);hold on;
            plot(sNf,sNy,'Color',color,'DisplayName','NoseY')
            if pausevalue
            pause
            end
        end
        
    %% back
    withersX= withersx(withersl>L); withersF=frame(withersl>L); color=colors(17,:);%rand(1,3);
    withersY= -withersy(withersl>L); withersY=withersY-((floorfit(1)*(1:length(withersY))+floorfit(2)))';
        [swithersx,swithersy, swithersf] = basiccmooth(withersX, withersY,withersF, d1);%using og filter
       [output(i).withers.x.avg, output(i).withers.f.avg,output(i).withers.x.std,output(i).withers.f.std] = avgforstride(swithersx,swithersf, strides, stridesXstart,spotcheck,color,'withersX');
        if spotcheck
            figure(1);hold on;
            %plot(sBf,sBx/10, 'Color',color,'DisplayName','BackX/10')
        end
    color=colors(17,:)+.05;%height of back relative to floor already defined
       [output(i).withers.y.avg, ~,output(i).withers.y.std,~] = avgforstride(swithersy,swithersf, strides, [],spotcheck,color,'withersY'); 
        if spotcheck
            figure(1);hold on;
            plot(swithersf,swithersy, 'Color',color,'DisplayName','withersY')
            if pausevalue
            pause
            end
        end
     %% backslope  
    backslope = (-(withersy-TailBasey)./(withersx-TailBasex));  color=colors(17,:);%(y-y/x-x) %y is negative because the origin is in the top left
        backslope = backslope(withersl>L & TailBasel>L); bsf =frame(withersl>L & TailBasel>L);
        [sbackslope,~,sbsf] = basiccmooth(backslope,backslope, bsf, d1);
        backslope = -directionfactor*(sbackslope);% needed.
        backangle = atand(sbackslope);
      [nBackA, nBAf,nBAstd] = avgforstride(backangle,sbsf, strides, 'y',0,color,'BackAngle'); 
        if spotcheck == 1
            figure(1); hold on;
            %plot(bsf,-directionfactor*backslope*10,'DisplayName','backslope*10');
            %plot(sbsf,backangle,'Color',color,'DisplayName','backangle');
            if pausevalue
            pause
            end
        end
        
    %velocity
        velocity =  abs(gradient(output(i).withers.x.avg)) ./ (gradient(output(i).withers.f.avg));
        output(i).velocity.avg = abs(mean(velocity));%in pixels per frame
        output(i).velocity.std = std(velocity);%in pixels per frame

    if spotcheck
     saveas(fig1,[myfile,'_fulltrial.png']);
     saveas(fig2,[myfile,'_avgstride.png']);
    end
    
    %% adding to the subselection
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
    
    horseReqOut(i).MaxHHoof_HFetlock_HHock = max(output(i).HHoof_HFetlock_HHock.y.avg);
    horseReqOut(i).MinHHoof_HFetlock_HHock = min(output(i).HHoof_HFetlock_HHock.y.avg);
    horseReqOut(i).HHoof_HFetlock_HHockStd = std(output(i).HHoof_HFetlock_HHock.y.avg);
    
    horseReqOut(i).HHoofVelocityAtFootstrikeAvg = vHHoof;
    horseReqOut(i).HHoofVelocityAtFootstrikeStd = vHHoofstd;
    horseReqOut(i).FHoofVelocityAtFootstrikeAvg = vF;
    horseReqOut(i).FHoofVelocityAtFootstrikeStd = vFstd;
    
    horseReqOut(i).HHoofProminanceAvg = output(i).HoofProminance.avg;
    horseReqOut(i).HHoofProminanceStd = output(i).HoofProminance.std;
    
    horseReqOut(i).MinHHoofHipAngle = min(output(i).HHoof_hip.y.avg);
    horseReqOut(i).MaxHHoofHipAngle = max(output(i).HHoof_hip.y.avg);
    horseReqOut(i).MinFHoof_withersAngle = min(output(i).FHoof_withers.y.avg);
    horseReqOut(i).MaxFHoof_withersAngle = max(output(i).FHoof_withers.y.avg);
    
    horseReqOut(i).MinHHoofHipLength = min(output(i).HipHoof.y.avg);
    horseReqOut(i).MaxHHoofHipLength = max(output(i).HipHoof.y.avg);
    horseReqOut(i).MinWithersForeLength = min(output(i).WithersFore.y.avg);
    horseReqOut(i).MaxWithersForeLength = max(output(i).WithersFore.y.avg);

    end

end
save('output.mat','output');
writetable(struct2table(horseReqOut),'SelectedOutputs.xlsx');
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
     %angle3=angle3*180/pi; %for converting to degrees
     if spotcheck==1
         figure(1); hold on;
         %plot(goodframes,angle3*10,'Color',color,'DisplayName',[name,' *10']);
     end
end
function [P] = floorfind(HTy,HMy,HHy); 
%this code was labeled for rats, where all 3 of these should touch the floor. I do it with different inputs in horses.
datas = {HTy,HMy,HHy};
for i =1:3
    data = datas{i};
    [floory(1,i),floorx(1,i)]=min(data(1:end/3));
    [floory(2,i),floorx(2,i)]=min(data(end/3+1:2*end/3));
    [floory(3,i),floorx(3,i)]=min(data(2*end/3+1:end));
    floorx(2,i)=floorx(2,i)+length(data(1:end/3));
    floorx(3,i)=floorx(3,i)+length(data(1:2*end/3));
end
floorx=reshape(floorx,9,1);
floory=reshape(floory,9,1);
P = polyfit(floorx,floory,1);
%floorvec = P(1)*(1:length(data))+P(2);
end
function [mw,mp,stdw,stdp] = pulloutYstuff(data,frames,spotcheck,color,name)
sdata=data;
[pks,locs,w,p] = findpeaks(sdata,frames, 'MinPeakProminence',4,'MinPeakDistance',25,'Annotate','extents');

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
function [dutyfactor, stridelength, numcycles, strides, dutyfactorStd,stridelengthStd, byEye]=fsto(data,frames, directionfactor,spotcheck, graphfactor,color, name)
%find derivative
dxdf = gradient(data(:));% ./ gradient(frames(:));
[dxdf] = rmoutliers([dxdf,frames],'movmedian',25);
rframes=dxdf(:,2);
dxdf=dxdf(:,1);
%find where the derivative chills out
% find peaks
[pks,locs,w,p] = findpeaks(abs(dxdf), 'MinPeakProminence',1,'MinPeakDistance',25,'Annotate','extents');
threshs=[pks-.75*p]; %tunable
for i=1:length(threshs)%find the x values
    threshi(i,1)=find(abs(dxdf)==pks(i));
end
P = polyfit(threshi,threshs,1); %fit a line through the threshold values to make a little threshold line
threshline=((P(1)*(1:length(dxdf))+P(2)))';
threshline=median(threshs)*ones(size(dxdf));
%define stride/stance based off this threshold
stance1=NaN(size(dxdf));
stance1(abs(dxdf)<=threshline)=1;
stance1(abs(dxdf)>threshline)=0;%stance is 1
%let's filter stance1 a bit though because we only want to count stance if
%it hangs out in stance for a while
[stance1] = movmedian(stance1,10);%in frames - tunable
stance1(stance1==.5)=0; %the movmedian makes there be .5 values when it goes from swing to stance or vice versa. I am assigning those to be stride because it kind of looks like they should be. Tunable, but only 1 frame
%find footstrike
[pks,toestrike]= findpeaks([stance1;0],[rframes;rframes(end)+1],'MinPeakDistance',25,'MinPeakWidth',10);% frames in stance - tunable
    %I added a point at 0 at the end because if I don't it doesn't see the
    %last stance time as a peak if it isn't followed by a trough.
%find toeoff
[pks2,toeoff]= findpeaks(-[stance1;0],[rframes;rframes(end)+1],'MinPeakDistance',25,'MinPeakWidth',10);% frames in swing - tunable

if length(toestrike)<=1 %if there are not footstrikes, abort the trial
    toestrike=[0 0];pks=[0 0];
    dutyfactor=nan; stridelength=nan;strides=nan;
    numcycles=nan; datasnew=nan;percentfsnew=nan;
    dutyfactorStd=nan;stridelengthStd=nan;datasnewstd=nan;percentfsnewstd=nan; byEye = 'toestrike<=1';
end

%set up strides matrix 
strides = [toestrike(1:end-1),toestrike(2:end)];
stridelengthF= strides(:,2)-strides(:,1);
%remove weird strides - determines which strides you will count in average.
%decreases the count tho.
%[stridelengthF,stridelengthTF] = rmoutliers(stridelengthF,'median'); %remove outliers in sliding window
%strides=strides(~stridelengthTF,:);

%find dutyfactor
dutyfactor=[];
stridelength=[];
for j=1:size(strides,1)
    stridestart=strides(j,1); %in frames
    strideend  =strides(j,2);
    strideToeOff=toeoff(toeoff>stridestart); %find toeoff after the toestrike
    ToeOff(j) = strideToeOff(1); %we just want the first one after toestrike
    %temporal
    timestance =ToeOff(j)-stridestart; %in frames
    dutyfactor(j) = timestance/(strideend-stridestart); %duty factor
    %spatial
    stridelength(j) =abs(data(frames==stridestart)-data(frames==strideend)); 
end

%plotting
val = 0;%conditional value set up for editing
if spotcheck
    offsetforgraphing=rand(1);%I offset the stride/stance so that I can look at multiple stride/stance at once and they don't overlap
    while val ==0
        figure(1);hold on;
        %plot(frames,   data/10, 'Color',color,'DisplayName',[name, '/10']);
        plot(rframes, abs(dxdf), 'Color',color,'DisplayName',['|derivative|',name]);
        %plot(rframes,threshline*10,'DisplayName','threshold line for stance/swing*10')
        plot(rframes, (stance1-.1)*100+offsetforgraphing,'.','Color',color*(2.5/3),'DisplayName',[name,' stance']);
        plot([toestrike,toestrike]',[(pks-1.1)*100-offsetforgraphing,(pks-.1)+100+offsetforgraphing]','Color',color*(2.2/3),'HandleVisibility','off'); 
            plot(0,0,'Color',color,'DisplayName',[name,' toestrike']); %just for the legend info
        plot(strides',[(ones(size(stridelengthF))-1.1)*100-offsetforgraphing*2,ones(size(stridelengthF))*100+offsetforgraphing*2]','Color',color*(2.2/3),'HandleVisibility','off');%toeoff 
        plot([ToeOff;ToeOff],[(ones(length(ToeOff),1)-1.1)*100-offsetforgraphing,(ones(length(ToeOff),1)-.1)+50+offsetforgraphing]','Color',color*(2.2/3),'HandleVisibility','off');%toeoff 

    byEye = '-'; %input('Are the strides accurate? y, n, or e for edit.','s');
    if byEye == 'e'
        strides = [toestrike(1:end-1),toestrike(2:end)]
        stridesToUse = input('choose stride indecies to use in []');
        strides = strides(stridesToUse, :);
        stridelengthF= strides(:,2)-strides(:,1);
        offsetforgraphing = offsetforgraphing+1;
    else val =1;
    end
    end
else 
         byEye = '-';
end

numcycles = size(strides,1);
dutyfactorStd   = std(dutyfactor);    dutyfactor=mean(dutyfactor);    
stridelengthStd = std(stridelength);stridelength=mean(stridelength);
[datasnew, percentfsnew, datasnewstd,percentfsnewstd] = avgforstride(stance1*100,frames,strides, [], spotcheck,color*(1/3),[name,'Stance1 Swing0']);
end
function [avnwinstrides, avnwinfs, avwinstridesSTDEV,avwinfsSTDEV] = avgforstride(data,f2, strides, stridesXstart, spotcheck,color,name)
    %minlength = inf;
    datas={};
    winsize = 25;%size in percentage of stride
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
        if length(stridesXstart)>1
        mystride = mystride-stridesXstart(j);%if this is x data, i want to normalize to the begining of the stride so that's the minimum
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
%     if exist('winstrides', 'var')==0
%         pause
%     end
    % msg=['testing sizes line 420, should be true: ',num2str(size(winstrides,2)==100/winsize)] %troubleshooting
    %initialize some things
    nwinstrides=cell(size(winstrides,1),1);
    nwinfs=cell(size(winstrides,1),1);
    weights=cell(size(winstrides,1),1);
    for m=1:size(winstrides,2) %loop thru the number of bins that exist. should = 100/winsize
        wins=winstrides(:,m);%select only bin m for all strides
        minps = min(cellfun('size',wins,1));
        if minps<=0
            msg=['need to increase winsize? winsize=',num2str(winsize)]
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
                weights{n}     = [    weights{n},0.5*ones(size(nwinnm))];%don't care abt these points
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