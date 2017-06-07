%% rolling calculation per week
% addpath C:\gurobi702\win64\matlab;
% warning( 'off', 'MATLAB:lang:badlyScopedReturnValue' );
RollNum=364;         %%滚动次数
RollStart=(1:24:8737)';       %%滚动周期起始时间
Iter=zeros(RollNum,1);        %%迭代次数
%% full period input data
load('input_data.mat');
%%------------------------ initialization ---------------------------------
Tfull   = in.T;
TDfull  = in.TD;
A       = in.A;
in_full = in.area;
in_roll = in_full;
parfor a=1:A
    %%------------- area data
    in_roll(a).T=0;
    in_roll(a).TD=0;
%     in_roll(a).Onoff_t0=zeros(1,in_roll(a).Nunit);       %% initial status at t=0
%     in_roll(a).Pthermal_t0=zeros(1,in_roll(a).Nunit);    %% initial output at t=0
%     in_roll(a).On_t0=zeros(1,in_roll(a).Nunit);          %% length of time unit g has to be on at the beginning
%     in_roll(a).Off_t0=zeros(1,in_roll(a).Nunit);         %% length of time unit g has to be off at the beginning
    in_roll(a).Demand=[];        %% demand
    in_roll(a).Windmax=[];      %% theory output of wind power
    in_roll(a).PVmax  = [];      %% theory output of PV
    in_roll(a).Ftie0=[];          %% fixed power flow
    in_roll(a).Etie =[];          %% exchage energy each day
    in_roll(a).ReserveUp=[];      %% up reserve
    in_roll(a).ReserveDn=[];      %% down reserve
end
parfor a=1:A
    %%-------------- results
    out_full(a).Pwind    = zeros(Tfull,1);                    %% output of wind power 
    out_full(a).Ppv      = zeros(Tfull,1);                    %% output of PV 
    out_full(a).Pthermal = zeros(Tfull,in_roll(a).Nunit);     %% output of thermal unit
    out_full(a).onoff    = zeros(Tfull,in_roll(a).Nunit);     %% on_off status;
    out_full(a).startup  = zeros(Tfull,in_roll(a).Nunit);     %% start up indicator
    out_full(a).shutdown = zeros(Tfull,in_roll(a).Nunit);     %% shut down indicator
    out_full(a).Ftie     = zeros(Tfull,in_roll(a).Ntie);
end
%% roll up
tic;
for roll=1:RollNum
    %%input the rth rolling period data
    tRoll = RollStart(roll):RollStart(roll+1)-1;
    parfor a=1:A
        in_roll(a).T=length(tRoll);
        if roll==1
%             in_area(a).Onoff_t0=in_full(a).Onoff_t0;       
%             in_area(a).Pthermal_t0=in_full(a).Pthermal_t0;   
%             in_area(a).On_t0=in_full(a).On_t0;         
%             in_area(a).Off_t0=in_full(a).Off_t0;       
        else
            in_roll(a).Onoff_t0    = out_full(a).onoff(tRoll(1)-1,:);      
            in_roll(a).Pthermal_t0 = out_full(a).Pthermal(tRoll(1)-1,:);    
            [in_roll(a).On_t0,in_roll(a).Off_t0] = getOnoff_t0(out_full(a).onoff,in_roll(a).Minup,in_roll(a).Mindown);       
        end
        in_roll(a).Demand    = in_full(a).Demand(tRoll,:);        
        in_roll(a).Windmax   = in_full(a).Windmax(tRoll,:); 
        in_roll(a).PVmax     = in_full(a).PVmax(tRoll,:);  
        in_roll(a).ReserveUp = in_full(a).ReserveUp(tRoll,:);      %% up reserve
        in_roll(a).ReserveDn = in_full(a).ReserveDn(tRoll,:);      %% dowen reserve
    end

    %%solution
    [out_roll,hist]=multi_area_accommodation(in_roll,A);
    %%results
    parfor a=1:A
        out_full(a).Pwind(tRoll)      = out_roll(a).Pwind;    
        out_full(a).Ppv(tRoll)        = out_roll(a).Ppv;     
        out_full(a).Pthermal(tRoll,:) = out_roll(a).Pthermal;
        out_full(a).onoff(tRoll,:)    = out_roll(a).onoff;
        out_full(a).startup(tRoll,:)  = out_roll(a).startup;
        out_full(a).shutdown(tRoll,:) = out_roll(a).shutdown;
        out_full(a).Ftie(tRoll,:)     = out_roll(a).Ftie;
    end
    Iter(roll)=hist.iter;
    roll
    toc;
end
%% save resluts
save results.mat A Tfull TDfull in_full out_full;
