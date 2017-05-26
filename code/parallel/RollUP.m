%% rolling calculation per week
% addpath C:\gurobi702\win64\matlab;
% warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
RollNum=364;         %%滚动次数
RollStart=(1:24:8737)';       %%滚动周期起始时间
Iter=zeros(RollNum,1);        %%迭代次数
%% full period input data
in_full = load('input_data.mat', 'in');
%%------------------------ initialization ---------------------------------
in_full = in_full.in;
in_area = in_full.area;
%%------------ system data
A=in_full.A;               %% number of areas
T=8736;                   %% time horizons
TD=0;                     %% number of days
%%------------- area data
for a=1:A
    in_area(a).T=0;
    in_area(a).TD=0;
%     in_area(a).Onoff_t0=zeros(1,in_area(a).Nunit);       %% initial status at t=0
%     in_area(a).Pthermal_t0=zeros(1,in_area(a).Nunit);    %% initial output at t=0
%     in_area(a).On_t0=zeros(1,in_area(a).Nunit);          %% length of time unit g has to be on at the beginning
%     in_area(a).Off_t0=zeros(1,in_area(a).Nunit);         %% length of time unit g has to be off at the beginning
    in_area(a).Demand=[];        %% demand
    in_area(a).Windmax=[];      %% theory output of wind power
    in_area(a).PVmax  = [];      %% theory output of PV
    in_area(a).Ftie0=[];          %% fixed power flow
    in_area(a).Etie =[];          %% exchage energy each day
    in_area(a).ReserveUp=[];      %% up reserve
    in_area(a).ReserveDn=[];      %% down reserve
end
%%-------------- results
Pwind_F=zeros(T,A);    %% output of wind power 
Ppv_F  =zeros(T,A);      %% output of PV 
Pthermal_F=cell(1,A);          %% output of thermal unit
onoff_F=cell(1,A);           %% on_off status;
startup_F=cell(1,A);              %% start up indicator
shutdown_F=cell(1,A);            %% shut down indicator
Ftie_F=cell(1,A);

%% roll up
% pool=parpool;
tic;
for roll=1:RollNum
    %%input the rth rolling period data
    parfor a=1:A
        in_area(a).T=RollStart(roll+1)-RollStart(roll);
        if roll==1
%             in_area(a).Onoff_t0=in_full.area(a).Onoff_t0;       
%             in_area(a).Pthermal_t0=in_full.area(a).Pthermal_t0;   
%             in_area(a).On_t0=in_full.area(a).On_t0;         
%             in_area(a).Off_t0=in_full.area(a).Off_t0;       
        else
            in_area(a).Onoff_t0    = out.area(a).onoff(in_area(a).T,:);      
            in_area(a).Pthermal_t0 = out.area(a).Pthermal(in_area(a).T);    
            [in_area(a).On_t0,in_area(a).Off_t0] = getOnoff_t0(out.area(a).onoff,in_area(a).Minup,in_area(a).Mindown);       
        end
        in_area(a).Demand    = in_full.area(a).Demand(RollStart(roll):RollStart(roll+1)-1,:);        
        in_area(a).Windmax   = in_full.area(a).Windmax(RollStart(roll):RollStart(roll+1)-1,:); 
        in_area(a).PVmax     = in_full.area(a).PVmax(RollStart(roll):RollStart(roll+1)-1,:);  
        in_area(a).ReserveUp = in_full.area(a).ReserveUp(RollStart(roll):RollStart(roll+1)-1,:);      %% up reserve
        in_area(a).ReserveDn = in_full.area(a).ReserveDn(RollStart(roll):RollStart(roll+1)-1,:);      %% dowen reserve
    end

    %%solution
    [out,hist]=multi_area_accommodation(in_area,A);
    %%results
    for a=1:A
        Pwind_F(RollStart(roll):RollStart(roll+1)-1,a)       = out.area(a).Pwind;    %% output of wind power 
        Ppv_F(RollStart(roll):RollStart(roll+1)-1,a)         = out.area(a).Ppv;      %% output of PV 
        Pthermal_F{a}(RollStart(roll):RollStart(roll+1)-1,:) = out.area(a).Pthermal;
        onoff_F{a}(RollStart(roll):RollStart(roll+1)-1,:)    = out.area(a).onoff;
        startup_F{a}(RollStart(roll):RollStart(roll+1)-1,:)  = out.area(a).startup;
        shutdown_F{a}(RollStart(roll):RollStart(roll+1)-1,:) = out.area(a).shutdown;
        Ftie_F{a}(RollStart(roll):RollStart(roll+1)-1,:)     = out.area(a).Ftie;
    end
    Iter(roll)=hist.iter;
    roll
    toc;
end
delete(pool);
%% save resluts
save results.mat Pwind_F Ppv_F Pthermal_F onoff_F startup_F shutdown_F Ftie_F;
%% display results
% Endh=24*3*10;
% for a=1:A
%     %%------------------------ thermal unit -------------------------------
%     figure;
%     stairs(Pthermal_F{a}(1:Endh,:));
%     title(['thermal unit output in area' num2str(a)]);
%     %%------------------------------- wind ------------------------------------
%     figure;
%     hold on;
%     stairs(in_full.area(a).Windmax(1:Endh));
%     stairs(Pwind_F(1:Endh,a));
%     title(['wind power in area' num2str(a)]);
%     legend('maximum','actual');
%     hold off;
%     %%-------------------------------- PV -------------------------------------
%     figure;
%     hold on;
%     stairs(in_full.area(a).PVmax(1:Endh));
%     stairs(Ppv_F(1:Endh,a));
%     title(['PV generation in area' num2str(a)]);
%     legend('maximum','actual');
%     hold off;  
% end
% %%------------------------------- tie lines -------------------------------
% for a=1:A
%     for b=a+1:A
%         for la=1:in_full.area(a).Ntie
%             for lb=1:in_full.area(b).Ntie
%                 if (in_full.area(a).Tieline(la,1)==b)&&(in_full.area(b).Tieline(lb,1)==a)
%                     figure;
%                     hold on;
%                     stairs(Ftie_F{a}(1:Endh,la));
%                     stairs(Ftie_F{b}(1:Endh,lb));
%                     legend(['Tie ' num2str(a) '-' num2str(b)],['Tie ' num2str(b) '-' num2str(a)]); 
%                     title('tie line power flow');
%                     hold off;
%                 end
%             end
%         end
%     end
% end