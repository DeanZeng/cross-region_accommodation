%input data
clear all;
%% system data
sysFile='data\sys.xlsx';
in.A=xlsread(sysFile,'B1:B1');               %% number of areas
in.T=xlsread(sysFile,'B2:B2');               %% time horizons
in.TD=0;                                     %% number of days
A=in.A; T=in.T; TD=in.TD;
%% area data
areaFile{1}='data\area_1.xlsx';
areaFile{2}='data\area_2.xlsx';
Nunit = [53,19];            %% number of units
Ntie  = [1,1];              %% number of tie lines
%%------------------------ initialization ---------------------------------
for a=1:A
    in.area(a).Nunit = Nunit(a);
    in.area(a).Ntie  = Ntie(a);
    in.area(a).Pmax=zeros(1,Nunit(a));           %% unit maximum output
    in.area(a).Pmin=zeros(1,Nunit(a));           %% unit minimum output
    in.area(a).Rampup=zeros(1,Nunit(a));         %% unit ramping up rates
    in.area(a).Rampdown=zeros(1,Nunit(a));       %% unit ramping down rates
    in.area(a).Minup=zeros(1,Nunit(a));          %% unit minimun up time
    in.area(a).Mindown=zeros(1,Nunit(a));        %% unit minimum dowm time
    in.area(a).Onoff_t0=zeros(1,Nunit(a));       %% initial status at t=0
    in.area(a).Pthermal_t0=zeros(1,Nunit(a));    %% initial output at t=0
    in.area(a).On_t0=zeros(1,Nunit(a));          %% length of time unit g has to be on at the beginning
    in.area(a).Off_t0=zeros(1,Nunit(a));         %% length of time unit g has to be off at the beginning
    in.area(a).Demand=zeros(T,1);        %% demand
    in.area(a).Windmax= zeros(T,1);      %% theory output of wind power
    in.area(a).PVmax  = zeros(T,1);      %% theory output of PV
    in.area(a).Tieline=zeros(1,Ntie(a));        %% tie lines
    in.area(a).Ftie0=zeros(T,Ntie(a));          %% fixed power flow
    in.area(a).Etie =zeros(TD,Ntie(a));          %% exchage energy each day
    in.area(a).TDstart=ones(1,TD+1);
    in.area(a).ReserveUp=ones(T,1);      %% up reserve
    in.area(a).ReserveDn=ones(T,1);      %% down reserve
end
%%------------------------------ read data---------------------------------
for a=1:A
    %%------------------------- unit data ---------------------------------
    in.area(a).Pmax        = xlsread(areaFile{a},1,['B2:B' num2str(Nunit(a)+1)])';
    in.area(a).Pmin        = xlsread(areaFile{a},1,['C2:C' num2str(Nunit(a)+1)])';
    in.area(a).Rampup      = xlsread(areaFile{a},1,['D2:D' num2str(Nunit(a)+1)])';
    in.area(a).Rampdown    = xlsread(areaFile{a},1,['E2:E' num2str(Nunit(a)+1)])';
    in.area(a).Minup       = xlsread(areaFile{a},1,['F2:F' num2str(Nunit(a)+1)])';
    in.area(a).Mindown     = xlsread(areaFile{a},1,['G2:G' num2str(Nunit(a)+1)])';
    in.area(a).Onoff_t0    = xlsread(areaFile{a},1,['H2:H' num2str(Nunit(a)+1)])';
    in.area(a).Pthermal_t0 = xlsread(areaFile{a},1,['I2:I' num2str(Nunit(a)+1)])';
    in.area(a).On_t0       = xlsread(areaFile{a},1,['J2:J' num2str(Nunit(a)+1)])';
    in.area(a).Off_t0      = xlsread(areaFile{a},1,['K2:K' num2str(Nunit(a)+1)])';
    %%------------------------- Demand data -------------------------------------
    in.area(a).Demand      = xlsread(areaFile{a},2,['B2:B' num2str(T+1)]);     %% demand of each area
    %%------------------------- Resever data -------------------------------------
    %ReserveUp=ones(T,A);  %% up reserve
    %ReserveDn=ones(T,A);  %% down reserve
    %%------------------------- wind power and PV data ------------------------
    in.area(a).Windmax     = xlsread(areaFile{a},3,['B2:B' num2str(T+1)]);     %% theory output of wind power
    in.area(a).PVmax       = xlsread(areaFile{a},4,['B2:B' num2str(T+1)]);     %% theory output of PV
    %%----------------------------- tie-line data -----------------------------
    in.area(a).Tieline     = xlsread(areaFile{a},5,['B2:D' num2str(Ntie(a)+1)]);
    % for a=1:A
    %     Tieline{a}=ones(Ntie(a),3);    %% [connected_area, type, flow_max]
    %     Ftie0{a}  =ones(T,Ntie(a));    
    %     Etie{a}   =ones(TD,Ntie(a));       
    % end
    in.area(a).ReserveUp   = xlsread(areaFile{a},8,['B2:B' num2str(T+1)]);  %% up reserve
    in.area(a).ReserveDn   = xlsread(areaFile{a},8,['C2:C' num2str(T+1)]);  %% down reserve
end
%% save data
save input_data in;